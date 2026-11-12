import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/daos/block_dao.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/data/daos/session_log_dao.dart';
import 'package:training_app/export/backup_export.dart';
import 'package:training_app/import/backup_import.dart';

// Found in the 2026-11 code review: a backup restore lost things that were
// on the device - workouts of a plan deleted with "keep history", reusable
// blocks, which plans were archived, favourites - and failed outright for a
// plan with two sessions of the same week, day and name.
void main() {
  // The restore re-seeds the bundled exercise library.
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> addExercise(String id) => db.exerciseDao.upsertExercise(
    ExercisesCompanion.insert(
      id: id,
      name: 'Squat $id',
      category: 'Main Lift',
      movementPattern: 'Squat',
      muscleGroups: 'Legs',
      equipment: 'Barbell',
      difficulty: 'Intermediate',
      measurementType: 'Weight x Reps',
      isCustom: const Value(true),
    ),
  );

  Future<int> addPlan(String id, {int sessions = 1}) async {
    await db.planDao.createPlan(
      id: id,
      name: 'Plan $id',
      sessions: [
        for (var i = 0; i < sessions; i++)
          const PlanSessionInput(
            weekNumber: 1,
            day: 'Mon',
            sessionName: 'Lower',
            exercises: [
              PlanExerciseInput(
                order: 1,
                exerciseId: 'ex',
                exerciseName: 'Squat ex',
                sets: 3,
                reps: '5',
              ),
            ],
          ),
      ],
    );
    return (await db.planDao.getPlanDetails(id))!.sessions.first.session.id;
  }

  Future<void> logWorkout(String logId, int sessionId) =>
      db.sessionLogDao.createSessionLog(
        id: logId,
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 3, 1),
        entries: const [
          LoggedSetInput(exerciseId: 'ex', setNumber: 1, reps: 5, weight: 100),
        ],
      );

  Future<void> backupAndRestore() async =>
      importBackupJson(await buildBackupJson(db), db);

  test('workouts of a plan deleted with "keep history" survive', () async {
    await addExercise('ex');
    final sessionId = await addPlan('gone');
    await logWorkout('log-1', sessionId);
    await db.planDao.deletePlanKeepingHistory('gone');

    await backupAndRestore();

    final history = await db.sessionLogDao.getWorkoutHistory();
    expect(history.map((w) => w.logId), ['log-1']);
    expect(history.single.sessionName, 'Lower');
    expect(history.single.setCount, 1);
    expect(await db.planDao.getAllPlans(), isEmpty, reason: 'still deleted');
  });

  test('two sessions with the same week, day and name still restore', () async {
    await addExercise('ex');
    final sessionId = await addPlan('twins', sessions: 2);
    await logWorkout('log-1', sessionId);

    await backupAndRestore();

    expect(
      (await db.planDao.getPlanDetails('twins'))!.sessions,
      hasLength(2),
    );
    expect(
      (await db.sessionLogDao.getWorkoutHistory()).map((w) => w.logId),
      ['log-1'],
    );
  });

  test('blocks, archived plans, reminders and favourites come back', () async {
    await addExercise('ex');
    await addPlan('archived');
    await db.planDao.archivePlan('archived');
    await db.planDao.setReportPreference(
      planId: 'archived',
      preference: 'enabled',
      frequencyDays: 14,
    );
    await db.exerciseDao.setFavorite('ex', true);
    await db.blockDao.createBlock(
      name: 'Warm-up',
      notes: 'easy',
      exercises: const [
        BlockExerciseInput(
          order: 1,
          exerciseId: 'ex',
          exerciseName: 'Squat ex',
          sets: 2,
          reps: '10',
          restSec: 30,
        ),
      ],
    );

    await backupAndRestore();

    final plan = (await db.planDao.getAllPlans()).single;
    expect(plan.archivedAt, isNotNull);
    expect(plan.reportPreference, 'enabled');
    expect(plan.reportFrequencyDays, 14);
    expect(await db.exerciseDao.getFavoriteIds(), ['ex']);
    final block = (await db.blockDao.getAllBlocks()).single;
    expect(block.name, 'Warm-up');
    final details = (await db.blockDao.getBlockDetails(block.id))!;
    expect(details.exercises.single.reps, '10');
    expect(details.exercises.single.restSec, 30);
  });

  test('a backup from before these were included still restores', () async {
    await addExercise('ex');
    await addPlan('old');
    final backup = await buildBackupJson(db)
      ..remove('blocks')
      ..remove('favorite_exercise_ids');
    for (final plan in backup['plans'] as List) {
      (plan as Map).remove('local_state');
    }

    await importBackupJson(backup, db);

    expect((await db.planDao.getAllPlans()).single.archivedAt, isNull);
  });

  test('"Delete all data" removes blocks too', () async {
    await db.blockDao.createBlock(name: 'Warm-up', exercises: const []);
    await db.maintenanceDao.wipeAllData();
    expect(await db.blockDao.getAllBlocks(), isEmpty);
  });
}
