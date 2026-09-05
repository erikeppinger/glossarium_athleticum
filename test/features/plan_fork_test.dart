import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/data/daos/session_log_dao.dart';
import 'package:training_app/features/plans/plan_fork.dart';

// Adding or removing an exercise on an already-existing plan's session was
// reported live as needing to save under a new plan name rather than
// silently rewriting the one the user opened - "flag that the original
// plan was user modified". These tests exercise the actual data-safety
// guarantees that decision depends on: the original plan's rows must come
// out byte-for-byte unchanged, and any logged history must stay pointed at
// the original's session ids, not the fork's new ones.
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

  const pullDay = PlanSessionInput(
    weekNumber: 1,
    day: 'Wed',
    sessionName: 'Pull Day',
    exercises: [
      PlanExerciseInput(order: 1, exerciseName: 'Deadlift', sets: 3, reps: '5'),
    ],
  );

  test('the fork has the added exercise; every other session is copied verbatim', () async {
    await db.planDao.createPlan(
      id: 'plan-1',
      name: 'Plan A',
      sessions: [pushDay, pullDay],
    );
    final source = (await db.planDao.getPlanDetails('plan-1'))!;
    final pushSessionId = source.sessions
        .firstWhere((s) => s.session.sessionName == 'Push Day')
        .session
        .id;
    final existing = source.sessions
        .firstWhere((s) => s.session.sessionName == 'Push Day')
        .exercises
        .map((e) => e.toInput())
        .toList();

    final newPlanId = await forkPlanWithModifiedSession(
      db,
      sourcePlanId: 'plan-1',
      newPlanName: 'Plan A (edited)',
      editedSessionId: pushSessionId,
      newExercisesForEditedSession: [
        ...existing,
        const PlanExerciseInput(order: 3, exerciseName: 'Lateral Raise', sets: 3, reps: '12-15'),
      ],
    );

    final forked = (await db.planDao.getPlanDetails(newPlanId))!;
    expect(forked.plan.name, 'Plan A (edited)');
    expect(forked.sessions, hasLength(2));

    final forkedPush = forked.sessions.firstWhere((s) => s.session.sessionName == 'Push Day');
    expect(forkedPush.exercises.map((e) => e.exerciseName), [
      'Bench Press',
      'Overhead Press',
      'Lateral Raise',
    ]);

    final forkedPull = forked.sessions.firstWhere((s) => s.session.sessionName == 'Pull Day');
    expect(forkedPull.exercises.map((e) => e.exerciseName), ['Deadlift']);
  });

  test('the original plan is completely untouched by the fork', () async {
    await db.planDao.createPlan(id: 'plan-1', name: 'Plan A', sessions: [pushDay]);
    final before = (await db.planDao.getPlanDetails('plan-1'))!;
    final sessionId = before.sessions.single.session.id;

    await forkPlanWithModifiedSession(
      db,
      sourcePlanId: 'plan-1',
      newPlanName: 'Plan A (edited)',
      editedSessionId: sessionId,
      newExercisesForEditedSession: const [],
    );

    final after = (await db.planDao.getPlanDetails('plan-1'))!;
    expect(after.plan.name, before.plan.name);
    expect(after.plan.updatedAt, before.plan.updatedAt);
    expect(after.sessions.single.exercises.map((e) => e.exerciseName), [
      'Bench Press',
      'Overhead Press',
    ]);
  });

  test('a scheduled session\'s dates are preserved on the fork', () async {
    await db.planDao.createPlan(id: 'plan-1', name: 'Plan A', sessions: [pushDay]);
    final sessionId =
        (await db.planDao.getPlanDetails('plan-1'))!.sessions.single.session.id;
    final date = DateTime(2026, 9, 10);
    await db.planDao.addSessionDate(sessionId, date);

    final newPlanId = await forkPlanWithModifiedSession(
      db,
      sourcePlanId: 'plan-1',
      newPlanName: 'Plan A (edited)',
      editedSessionId: sessionId,
      newExercisesForEditedSession: const [
        PlanExerciseInput(order: 1, exerciseName: 'Bench Press', sets: 4, reps: '8-10'),
      ],
    );

    final forked = (await db.planDao.getPlanDetails(newPlanId))!;
    expect(forked.sessions.single.dates, [date]);
  });

  test('logged history stays attached to the original session, not the fork', () async {
    await db.planDao.createPlan(id: 'plan-1', name: 'Plan A', sessions: [pushDay]);
    final sessionId =
        (await db.planDao.getPlanDetails('plan-1'))!.sessions.single.session.id;
    await db.sessionLogDao.createSessionLog(
      id: 'log-1',
      planSessionId: sessionId,
      loggedAt: DateTime(2026, 9, 1),
      entries: const [
        LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
      ],
    );

    await forkPlanWithModifiedSession(
      db,
      sourcePlanId: 'plan-1',
      newPlanName: 'Plan A (edited)',
      editedSessionId: sessionId,
      newExercisesForEditedSession: const [],
    );

    final logs = await db.sessionLogDao.getLogsForPlanSession(sessionId);
    expect(
      logs,
      hasLength(1),
      reason: 'the log must still be readable via the original session id',
    );
  });
}
