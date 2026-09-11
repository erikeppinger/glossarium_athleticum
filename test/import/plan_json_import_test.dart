import 'dart:io';

import 'package:drift/drift.dart' show Value;
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
    final assignedDates = [DateTime(2026, 9, 1), DateTime(2026, 9, 8)];
    await db.planDao.createPlan(
      id: 'plan-1',
      name: 'My Plan',
      notes: 'Some notes',
      sessions: [
        PlanSessionInput(
          weekNumber: 1,
          day: 'Mon',
          sessionName: 'Push Day',
          assignedDates: assignedDates,
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
    expect(imported.sessions.single.dates, assignedDates);
    expect(imported.sessions.single.exercises.single.exerciseId, 'EX_BP');
    expect(imported.sessions.single.exercises.single.weightIntensity, '60kg');
  });

  // Regression: schema_version 2 replaced a session's singular
  // 'assigned_date' field with an 'assigned_dates' array - a file exported
  // before that bump (or shared from an older install) must still import
  // correctly rather than silently losing its scheduled date.
  test(
    'imports a pre-schema_version-2 file using the old singular assigned_date field',
    () async {
      await seedLibrary();
      final json = {
        'schema_version': 1,
        'id': 'plan-legacy',
        'name': 'Legacy Plan',
        'notes': '',
        'weeks': [
          {
            'week_number': 1,
            'sessions': [
              {
                'day': 'Mon',
                'session_name': 'Push Day',
                'assigned_date': '2026-09-01',
                'exercises': [
                  {
                    'order': 1,
                    'exercise_id': 'EX_BP',
                    'exercise_name': 'Bench Press',
                    'sets': 4,
                    'reps': '8-10',
                  },
                ],
              },
            ],
          },
        ],
      };

      final planId = await importPlanJson(json, db);
      final imported = await db.planDao.getPlanDetails(planId);

      expect(imported!.sessions.single.dates, [DateTime(2026, 9, 1)]);
    },
  );

  test(
    'a custom exercise\'s image travels through a single-plan export onto a fresh device',
    () async {
      // Regression: a plain plan export only ever carried an exercise's
      // id/name, so a plan built around a custom exercise with a photo
      // silently lost that exercise's image (and full detail) when imported
      // somewhere that didn't already have it.
      final tempRoot = await Directory.systemTemp.createTemp(
        'plan_export_image_test',
      );
      final sourceDir = Directory('${tempRoot.path}/source');
      final restoredDir = Directory('${tempRoot.path}/restored');
      await sourceDir.create(recursive: true);
      await File('${sourceDir.path}/photo.jpg').writeAsBytes([9, 8, 7]);

      await db.exerciseDao.upsertExercise(
        ExercisesCompanion.insert(
          id: 'EX_CUSTOM',
          name: 'Garage Pull-Up Bar',
          category: 'Custom',
          movementPattern: '',
          muscleGroups: '',
          equipment: '',
          difficulty: 'Beginner',
          measurementType: 'Weight x Reps',
          isCustom: const Value(true),
          imagePath: const Value('photo.jpg'),
          imagePaths: const Value('photo.jpg'),
        ),
      );
      await db.planDao.createPlan(
        id: 'plan-1',
        name: 'Garage Plan',
        sessions: const [
          PlanSessionInput(
            weekNumber: 1,
            day: 'Mon',
            sessionName: 'Pull Day',
            exercises: [
              PlanExerciseInput(
                order: 1,
                exerciseId: 'EX_CUSTOM',
                exerciseName: 'Garage Pull-Up Bar',
                sets: 3,
                reps: '8',
              ),
            ],
          ),
        ],
      );

      final details = await db.planDao.getPlanDetails('plan-1');
      final json = await planToJsonWithImages(
        details!,
        db,
        attachmentsDirectory: sourceDir,
      );
      expect(
        (json['exercises'] as List).single['images_data_base64'],
        isNotNull,
      );

      // Simulate a fresh device: wipe everything (the custom exercise and
      // its image reference both disappear) then import.
      await db.maintenanceDao.wipeAllData();

      final newPlanId = await importPlanJson(
        json,
        db,
        attachmentsDirectory: restoredDir,
      );
      final imported = await db.planDao.getPlanDetails(newPlanId);
      final exerciseId = imported!.sessions.single.exercises.single.exerciseId;

      final restoredExercise = await db.exerciseDao.getExerciseById(
        exerciseId!,
      );
      expect(restoredExercise!.imagePaths, 'photo.jpg');
      expect(
        await File('${restoredDir.path}/photo.jpg').readAsBytes(),
        [9, 8, 7],
      );

      await tempRoot.delete(recursive: true);
    },
  );

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
