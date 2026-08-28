import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/data/daos/session_log_dao.dart';

void main() {
  late AppDatabase db;
  late int sessionId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: 'EX_BP',
        name: 'Bench Press',
        category: 'Main Lift',
        movementPattern: 'Push',
        muscleGroups: 'Chest',
        equipment: 'Barbell',
        difficulty: 'Intermediate',
        measurementType: 'Weight x Reps',
      ),
    );
    await db.planDao.createPlan(
      id: 'plan-1',
      name: 'Plan A',
      sessions: [
        const PlanSessionInput(
          weekNumber: 1,
          day: 'Mon',
          sessionName: 'Push Day',
          exercises: [
            PlanExerciseInput(
              order: 1,
              exerciseId: 'EX_BP',
              exerciseName: 'Bench Press',
              sets: 3,
              reps: '8',
            ),
          ],
        ),
      ],
    );
    final details = await db.planDao.getPlanDetails('plan-1');
    sessionId = details!.sessions.single.session.id;
  });

  tearDown(() => db.close());

  test('createSessionLog then getLoggedSetsForSessionLog round-trips', () async {
    await db.sessionLogDao.createSessionLog(
      id: 'log-1',
      planSessionId: sessionId,
      loggedAt: DateTime(2026, 8, 20),
      entries: const [
        LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
        LoggedSetInput(exerciseId: 'EX_BP', setNumber: 2, reps: 7, weight: 60),
      ],
    );

    final sets = await db.sessionLogDao.getLoggedSetsForSessionLog('log-1');
    expect(sets, hasLength(2));
    expect(sets[0].weight, 60.0);
    expect(sets[1].reps, 7);
  });

  test('getLogsForPlanSession returns logs newest first', () async {
    await db.sessionLogDao.createSessionLog(
      id: 'log-1',
      planSessionId: sessionId,
      loggedAt: DateTime(2026, 8, 13),
      entries: const [
        LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 55),
      ],
    );
    await db.sessionLogDao.createSessionLog(
      id: 'log-2',
      planSessionId: sessionId,
      loggedAt: DateTime(2026, 8, 20),
      entries: const [
        LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
      ],
    );

    final logs = await db.sessionLogDao.getLogsForPlanSession(sessionId);
    expect(logs.map((l) => l.id), ['log-2', 'log-1']);
  });

  test('getPriorWeights returns every logged weight for the exercise', () async {
    await db.sessionLogDao.createSessionLog(
      id: 'log-1',
      planSessionId: sessionId,
      loggedAt: DateTime(2026, 8, 13),
      entries: const [
        LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 55),
        LoggedSetInput(exerciseId: 'EX_BP', setNumber: 2, reps: 6, weight: 57.5),
      ],
    );

    final weights = await db.sessionLogDao.getPriorWeights('EX_BP');
    expect(weights, containsAll([55.0, 57.5]));
  });

  test('getPriorWeights ignores sets with a null weight (time/distance exercises)', () async {
    await db.sessionLogDao.createSessionLog(
      id: 'log-1',
      planSessionId: sessionId,
      loggedAt: DateTime(2026, 8, 13),
      entries: const [
        LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, durationSec: 30),
      ],
    );
    expect(await db.sessionLogDao.getPriorWeights('EX_BP'), isEmpty);
  });

  test('getLoggedPlanSessionIds returns only sessions with a logged workout', () async {
    expect(await db.sessionLogDao.getLoggedPlanSessionIds(), isEmpty);

    await db.sessionLogDao.createSessionLog(
      id: 'log-1',
      planSessionId: sessionId,
      loggedAt: DateTime(2026, 8, 20),
      entries: const [
        LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
      ],
    );

    expect(await db.sessionLogDao.getLoggedPlanSessionIds(), {sessionId});
  });

  group('getPeriodSummary', () {
    test('counts scheduled/completed sessions, volume, and PRs within range', () async {
      await db.planDao.assignSessionDate(sessionId, DateTime(2026, 8, 10));
      await db.sessionLogDao.createSessionLog(
        id: 'log-1',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 8, 10),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60, isPr: true),
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 2, reps: 8, weight: 60),
        ],
      );
      // Outside the range below - shouldn't be counted.
      await db.sessionLogDao.createSessionLog(
        id: 'log-2',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 9, 1),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 100),
        ],
      );

      final summary = await db.sessionLogDao.getPeriodSummary(
        start: DateTime(2026, 8, 1),
        end: DateTime(2026, 9, 1),
      );

      expect(summary.sessionsScheduled, 1);
      expect(summary.sessionsCompleted, 1);
      expect(summary.totalVolume, 8 * 60.0 * 2);
      expect(summary.prCount, 1);
    });

    test('an unscheduled but logged session counts as volume/PRs but not completed', () async {
      await db.sessionLogDao.createSessionLog(
        id: 'log-1',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 8, 10),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
        ],
      );

      final summary = await db.sessionLogDao.getPeriodSummary(
        start: DateTime(2026, 8, 1),
        end: DateTime(2026, 9, 1),
      );

      expect(summary.sessionsScheduled, 0);
      expect(summary.sessionsCompleted, 0);
      expect(summary.totalVolume, 8 * 60.0);
    });
  });

  group('getDailyTotals', () {
    test('aggregates volume/sets/reps/PRs per day within the range', () async {
      await db.sessionLogDao.createSessionLog(
        id: 'log-1',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 8, 10),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60, isPr: true),
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 2, reps: 6, weight: 60),
        ],
      );
      await db.sessionLogDao.createSessionLog(
        id: 'log-2',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 8, 12),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 5, weight: 70),
        ],
      );

      final totals = await db.sessionLogDao.getDailyTotals(
        start: DateTime(2026, 8, 1),
        end: DateTime(2026, 9, 1),
      );

      expect(totals, hasLength(2));
      expect(totals[0].day, DateTime(2026, 8, 10));
      expect(totals[0].volume, 8 * 60.0 + 6 * 60.0);
      expect(totals[0].sets, 2);
      expect(totals[0].reps, 14);
      expect(totals[0].prs, 1);
      expect(totals[0].sessions, 1);
      expect(totals[1].day, DateTime(2026, 8, 12));
      expect(totals[1].volume, 5 * 70.0);
    });

    test('is ordered oldest-first, so a chart reads left to right', () async {
      await db.sessionLogDao.createSessionLog(
        id: 'log-late',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 8, 20),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 5, weight: 70),
        ],
      );
      await db.sessionLogDao.createSessionLog(
        id: 'log-early',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 8, 5),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 5, weight: 60),
        ],
      );

      final totals = await db.sessionLogDao.getDailyTotals(
        start: DateTime(2026, 8, 1),
        end: DateTime(2026, 9, 1),
      );
      expect(totals.map((t) => t.day), [
        DateTime(2026, 8, 5),
        DateTime(2026, 8, 20),
      ]);
    });

    test('excludes days outside the range', () async {
      await db.sessionLogDao.createSessionLog(
        id: 'log-1',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 7, 31),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 5, weight: 60),
        ],
      );
      final totals = await db.sessionLogDao.getDailyTotals(
        start: DateTime(2026, 8, 1),
        end: DateTime(2026, 9, 1),
      );
      expect(totals, isEmpty);
    });
  });

  group('getLatestTopSetPerExercise', () {
    test('picks the heaviest set from the most recent session', () async {
      await db.sessionLogDao.createSessionLog(
        id: 'log-1',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 8, 6),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 55),
        ],
      );
      await db.sessionLogDao.createSessionLog(
        id: 'log-2',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 8, 13),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 2, reps: 6, weight: 65, isPr: true),
        ],
      );

      final summaries = await db.sessionLogDao.getLatestTopSetPerExercise();
      expect(summaries, hasLength(1));
      expect(summaries.single.exerciseId, 'EX_BP');
      expect(summaries.single.topWeight, 65.0);
      expect(summaries.single.topReps, 6);
      expect(summaries.single.isPr, isTrue);
      expect(summaries.single.lastLoggedAt, DateTime(2026, 8, 13));
    });

    test('excludes sets with no weight/reps (time/distance exercises)', () async {
      await db.sessionLogDao.createSessionLog(
        id: 'log-1',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 8, 13),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, durationSec: 30),
        ],
      );
      expect(await db.sessionLogDao.getLatestTopSetPerExercise(), isEmpty);
    });
  });

  group('getProgressionHistory', () {
    test('reduces each session to its top (heaviest) set', () async {
      await db.sessionLogDao.createSessionLog(
        id: 'log-1',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 8, 13),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 50),
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 2, reps: 6, weight: 60),
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 3, reps: 4, weight: 65),
        ],
      );

      final history = await db.sessionLogDao.getProgressionHistory('EX_BP');
      expect(history, hasLength(1));
      expect(history.single.weight, 65.0);
      expect(history.single.reps, 4);
    });

    test('one entry per session, ordered sessions distinguishable by date', () async {
      await db.sessionLogDao.createSessionLog(
        id: 'log-1',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 8, 6),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 55),
        ],
      );
      await db.sessionLogDao.createSessionLog(
        id: 'log-2',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 8, 13),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
        ],
      );

      final history = await db.sessionLogDao.getProgressionHistory('EX_BP');
      expect(history, hasLength(2));
      final sorted = [...history]..sort((a, b) => a.date.compareTo(b.date));
      expect(sorted.map((e) => e.weight), [55.0, 60.0]);
    });

    test('excludes sets with null weight or reps', () async {
      await db.sessionLogDao.createSessionLog(
        id: 'log-1',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 8, 13),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, durationSec: 45),
        ],
      );
      expect(await db.sessionLogDao.getProgressionHistory('EX_BP'), isEmpty);
    });
  });
}
