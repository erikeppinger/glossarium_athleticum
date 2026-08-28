import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/daos/plan_dao.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  const pushDay = PlanSessionInput(
    weekNumber: 1,
    day: 'Mon',
    sessionName: 'Push Day',
    exercises: [
      PlanExerciseInput(
        order: 1,
        exerciseName: 'Bench Press',
        sets: 4,
        reps: '8-10',
        weightIntensity: '60kg',
        restSec: 90,
      ),
      PlanExerciseInput(
        order: 2,
        exerciseName: 'Overhead Press',
        sets: 3,
        reps: '8-10',
      ),
    ],
  );

  test('createPlan then getPlanDetails round-trips nested structure', () async {
    await db.planDao.createPlan(id: 'plan-1', name: 'My Plan', sessions: [pushDay]);

    final details = await db.planDao.getPlanDetails('plan-1');
    expect(details, isNotNull);
    expect(details!.plan.name, 'My Plan');
    expect(details.sessions, hasLength(1));
    expect(details.sessions.single.session.sessionName, 'Push Day');
    expect(details.sessions.single.exercises, hasLength(2));
    expect(details.sessions.single.exercises[0].exerciseName, 'Bench Press');
    expect(details.sessions.single.exercises[1].order, 2);
  });

  test('getPlanDetails returns null for unknown plan', () async {
    expect(await db.planDao.getPlanDetails('nope'), isNull);
  });

  test('getAllPlans lists created plans', () async {
    await db.planDao.createPlan(id: 'plan-1', name: 'Plan A', sessions: [pushDay]);
    await db.planDao.createPlan(id: 'plan-2', name: 'Plan B', sessions: [pushDay]);
    final all = await db.planDao.getAllPlans();
    expect(all.map((p) => p.name), containsAll(['Plan A', 'Plan B']));
  });

  test('deletePlan cascades to sessions and exercises', () async {
    await db.planDao.createPlan(id: 'plan-1', name: 'Plan A', sessions: [pushDay]);
    final sessionId = (await db.planDao.getPlanDetails('plan-1'))!.sessions.single.session.id;

    await db.planDao.deletePlan('plan-1');

    expect(await db.planDao.getPlanDetails('plan-1'), isNull);
    // getPlanDetails alone would pass even if child rows were orphaned,
    // since it short-circuits on the parent's absence - check the
    // children directly (this caught a real bug during Phase 5: deletePlan
    // used to only delete the Plans row, relying on FK cascade that isn't
    // actually enabled for this connection).
    expect(
      await db.planDao.getSessionDetails(sessionId),
      isNull,
      reason: 'the session row should have been deleted along with the plan',
    );
  });

  test('assignSessionDate then getSessionsInRange finds it', () async {
    await db.planDao.createPlan(id: 'plan-1', name: 'Plan A', sessions: [pushDay]);
    final details = await db.planDao.getPlanDetails('plan-1');
    final sessionId = details!.sessions.single.session.id;

    final date = DateTime(2026, 9, 1);
    await db.planDao.assignSessionDate(sessionId, date);

    final inRange = await db.planDao.getSessionsInRange(
      DateTime(2026, 8, 25),
      DateTime(2026, 9, 7),
    );
    expect(inRange.map((s) => s.id), [sessionId]);

    final outOfRange = await db.planDao.getSessionsInRange(
      DateTime(2026, 9, 2),
      DateTime(2026, 9, 7),
    );
    expect(outOfRange, isEmpty);
  });

  test('sessions with no assignedDate are excluded from range queries', () async {
    await db.planDao.createPlan(id: 'plan-1', name: 'Plan A', sessions: [pushDay]);
    final inRange = await db.planDao.getSessionsInRange(
      DateTime(2020, 1, 1),
      DateTime(2030, 1, 1),
    );
    expect(inRange, isEmpty);
  });

  test('createEmptyPlan creates a plan with zero sessions', () async {
    final id = await db.planDao.createEmptyPlan(name: 'Blank Plan');
    final details = await db.planDao.getPlanDetails(id);
    expect(details!.plan.name, 'Blank Plan');
    expect(details.sessions, isEmpty);
  });

  test('addSession appends a session to an existing plan and bumps updated_at', () async {
    final planId = await db.planDao.createEmptyPlan(name: 'Blank Plan');
    final before = (await db.planDao.getPlanDetails(planId))!.plan.updatedAt;
    await Future<void>.delayed(const Duration(seconds: 1, milliseconds: 100));

    final sessionId = await db.planDao.addSession(
      planId: planId,
      weekNumber: 1,
      day: 'Mon',
      sessionName: 'Leg Day',
    );

    final details = await db.planDao.getPlanDetails(planId);
    expect(details!.sessions, hasLength(1));
    expect(details.sessions.single.session.id, sessionId);
    expect(details.sessions.single.session.sessionName, 'Leg Day');
    expect(details.plan.updatedAt.isAfter(before), isTrue);
  });

  test(
    'addExerciseToSession appends after existing exercises and assigns the next order',
    () async {
      await db.planDao.createPlan(id: 'plan-1', name: 'Plan A', sessions: [pushDay]);
      final sessionId =
          (await db.planDao.getPlanDetails('plan-1'))!.sessions.single.session.id;
      final before = (await db.planDao.getPlanDetails('plan-1'))!.plan.updatedAt;
      await Future<void>.delayed(const Duration(seconds: 1, milliseconds: 100));

      await db.planDao.addExerciseToSession(
        sessionId: sessionId,
        input: const PlanExerciseInput(
          order: 999, // ignored - the DAO assigns the real next order
          exerciseName: 'Lateral Raise',
          sets: 3,
          reps: '12-15',
        ),
      );

      final details = await db.planDao.getPlanDetails('plan-1');
      final exercises = details!.sessions.single.exercises;
      expect(exercises, hasLength(3));
      expect(exercises.last.exerciseName, 'Lateral Raise');
      expect(exercises.last.order, 3);
      expect(details.plan.updatedAt.isAfter(before), isTrue);
    },
  );

  group('editing an existing session\'s exercises', () {
    late int firstExerciseId;
    late int secondExerciseId;

    setUp(() async {
      await db.planDao.createPlan(
        id: 'plan-1',
        name: 'Plan A',
        sessions: [pushDay],
      );
      final exercises =
          (await db.planDao.getPlanDetails('plan-1'))!.sessions.single.exercises;
      firstExerciseId = exercises[0].id;
      secondExerciseId = exercises[1].id;
    });

    Future<List<PlanExercise>> currentExercises() async =>
        (await db.planDao.getPlanDetails('plan-1'))!.sessions.single.exercises;

    test('updatePlanExercise edits prescription fields and bumps updated_at', () async {
      final before = (await db.planDao.getPlanDetails('plan-1'))!.plan.updatedAt;
      await Future<void>.delayed(const Duration(seconds: 1, milliseconds: 100));

      await db.planDao.updatePlanExercise(
        planExerciseId: firstExerciseId,
        sets: 5,
        reps: '5',
        weightIntensity: '80kg',
        restSec: 180,
        notes: 'Heavier top set',
      );

      final exercises = await currentExercises();
      expect(exercises[0].sets, 5);
      expect(exercises[0].reps, '5');
      expect(exercises[0].weightIntensity, '80kg');
      expect(exercises[0].restSec, 180);
      expect(exercises[0].notes, 'Heavier top set');
      expect(
        exercises[0].exerciseName,
        'Bench Press',
        reason: 'which exercise the row points at is not editable here',
      );

      final after = (await db.planDao.getPlanDetails('plan-1'))!.plan.updatedAt;
      expect(after.isAfter(before), isTrue);
    });

    test('deletePlanExercise removes the row and closes the order gap', () async {
      await db.planDao.deletePlanExercise(firstExerciseId);

      final exercises = await currentExercises();
      expect(exercises, hasLength(1));
      expect(exercises.single.exerciseName, 'Overhead Press');
      expect(
        exercises.single.order,
        1,
        reason: 'the survivor should be renumbered so orders stay contiguous',
      );
    });

    test('a new exercise added after a delete does not collide on order', () async {
      await db.planDao.deletePlanExercise(firstExerciseId);
      await db.planDao.addExerciseToSession(
        sessionId: (await db.planDao.getPlanDetails(
          'plan-1',
        ))!.sessions.single.session.id,
        input: const PlanExerciseInput(
          order: 0,
          exerciseName: 'Lateral Raise',
          sets: 3,
          reps: '12',
        ),
      );

      final exercises = await currentExercises();
      expect(exercises.map((e) => e.order), [1, 2]);
    });

    test('movePlanExercise swaps order with its neighbour', () async {
      await db.planDao.movePlanExercise(
        planExerciseId: secondExerciseId,
        up: true,
      );

      final exercises = await currentExercises();
      expect(exercises.map((e) => e.exerciseName), [
        'Overhead Press',
        'Bench Press',
      ]);
      expect(exercises.map((e) => e.order), [1, 2]);
    });

    test('movePlanExercise is a no-op at the ends of the list', () async {
      await db.planDao.movePlanExercise(
        planExerciseId: firstExerciseId,
        up: true,
      );
      expect((await currentExercises()).map((e) => e.exerciseName), [
        'Bench Press',
        'Overhead Press',
      ]);

      await db.planDao.movePlanExercise(
        planExerciseId: secondExerciseId,
        up: false,
      );
      expect((await currentExercises()).map((e) => e.exerciseName), [
        'Bench Press',
        'Overhead Press',
      ]);
    });
  });

  test('assignSessionDate bumps the parent plan\'s updated_at', () async {
    await db.planDao.createPlan(id: 'plan-1', name: 'Plan A', sessions: [pushDay]);
    final sessionId =
        (await db.planDao.getPlanDetails('plan-1'))!.sessions.single.session.id;
    final before = (await db.planDao.getPlanDetails('plan-1'))!.plan.updatedAt;
    await Future<void>.delayed(const Duration(seconds: 1, milliseconds: 100));

    await db.planDao.assignSessionDate(sessionId, DateTime(2026, 9, 1));

    final after = (await db.planDao.getPlanDetails('plan-1'))!.plan.updatedAt;
    expect(after.isAfter(before), isTrue);
  });
}
