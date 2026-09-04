import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/data/daos/session_log_dao.dart';

/// Covers the plan deletion model: archive is reversible and lossless,
/// deletion states its blast radius up front, and losing a plan never
/// silently takes logged training history with it.
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
    sessionId =
        (await db.planDao.getPlanDetails('plan-1'))!.sessions.single.session.id;
  });

  tearDown(() => db.close());

  Future<void> logAWorkout({
    String id = 'log-1',
    DateTime? at,
    int sets = 2,
  }) async {
    await db.sessionLogDao.createSessionLog(
      id: id,
      planSessionId: sessionId,
      loggedAt: at ?? DateTime(2026, 8, 20),
      entries: [
        for (var i = 1; i <= sets; i++)
          LoggedSetInput(
            exerciseId: 'EX_BP',
            setNumber: i,
            reps: 8,
            weight: 60,
          ),
      ],
    );
  }

  group('rename', () {
    test('renames and bumps updated_at', () async {
      final before = (await db.planDao.getPlanDetails('plan-1'))!.plan.updatedAt;
      await Future<void>.delayed(const Duration(seconds: 1, milliseconds: 100));

      await db.planDao.renamePlan('plan-1', 'Renamed Plan');

      final after = await db.planDao.getPlanDetails('plan-1');
      expect(after!.plan.name, 'Renamed Plan');
      expect(after.plan.updatedAt.isAfter(before), isTrue);
    });
  });

  group('archive', () {
    test('hides from the active list without touching any data', () async {
      await logAWorkout();
      await db.planDao.archivePlan('plan-1');

      expect(await db.planDao.watchActivePlans().first, isEmpty);
      expect(
        (await db.planDao.watchArchivedPlans().first).map((p) => p.name),
        ['Plan A'],
      );
      // Everything survives.
      final details = await db.planDao.getPlanDetails('plan-1');
      expect(details!.sessions.single.exercises, hasLength(1));
      expect(
        await db.sessionLogDao.getLogsForPlanSession(sessionId),
        hasLength(1),
      );
    });

    test('unarchive puts it back', () async {
      await db.planDao.archivePlan('plan-1');
      await db.planDao.unarchivePlan('plan-1');

      expect(
        (await db.planDao.watchActivePlans().first).map((p) => p.name),
        ['Plan A'],
      );
      expect(await db.planDao.watchArchivedPlans().first, isEmpty);
    });
  });

  group('getPlanDeletionImpact', () {
    test('reports structure only when nothing has been logged', () async {
      final impact = await db.planDao.getPlanDeletionImpact('plan-1');
      expect(impact.sessions, 1);
      expect(impact.exercises, 1);
      expect(impact.loggedWorkouts, 0);
      expect(impact.loggedSets, 0);
      expect(
        impact.losesHistory,
        isFalse,
        reason: 'deleting an untrained plan destroys nothing irreplaceable',
      );
    });

    test('reports logged workouts, sets, and the date range at stake', () async {
      await logAWorkout(id: 'log-1', at: DateTime(2026, 3, 2), sets: 2);
      await logAWorkout(id: 'log-2', at: DateTime(2026, 8, 20), sets: 3);

      final impact = await db.planDao.getPlanDeletionImpact('plan-1');
      expect(impact.loggedWorkouts, 2);
      expect(impact.loggedSets, 5);
      expect(impact.firstLoggedAt, DateTime(2026, 3, 2));
      expect(impact.lastLoggedAt, DateTime(2026, 8, 20));
      expect(impact.losesHistory, isTrue);
    });
  });

  group('deletePlanKeepingHistory', () {
    test('removes the plan but leaves logged workouts readable', () async {
      await logAWorkout(sets: 2);

      await db.planDao.deletePlanKeepingHistory('plan-1');

      expect(await db.planDao.getPlanDetails('plan-1'), isNull);
      expect(await db.planDao.getAllPlans(), isEmpty);

      final logs = await db.sessionLogDao.getLogsForPlanSession(sessionId);
      expect(logs, hasLength(1), reason: 'history must survive');
      final sets = await db.sessionLogDao.getLoggedSetsForSessionLog(
        logs.single.id,
      );
      expect(sets, hasLength(2));
      expect(sets.first.weight, 60.0);
    });

    test('drops sessions that were never trained, keeps ones that were', () async {
      await db.planDao.addSession(
        planId: 'plan-1',
        weekNumber: 1,
        day: 'Wed',
        sessionName: 'Never Trained',
      );
      await logAWorkout();

      await db.planDao.deletePlanKeepingHistory('plan-1');

      final remaining = await db.select(db.planSessions).get();
      expect(
        remaining.map((s) => s.sessionName),
        ['Push Day'],
        reason: 'only the session with history is kept as a tombstone',
      );
    });

    test('clears the calendar date so a deleted plan stops showing up', () async {
      await db.planDao.addSessionDate(sessionId, DateTime(2026, 9, 1));
      await logAWorkout();

      await db.planDao.deletePlanKeepingHistory('plan-1');

      expect(
        await db.planDao.getDatesForSession(sessionId),
        isEmpty,
        reason: 'a kept, tombstoned session should not still show as scheduled',
      );
    });

    test('an untrained plan leaves nothing behind at all', () async {
      await db.planDao.deletePlanKeepingHistory('plan-1');
      expect(await db.select(db.planSessions).get(), isEmpty);
      expect(await db.select(db.planExercises).get(), isEmpty);
    });
  });

  group('deletePlanAndHistory', () {
    test('removes the plan and every logged workout under it', () async {
      await logAWorkout(sets: 3);

      await db.planDao.deletePlanAndHistory('plan-1');

      expect(await db.planDao.getAllPlans(), isEmpty);
      expect(await db.select(db.planSessions).get(), isEmpty);
      expect(await db.select(db.planExercises).get(), isEmpty);
      expect(await db.select(db.sessionLogs).get(), isEmpty);
      expect(
        await db.select(db.loggedSets).get(),
        isEmpty,
        reason: 'logged sets must not be orphaned behind their parent log',
      );
    });

    test('leaves other plans and their history untouched', () async {
      await logAWorkout();
      await db.planDao.createPlan(
        id: 'plan-2',
        name: 'Plan B',
        sessions: [
          const PlanSessionInput(
            weekNumber: 1,
            day: 'Tue',
            sessionName: 'Pull Day',
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
      final otherSessionId =
          (await db.planDao.getPlanDetails('plan-2'))!.sessions.single.session.id;
      await db.sessionLogDao.createSessionLog(
        id: 'other-log',
        planSessionId: otherSessionId,
        loggedAt: DateTime(2026, 8, 21),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 5, weight: 70),
        ],
      );

      await db.planDao.deletePlanAndHistory('plan-1');

      expect((await db.planDao.getAllPlans()).map((p) => p.name), ['Plan B']);
      expect(
        await db.sessionLogDao.getLogsForPlanSession(otherSessionId),
        hasLength(1),
      );
    });
  });
}
