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
    await db.planDao.deletePlan('plan-1');
    expect(await db.planDao.getPlanDetails('plan-1'), isNull);
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
}
