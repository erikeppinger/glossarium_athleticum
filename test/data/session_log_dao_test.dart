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

  test('getLoggedPlanSessionCounts returns only sessions with a logged workout', () async {
    expect(await db.sessionLogDao.getLoggedPlanSessionCounts(), isEmpty);

    await db.sessionLogDao.createSessionLog(
      id: 'log-1',
      planSessionId: sessionId,
      loggedAt: DateTime(2026, 8, 20),
      entries: const [
        LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
      ],
    );

    expect(await db.sessionLogDao.getLoggedPlanSessionCounts(), {
      sessionId: {DateTime(2026, 8, 20): 1},
    });
  });

  // Regression test: the calendar used to collapse "logged" down to a plain
  // Set<int>, so training the same scheduled session twice in a day showed
  // as identically "completed" as training it once - the count itself was
  // silently thrown away even though both workouts were correctly saved and
  // both showed up in Progress. See calendar_screen.dart's
  // `_scheduledSessionTile`, which now reads this count to say "Completed
  // 2x" instead of just "Completed".
  test(
    'getLoggedPlanSessionCounts counts multiple logs against the same session',
    () async {
      await db.sessionLogDao.createSessionLog(
        id: 'log-1',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 8, 20, 9),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
        ],
      );
      await db.sessionLogDao.createSessionLog(
        id: 'log-2',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 8, 20, 18),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 65),
        ],
      );

      expect(await db.sessionLogDao.getLoggedPlanSessionCounts(), {
        sessionId: {DateTime(2026, 8, 20): 2},
      });
    },
  );

  // Regression test: reassigning an already-completed session to a new,
  // untrained date used to still read as "done" on the calendar - and, worse,
  // block starting it from there - because completion was tracked purely by
  // plan_session_id with no correlation to *which* date had actually been
  // trained. `getLoggedPlanSessionCounts` now buckets by day, so the count
  // for the old date is unaffected by the move, and the new date (never
  // logged) legitimately has none - it's `calendar_screen.dart`'s job to look
  // the day up, but the DAO returning day-separated counts at all is what
  // makes that possible.
  test(
    'getLoggedPlanSessionCounts keeps counts separated by the day they were logged on',
    () async {
      await db.sessionLogDao.createSessionLog(
        id: 'log-1',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 8, 20),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
        ],
      );

      final counts = await db.sessionLogDao.getLoggedPlanSessionCounts();
      expect(counts[sessionId], {DateTime(2026, 8, 20): 1});
      // The session is later moved to a fresh date with no log of its own -
      // that date must not inherit the old date's completion.
      expect(counts[sessionId]?[DateTime(2026, 9, 15)], isNull);
    },
  );

  group('getPeriodSummary', () {
    test('counts scheduled/completed sessions, volume, and PRs within range', () async {
      await db.planDao.addSessionDate(sessionId, DateTime(2026, 8, 10));
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

    test('includes ad-hoc activities logged within range', () async {
      await db.sessionLogDao.createAdHocActivity(
        id: 'activity-1',
        loggedAt: DateTime(2026, 8, 10),
        activityName: 'Walk',
        durationSec: 1800,
        distance: 3000,
      );
      await db.sessionLogDao.createAdHocActivity(
        id: 'activity-2',
        loggedAt: DateTime(2026, 8, 15),
        activityName: 'Run',
        durationSec: 1200,
        distance: 5000,
      );
      // Outside the range - shouldn't count.
      await db.sessionLogDao.createAdHocActivity(
        id: 'activity-3',
        loggedAt: DateTime(2026, 9, 5),
        activityName: 'Bike',
        durationSec: 3600,
        distance: 20000,
      );

      final summary = await db.sessionLogDao.getPeriodSummary(
        start: DateTime(2026, 8, 1),
        end: DateTime(2026, 9, 1),
      );

      expect(summary.adHocActivityCount, 2);
      expect(summary.adHocDurationSec, 3000);
      expect(summary.adHocDistanceMeters, 8000);
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

    test(
      'when multiple sets tie for the top weight, uses the fewest reps '
      'among them (the hardest set), not an arbitrary one',
      () async {
        // Reported live: progression suggestions used to key off whichever
        // set happened to tie for the top weight first, which could pick an
        // easy 8-rep set over a grinding 5-rep set done at the exact same
        // weight in the same session - overstating how well the session
        // actually went.
        await db.sessionLogDao.createSessionLog(
          id: 'log-1',
          planSessionId: sessionId,
          loggedAt: DateTime(2026, 8, 13),
          entries: const [
            LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
            LoggedSetInput(exerciseId: 'EX_BP', setNumber: 2, reps: 6, weight: 60),
            LoggedSetInput(exerciseId: 'EX_BP', setNumber: 3, reps: 7, weight: 60),
          ],
        );

        final history = await db.sessionLogDao.getProgressionHistory('EX_BP');
        expect(history, hasLength(1));
        expect(history.single.weight, 60.0);
        expect(history.single.reps, 6);
      },
    );

    test(
      'uses the highest RPE among the sets at the top weight, when recorded',
      () async {
        await db.sessionLogDao.createSessionLog(
          id: 'log-1',
          planSessionId: sessionId,
          loggedAt: DateTime(2026, 8, 13),
          entries: const [
            LoggedSetInput(
              exerciseId: 'EX_BP',
              setNumber: 1,
              reps: 8,
              weight: 60,
              rpe: 7.5,
            ),
            LoggedSetInput(
              exerciseId: 'EX_BP',
              setNumber: 2,
              reps: 8,
              weight: 60,
              rpe: 9.5,
            ),
          ],
        );

        final history = await db.sessionLogDao.getProgressionHistory('EX_BP');
        expect(history.single.rpe, 9.5);
      },
    );

    test('RPE is null when no set at the top weight recorded one', () async {
      await db.sessionLogDao.createSessionLog(
        id: 'log-1',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 8, 13),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
        ],
      );

      final history = await db.sessionLogDao.getProgressionHistory('EX_BP');
      expect(history.single.rpe, isNull);
    });
  });

  group('getAllLoggedDays', () {
    test('returns no days for an empty log', () async {
      expect(await db.sessionLogDao.getAllLoggedDays(), isEmpty);
    });

    test('includes both scheduled-session and ad-hoc-activity days', () async {
      await db.sessionLogDao.createSessionLog(
        id: 'log-1',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 8, 20),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
        ],
      );
      await db.sessionLogDao.createAdHocActivity(
        id: 'activity-1',
        loggedAt: DateTime(2026, 8, 21),
        activityName: 'Walk',
      );

      expect(
        await db.sessionLogDao.getAllLoggedDays(),
        unorderedEquals([DateTime(2026, 8, 20), DateTime(2026, 8, 21)]),
      );
    });

    test('logging twice on the same day only counts as one day', () async {
      await db.sessionLogDao.createSessionLog(
        id: 'log-1',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 8, 20, 9),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
        ],
      );
      await db.sessionLogDao.createAdHocActivity(
        id: 'activity-1',
        loggedAt: DateTime(2026, 8, 20, 18),
        activityName: 'Walk',
      );

      expect(await db.sessionLogDao.getAllLoggedDays(), [DateTime(2026, 8, 20)]);
    });
  });

  group('ad-hoc activities', () {
    test('createAdHocActivity round-trips through getAdHocActivities', () async {
      await db.sessionLogDao.createAdHocActivity(
        id: 'activity-1',
        loggedAt: DateTime(2026, 8, 20),
        activityName: 'Walk',
        durationSec: 1800,
        distance: 3.2,
        notes: 'Around the block',
      );

      final activities = await db.sessionLogDao.getAdHocActivities();
      expect(activities, hasLength(1));
      expect(activities.single.planSessionId, isNull);
      expect(activities.single.activityName, 'Walk');
      expect(activities.single.durationSec, 1800);
      expect(activities.single.distance, 3.2);
      expect(activities.single.notes, 'Around the block');
    });

    test('does not show up in getLoggedPlanSessionIds', () async {
      await db.sessionLogDao.createAdHocActivity(
        id: 'activity-1',
        loggedAt: DateTime(2026, 8, 20),
        activityName: 'Run',
      );
      expect(await db.sessionLogDao.getLoggedPlanSessionCounts(), isEmpty);
    });

    test('appears in getWorkoutHistory using its activity name', () async {
      await db.sessionLogDao.createAdHocActivity(
        id: 'activity-1',
        loggedAt: DateTime(2026, 8, 20),
        activityName: 'Yoga',
      );

      final history = await db.sessionLogDao.getWorkoutHistory();
      expect(history, hasLength(1));
      expect(history.single.sessionName, 'Yoga');
      expect(history.single.setCount, 0);
    });

    test('getCompletedWorkout returns it with no plan session and no sets', () async {
      await db.sessionLogDao.createAdHocActivity(
        id: 'activity-1',
        loggedAt: DateTime(2026, 8, 20),
        activityName: 'Cycling',
        durationSec: 2400,
      );

      final workout = await db.sessionLogDao.getCompletedWorkout('activity-1');
      expect(workout, isNotNull);
      expect(workout!.sessionName, 'Cycling');
      expect(workout.exercises, isEmpty);
      expect(workout.log.durationSec, 2400);
    });

    test('a normal plan-session workout is unaffected by ad-hoc activities existing', () async {
      await db.sessionLogDao.createAdHocActivity(
        id: 'activity-1',
        loggedAt: DateTime(2026, 8, 20),
        activityName: 'Walk',
      );
      await db.sessionLogDao.createSessionLog(
        id: 'log-1',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 8, 21),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
        ],
      );

      expect(await db.sessionLogDao.getLoggedPlanSessionCounts(), {
        sessionId: {DateTime(2026, 8, 21): 1},
      });
      final history = await db.sessionLogDao.getWorkoutHistory();
      expect(history, hasLength(2));
    });

    test('deleteSessionLog removes an ad-hoc activity like any other log', () async {
      await db.sessionLogDao.createAdHocActivity(
        id: 'activity-1',
        loggedAt: DateTime(2026, 8, 20),
        activityName: 'Walk',
      );
      await db.sessionLogDao.deleteSessionLog('activity-1');
      expect(await db.sessionLogDao.getAdHocActivities(), isEmpty);
    });
  });

  group('getLastLoggedSets', () {
    test('returns every set from only the most recent session, in order', () async {
      await db.sessionLogDao.createSessionLog(
        id: 'log-older',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 8, 13),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 5, weight: 50),
        ],
      );
      await db.sessionLogDao.createSessionLog(
        id: 'log-newer',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 8, 20),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 2, reps: 7, weight: 60),
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 3, reps: 6, weight: 55),
        ],
      );

      final sets = await db.sessionLogDao.getLastLoggedSets('EX_BP');
      expect(sets, hasLength(3));
      expect(sets.map((s) => s.setNumber), [1, 2, 3]);
      expect(sets.map((s) => s.weight), [60.0, 60.0, 55.0]);
      expect(sets.map((s) => s.reps), [8, 7, 6]);
    });

    test('is empty when the exercise has never been logged', () async {
      expect(await db.sessionLogDao.getLastLoggedSets('EX_BP'), isEmpty);
    });
  });

  group('getActiveDraftPlanSessionId', () {
    test('is null when there is no draft at all', () async {
      expect(await db.sessionLogDao.getActiveDraftPlanSessionId(), isNull);
    });

    test('returns the draft\'s plan session id', () async {
      await db.sessionLogDao.saveDraft(
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 8, 20),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
        ],
      );
      expect(
        await db.sessionLogDao.getActiveDraftPlanSessionId(),
        sessionId,
      );
    });

    test('is null once the draft is cleared', () async {
      await db.sessionLogDao.saveDraft(
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 8, 20),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
        ],
      );
      await db.sessionLogDao.deleteDraft(sessionId);
      expect(await db.sessionLogDao.getActiveDraftPlanSessionId(), isNull);
    });

    test('a real finished log is not mistaken for a draft', () async {
      await db.sessionLogDao.createSessionLog(
        id: 'log-1',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 8, 20),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
        ],
      );
      expect(await db.sessionLogDao.getActiveDraftPlanSessionId(), isNull);
    });

    test('picks the most recently autosaved draft when more than one lingers', () async {
      await db.planDao.createPlan(
        id: 'plan-2',
        name: 'Plan B',
        sessions: [
          const PlanSessionInput(
            weekNumber: 1,
            day: 'Wed',
            sessionName: 'Pull Day',
            exercises: [
              PlanExerciseInput(
                order: 1,
                exerciseId: 'EX_BP',
                exerciseName: 'Bench Press',
                sets: 1,
                reps: '8',
              ),
            ],
          ),
        ],
      );
      final otherSessionId = (await db.planDao.getPlanDetails(
        'plan-2',
      ))!.sessions.single.session.id;

      await db.sessionLogDao.saveDraft(
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 8, 13),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
        ],
      );
      await db.sessionLogDao.saveDraft(
        planSessionId: otherSessionId,
        loggedAt: DateTime(2026, 8, 20),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 5, weight: 40),
        ],
      );

      expect(
        await db.sessionLogDao.getActiveDraftPlanSessionId(),
        otherSessionId,
      );
    });
  });
}
