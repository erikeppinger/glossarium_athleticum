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
      ),
      PlanExerciseInput(
        order: 2,
        exerciseName: 'Overhead Press',
        sets: 3,
        reps: '8-10',
      ),
    ],
  );

  test('setSupersetGroup assigns a shared group id to every given exercise', () async {
    await db.planDao.createPlan(id: 'plan-1', name: 'Plan A', sessions: [pushDay]);
    final exercises =
        (await db.planDao.getPlanDetails('plan-1'))!.sessions.single.exercises;
    final ids = exercises.map((e) => e.id).toList();

    await db.planDao.setSupersetGroup(ids);

    final updated =
        (await db.planDao.getPlanDetails('plan-1'))!.sessions.single.exercises;
    expect(updated[0].supersetGroupId, isNotNull);
    expect(updated[0].supersetGroupId, updated[1].supersetGroupId);
  });

  test('a second group in the same session gets a non-colliding id', () async {
    await db.planDao.createPlan(id: 'plan-1', name: 'Plan A', sessions: [pushDay]);
    final details = (await db.planDao.getPlanDetails('plan-1'))!;
    final sessionId = details.sessions.single.session.id;
    final exercises = details.sessions.single.exercises;

    await db.planDao.addExerciseToSession(
      sessionId: sessionId,
      input: const PlanExerciseInput(
        order: 3,
        exerciseName: 'Lateral Raise',
        sets: 3,
        reps: '12',
      ),
    );
    final thirdExercise = (await db.planDao.getPlanDetails(
      'plan-1',
    ))!.sessions.single.exercises.firstWhere((e) => e.exerciseName == 'Lateral Raise');

    await db.planDao.setSupersetGroup([exercises[0].id, exercises[1].id]);
    await db.planDao.setSupersetGroup([thirdExercise.id]);

    final updated =
        (await db.planDao.getPlanDetails('plan-1'))!.sessions.single.exercises;
    final firstGroupId = updated
        .firstWhere((e) => e.id == exercises[0].id)
        .supersetGroupId;
    final secondGroupId = updated
        .firstWhere((e) => e.id == thirdExercise.id)
        .supersetGroupId;
    expect(firstGroupId, 1);
    expect(secondGroupId, 2);
  });

  test('throws when the given exercises span more than one session', () async {
    await db.planDao.createPlan(
      id: 'plan-1',
      name: 'Plan A',
      sessions: [
        pushDay,
        const PlanSessionInput(
          weekNumber: 1,
          day: 'Wed',
          sessionName: 'Pull Day',
          exercises: [
            PlanExerciseInput(
              order: 1,
              exerciseName: 'Barbell Row',
              sets: 4,
              reps: '8-10',
            ),
          ],
        ),
      ],
    );
    final sessions = (await db.planDao.getPlanDetails('plan-1'))!.sessions;
    final pushExerciseId = sessions
        .firstWhere((s) => s.session.sessionName == 'Push Day')
        .exercises
        .first
        .id;
    final pullExerciseId = sessions
        .firstWhere((s) => s.session.sessionName == 'Pull Day')
        .exercises
        .first
        .id;

    expect(
      () => db.planDao.setSupersetGroup([pushExerciseId, pullExerciseId]),
      throwsArgumentError,
    );
  });

  test('clearSupersetGroup only affects the targeted row', () async {
    await db.planDao.createPlan(id: 'plan-1', name: 'Plan A', sessions: [pushDay]);
    final exercises =
        (await db.planDao.getPlanDetails('plan-1'))!.sessions.single.exercises;
    await db.planDao.setSupersetGroup(exercises.map((e) => e.id).toList());

    await db.planDao.clearSupersetGroup(exercises[0].id);

    final updated =
        (await db.planDao.getPlanDetails('plan-1'))!.sessions.single.exercises;
    expect(updated.firstWhere((e) => e.id == exercises[0].id).supersetGroupId, isNull);
    expect(updated.firstWhere((e) => e.id == exercises[1].id).supersetGroupId, isNotNull);
  });

  test('grouping survives duplicateSessionToWeeks', () async {
    await db.planDao.createPlan(id: 'plan-1', name: 'Plan A', sessions: [pushDay]);
    final details = (await db.planDao.getPlanDetails('plan-1'))!;
    final sessionId = details.sessions.single.session.id;
    final exercises = details.sessions.single.exercises;
    await db.planDao.setSupersetGroup(exercises.map((e) => e.id).toList());

    await db.planDao.duplicateSessionToWeeks(
      sessionId: sessionId,
      weekNumbers: [2],
    );

    final week2 = (await db.planDao.getPlanDetails(
      'plan-1',
    ))!.sessions.firstWhere((s) => s.session.weekNumber == 2);
    expect(week2.exercises[0].supersetGroupId, isNotNull);
    expect(week2.exercises[0].supersetGroupId, week2.exercises[1].supersetGroupId);
  });

  test(
    'two different sessions can each independently use group id 1 without colliding',
    () async {
      await db.planDao.createPlan(
        id: 'plan-1',
        name: 'Plan A',
        sessions: [
          pushDay,
          const PlanSessionInput(
            weekNumber: 1,
            day: 'Wed',
            sessionName: 'Pull Day',
            exercises: [
              PlanExerciseInput(
                order: 1,
                exerciseName: 'Barbell Row',
                sets: 4,
                reps: '8-10',
              ),
              PlanExerciseInput(
                order: 2,
                exerciseName: 'Lat Pulldown',
                sets: 3,
                reps: '10-12',
              ),
            ],
          ),
        ],
      );
      final sessions = (await db.planDao.getPlanDetails('plan-1'))!.sessions;
      final pushExercises = sessions
          .firstWhere((s) => s.session.sessionName == 'Push Day')
          .exercises;
      final pullExercises = sessions
          .firstWhere((s) => s.session.sessionName == 'Pull Day')
          .exercises;

      await db.planDao.setSupersetGroup(pushExercises.map((e) => e.id).toList());
      await db.planDao.setSupersetGroup(pullExercises.map((e) => e.id).toList());

      final updated = (await db.planDao.getPlanDetails('plan-1'))!.sessions;
      final updatedPush = updated
          .firstWhere((s) => s.session.sessionName == 'Push Day')
          .exercises;
      final updatedPull = updated
          .firstWhere((s) => s.session.sessionName == 'Pull Day')
          .exercises;
      expect(updatedPush[0].supersetGroupId, 1);
      expect(updatedPull[0].supersetGroupId, 1);
    },
  );
}
