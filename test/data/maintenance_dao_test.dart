import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/data/daos/session_log_dao.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> seedSomeData() async {
    await db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: 'EX1',
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
              exerciseId: 'EX1',
              exerciseName: 'Bench Press',
              sets: 1,
              reps: '8',
            ),
          ],
        ),
      ],
    );
    final details = await db.planDao.getPlanDetails('plan-1');
    final sessionId = details!.sessions.single.session.id;
    await db.sessionLogDao.createSessionLog(
      id: 'log-1',
      planSessionId: sessionId,
      loggedAt: DateTime(2026, 8, 20),
      entries: const [
        LoggedSetInput(exerciseId: 'EX1', setNumber: 1, reps: 8, weight: 60),
      ],
    );
  }

  test('wipeAllData removes every row from every table', () async {
    await seedSomeData();

    await db.maintenanceDao.wipeAllData();

    expect(await db.exerciseDao.getAllExercises(), isEmpty);
    expect(await db.planDao.getAllPlans(), isEmpty);
    expect(await db.sessionLogDao.getAllSessionLogsWithSets(), isEmpty);
  });

  test('wipeAllData on an already-empty database is a no-op, not an error', () async {
    await db.maintenanceDao.wipeAllData();
    expect(await db.exerciseDao.getAllExercises(), isEmpty);
  });

  test('getAllSessionLogsWithSets returns each log paired with its sets', () async {
    await seedSomeData();
    final logs = await db.sessionLogDao.getAllSessionLogsWithSets();
    expect(logs, hasLength(1));
    expect(logs.single.log.id, 'log-1');
    expect(logs.single.sets, hasLength(1));
    expect(logs.single.sets.single.weight, 60.0);
  });

  test('getCustomExercises returns only exercises marked custom', () async {
    await db.exerciseDao.upsertExercises([
      ExercisesCompanion.insert(
        id: 'SEED1',
        name: 'Seed Exercise',
        category: 'Main Lift',
        movementPattern: 'Push',
        muscleGroups: 'Chest',
        equipment: 'Barbell',
        difficulty: 'Beginner',
        measurementType: 'Weight x Reps',
      ),
      ExercisesCompanion.insert(
        id: 'CUSTOM1',
        name: 'My Custom Exercise',
        category: 'Custom',
        movementPattern: '',
        muscleGroups: '',
        equipment: '',
        difficulty: 'Beginner',
        measurementType: 'Weight x Reps',
        isCustom: const Value(true),
      ),
    ]);

    final custom = await db.exerciseDao.getCustomExercises();
    expect(custom.map((e) => e.id), ['CUSTOM1']);
  });
}
