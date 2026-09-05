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

  // A session used to be limited to one assignedDate column; it can now be
  // scheduled on several dates at once via PlanSessionDates rows.
  group('multi-date scheduling', () {
    test('addSessionDate then getDatesForSession returns it, ascending', () async {
      await db.planDao.createPlan(id: 'plan-1', name: 'Plan A', sessions: [pushDay]);
      final sessionId =
          (await db.planDao.getPlanDetails('plan-1'))!.sessions.single.session.id;

      await db.planDao.addSessionDate(sessionId, DateTime(2026, 9, 8));
      await db.planDao.addSessionDate(sessionId, DateTime(2026, 9, 1));

      expect(await db.planDao.getDatesForSession(sessionId), [
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 8),
      ]);
    });

    test('addSessionDate is a no-op for a date already scheduled', () async {
      await db.planDao.createPlan(id: 'plan-1', name: 'Plan A', sessions: [pushDay]);
      final sessionId =
          (await db.planDao.getPlanDetails('plan-1'))!.sessions.single.session.id;

      await db.planDao.addSessionDate(sessionId, DateTime(2026, 9, 1));
      await db.planDao.addSessionDate(sessionId, DateTime(2026, 9, 1));

      expect(await db.planDao.getDatesForSession(sessionId), [
        DateTime(2026, 9, 1),
      ]);
    });

    test('removeSessionDate removes only that one date', () async {
      await db.planDao.createPlan(id: 'plan-1', name: 'Plan A', sessions: [pushDay]);
      final sessionId =
          (await db.planDao.getPlanDetails('plan-1'))!.sessions.single.session.id;
      await db.planDao.addSessionDate(sessionId, DateTime(2026, 9, 1));
      await db.planDao.addSessionDate(sessionId, DateTime(2026, 9, 8));

      await db.planDao.removeSessionDate(sessionId, DateTime(2026, 9, 1));

      expect(await db.planDao.getDatesForSession(sessionId), [
        DateTime(2026, 9, 8),
      ]);
    });

    test(
      'removeSessionDate never touches an existing SessionLog for that session',
      () async {
        await db.planDao.createPlan(id: 'plan-1', name: 'Plan A', sessions: [pushDay]);
        final sessionId =
            (await db.planDao.getPlanDetails('plan-1'))!.sessions.single.session.id;
        await db.planDao.addSessionDate(sessionId, DateTime(2026, 9, 1));
        await db.sessionLogDao.createSessionLog(
          id: 'log-1',
          planSessionId: sessionId,
          loggedAt: DateTime(2026, 9, 1),
          entries: const [],
        );

        await db.planDao.removeSessionDate(sessionId, DateTime(2026, 9, 1));

        expect(
          await db.sessionLogDao.getLogsForPlanSession(sessionId),
          hasLength(1),
          reason: 'unscheduling a date must not delete what was logged on it',
        );
      },
    );

    test('moveSessionDate updates one occurrence in place', () async {
      await db.planDao.createPlan(id: 'plan-1', name: 'Plan A', sessions: [pushDay]);
      final sessionId =
          (await db.planDao.getPlanDetails('plan-1'))!.sessions.single.session.id;
      await db.planDao.addSessionDate(sessionId, DateTime(2026, 9, 1));
      await db.planDao.addSessionDate(sessionId, DateTime(2026, 9, 8));

      await db.planDao.moveSessionDate(
        sessionId,
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 4),
      );

      expect(await db.planDao.getDatesForSession(sessionId), [
        DateTime(2026, 9, 4),
        DateTime(2026, 9, 8),
      ]);
    });

    test(
      'getAllScheduledSessions returns one row per (session, date) occurrence',
      () async {
        await db.planDao.createPlan(
          id: 'plan-1',
          name: 'Plan A',
          sessions: [
            PlanSessionInput(
              weekNumber: pushDay.weekNumber,
              day: pushDay.day,
              sessionName: pushDay.sessionName,
              exercises: pushDay.exercises,
              assignedDates: [DateTime(2026, 9, 1), DateTime(2026, 9, 8)],
            ),
          ],
        );

        final scheduled = await db.planDao.getAllScheduledSessions();

        expect(scheduled, hasLength(2));
        // No ordering guarantee on this query - compare as a set.
        expect(
          scheduled.map((s) => s.date).toSet(),
          {DateTime(2026, 9, 1), DateTime(2026, 9, 8)},
        );
      },
    );

    test('a session with no dates is excluded from getAllScheduledSessions', () async {
      await db.planDao.createPlan(id: 'plan-1', name: 'Plan A', sessions: [pushDay]);
      expect(await db.planDao.getAllScheduledSessions(), isEmpty);
    });
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

  group('duplicateSessionToWeeks', () {
    test('clones the session\'s exercises into each target week', () async {
      await db.planDao.createPlan(id: 'plan-1', name: 'Plan A', sessions: [pushDay]);
      final sessionId =
          (await db.planDao.getPlanDetails('plan-1'))!.sessions.single.session.id;

      final result = await db.planDao.duplicateSessionToWeeks(
        sessionId: sessionId,
        weekNumbers: [2, 3],
      );
      expect(result, (added: 2, skipped: 0));

      final sessions = (await db.planDao.getPlanDetails('plan-1'))!.sessions;
      expect(sessions, hasLength(3));
      final week2 = sessions.firstWhere((s) => s.session.weekNumber == 2);
      final week3 = sessions.firstWhere((s) => s.session.weekNumber == 3);
      for (final s in [week2, week3]) {
        expect(s.session.day, 'Mon');
        expect(s.session.sessionName, 'Push Day');
        expect(s.exercises.map((e) => e.exerciseName), [
          'Bench Press',
          'Overhead Press',
        ]);
        expect(s.dates, isEmpty, reason: 'duplicated sessions start unscheduled');
      }
    });

    test(
      'skips a week that already has a session with the same day and name',
      () async {
        await db.planDao.createPlan(id: 'plan-1', name: 'Plan A', sessions: [pushDay]);
        final details = (await db.planDao.getPlanDetails('plan-1'))!;
        final sessionId = details.sessions.single.session.id;
        await db.planDao.addSession(
          planId: 'plan-1',
          weekNumber: 2,
          day: 'Mon',
          sessionName: 'Push Day',
        );

        final result = await db.planDao.duplicateSessionToWeeks(
          sessionId: sessionId,
          weekNumbers: [2, 3],
        );
        expect(result, (added: 1, skipped: 1));

        final sessions = (await db.planDao.getPlanDetails('plan-1'))!.sessions;
        // The pre-existing week-2 session, plus the original and the new
        // week-3 one - not a second week-2 duplicate.
        expect(sessions.where((s) => s.session.weekNumber == 2), hasLength(1));
        expect(sessions.where((s) => s.session.weekNumber == 3), hasLength(1));
      },
    );

    test('duplicating to zero weeks is a harmless no-op', () async {
      await db.planDao.createPlan(id: 'plan-1', name: 'Plan A', sessions: [pushDay]);
      final sessionId =
          (await db.planDao.getPlanDetails('plan-1'))!.sessions.single.session.id;

      final result = await db.planDao.duplicateSessionToWeeks(
        sessionId: sessionId,
        weekNumbers: [],
      );
      expect(result, (added: 0, skipped: 0));
      expect((await db.planDao.getPlanDetails('plan-1'))!.sessions, hasLength(1));
    });
  });

  test('addSessionDate bumps the parent plan\'s updated_at', () async {
    await db.planDao.createPlan(id: 'plan-1', name: 'Plan A', sessions: [pushDay]);
    final sessionId =
        (await db.planDao.getPlanDetails('plan-1'))!.sessions.single.session.id;
    final before = (await db.planDao.getPlanDetails('plan-1'))!.plan.updatedAt;
    await Future<void>.delayed(const Duration(seconds: 1, milliseconds: 100));

    await db.planDao.addSessionDate(sessionId, DateTime(2026, 9, 1));

    final after = (await db.planDao.getPlanDetails('plan-1'))!.plan.updatedAt;
    expect(after.isAfter(before), isTrue);
  });

  test('updatePlanNotes saves the text and bumps updated_at', () async {
    await db.planDao.createPlan(id: 'plan-1', name: 'Plan A', sessions: [pushDay]);
    final before = (await db.planDao.getPlanDetails('plan-1'))!.plan;
    expect(before.notes, '');
    await Future<void>.delayed(const Duration(seconds: 1, milliseconds: 100));

    await db.planDao.updatePlanNotes(
      'plan-1',
      'Swap deadlifts for RDLs next block',
    );

    final after = (await db.planDao.getPlanDetails('plan-1'))!.plan;
    expect(after.notes, 'Swap deadlifts for RDLs next block');
    expect(after.updatedAt.isAfter(before.updatedAt), isTrue);
  });
}
