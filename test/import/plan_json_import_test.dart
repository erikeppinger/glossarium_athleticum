import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/export/plan_export.dart';
import 'package:training_app/import/plan_json_import.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> seedLibrary() => db.exerciseDao.upsertExercise(
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

  test('round-trips a plan: export -> wipe -> import -> identical', () async {
    await seedLibrary();
    final assignedDate = DateTime(2026, 9, 1);
    await db.planDao.createPlan(
      id: 'plan-1',
      name: 'My Plan',
      notes: 'Some notes',
      sessions: [
        PlanSessionInput(
          weekNumber: 1,
          day: 'Mon',
          sessionName: 'Push Day',
          assignedDate: assignedDate,
          exercises: const [
            PlanExerciseInput(
              order: 1,
              exerciseId: 'EX_BP',
              exerciseName: 'Bench Press',
              sets: 4,
              reps: '8-10',
              weightIntensity: '60kg',
              restSec: 90,
            ),
          ],
        ),
      ],
    );

    final original = await db.planDao.getPlanDetails('plan-1');
    final json = planToJson(original!);

    // Simulate moving to a fresh device: wipe everything, reseed the shared
    // library (same ids since it's the same bundled CSV), then import.
    await db.maintenanceDao.wipeAllData();
    await seedLibrary();

    final newPlanId = await importPlanJson(json, db);
    final imported = await db.planDao.getPlanDetails(newPlanId);

    expect(imported, isNotNull);
    expect(imported!.plan.name, 'My Plan');
    expect(imported.plan.notes, 'Some notes');
    expect(imported.plan.createdAt, original.plan.createdAt);
    expect(imported.sessions, hasLength(1));
    expect(imported.sessions.single.session.assignedDate, assignedDate);
    expect(imported.sessions.single.exercises.single.exerciseId, 'EX_BP');
    expect(imported.sessions.single.exercises.single.weightIntensity, '60kg');
  });

  test('resolves exercise_id by name when the id is missing on this device', () async {
    await seedLibrary();
    final json = {
      'schema_version': 1,
      'id': 'plan-1',
      'name': 'Imported Plan',
      'weeks': [
        {
          'week_number': 1,
          'sessions': [
            {
              'day': 'Mon',
              'session_name': 'Push Day',
              'exercises': [
                {
                  'order': 1,
                  'exercise_id': 'EX_ON_OTHER_DEVICE', // doesn't exist here
                  'exercise_name': 'Bench Press', // but the name matches
                  'sets': 3,
                  'reps': '8',
                },
              ],
            },
          ],
        },
      ],
    };

    final planId = await importPlanJson(json, db);
    final details = await db.planDao.getPlanDetails(planId);
    expect(details!.sessions.single.exercises.single.exerciseId, 'EX_BP');
  });

  test('creates a custom exercise when neither id nor name resolve', () async {
    await seedLibrary();
    final json = {
      'schema_version': 1,
      'id': 'plan-1',
      'name': 'Imported Plan',
      'weeks': [
        {
          'week_number': 1,
          'sessions': [
            {
              'day': 'Mon',
              'session_name': 'Push Day',
              'exercises': [
                {
                  'order': 1,
                  'exercise_id': null,
                  'exercise_name': 'Some Totally New Exercise',
                  'sets': 3,
                  'reps': '8',
                },
              ],
            },
          ],
        },
      ],
    };

    final planId = await importPlanJson(json, db);
    final details = await db.planDao.getPlanDetails(planId);
    final exerciseId = details!.sessions.single.exercises.single.exerciseId;
    expect(exerciseId, isNotNull);

    final createdExercise = await db.exerciseDao.getExerciseById(exerciseId!);
    expect(createdExercise!.name, 'Some Totally New Exercise');
    expect(createdExercise.isCustom, isTrue);
  });

  test('throws for an unsupported schema version', () async {
    final json = {'schema_version': 999, 'name': 'x', 'weeks': []};
    await expectLater(
      importPlanJson(json, db),
      throwsA(isA<PlanJsonFormatException>()),
    );
  });

  test('throws for a file missing required structure', () async {
    final json = {'schema_version': 1};
    await expectLater(
      importPlanJson(json, db),
      throwsA(isA<PlanJsonFormatException>()),
    );
  });
}
