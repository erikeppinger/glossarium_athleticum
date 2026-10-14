import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/data/daos/session_log_dao.dart';
import 'package:training_app/export/library_export.dart';
import 'package:training_app/export/plan_export.dart';
import 'package:training_app/import/json_object.dart';
import 'package:training_app/import/library_import.dart';
import 'package:training_app/import/plan_json_import.dart';
import 'package:training_app/import/plan_sync.dart';

// A damaged file must never half-import: whatever it managed to write
// before failing is rolled back, and the failure arrives as the importer's
// own format exception so the screens can show a message.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  ExercisesCompanion customExercise(String id, String name) =>
      ExercisesCompanion.insert(
        id: id,
        name: name,
        category: 'Accessory',
        movementPattern: 'Pull',
        muscleGroups: 'Back',
        equipment: 'Cable',
        difficulty: 'Intermediate',
        measurementType: 'Weight x Reps',
        isCustom: const Value(true),
      );

  Future<void> createPlanWith(String id, String exerciseId) =>
      db.planDao.createPlan(
        id: id,
        name: 'Plan $id',
        sessions: [
          PlanSessionInput(
            weekNumber: 1,
            day: 'Mon',
            sessionName: 'Pull Day',
            exercises: [
              PlanExerciseInput(
                order: 1,
                exerciseId: exerciseId,
                exerciseName: 'Face Pull',
                sets: 3,
                reps: '12',
              ),
            ],
          ),
        ],
      );

  group('decodeJsonObject', () {
    test('returns a JSON object', () {
      expect(decodeJsonObject('{"a": 1}'), {'a': 1});
    });

    test('rejects text that is not JSON, or JSON that is not an object', () {
      expect(() => decodeJsonObject('not json'), throwsFormatException);
      expect(() => decodeJsonObject('[1, 2]'), throwsFormatException);
      expect(() => decodeJsonObject('42'), throwsFormatException);
    });
  });

  test('a damaged plan file writes nothing, not even its exercises', () async {
    await db.exerciseDao.upsertExercise(customExercise('EX_FP', 'Face Pull'));
    await createPlanWith('source', 'EX_FP');
    final json = await planToJsonWithImages(
      (await db.planDao.getPlanDetails('source'))!,
      db,
    );
    // Arrive on a fresh device, where the embedded exercise is new...
    await db.close();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // ...with one session's exercise damaged.
    final session = ((json['weeks'] as List).first as Map)['sessions'] as List;
    ((session.first as Map)['exercises'] as List).first['sets'] = 'three';

    await expectLater(
      importPlanJson(json, db),
      throwsA(isA<PlanJsonFormatException>()),
    );
    expect(await db.planDao.getAllPlans(), isEmpty);
    expect(await db.exerciseDao.getCustomExercises(), isEmpty);
  });

  test('a damaged library file writes none of its exercises', () async {
    await db.exerciseDao.upsertExercise(customExercise('EX_A', 'Move A'));
    await db.exerciseDao.upsertExercise(customExercise('EX_B', 'Move B'));
    final json = await buildLibraryJson(db);
    await db.close();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // The first entry is fine; the second is damaged.
    (json['exercises'] as List).last['name'] = 42;

    await expectLater(
      importLibraryJson(json, db),
      throwsA(isA<LibraryJsonFormatException>()),
    );
    expect(await db.exerciseDao.getCustomExercises(), isEmpty);
  });

  test(
    'a damaged incoming sync version keeps the local plan and its logs',
    () async {
      await db.exerciseDao.upsertExercise(customExercise('EX_FP', 'Face Pull'));
      await createPlanWith('shared', 'EX_FP');
      final local = (await db.planDao.getPlanDetails('shared'))!;
      await db.sessionLogDao.createSessionLog(
        id: 'log-1',
        planSessionId: local.sessions.first.session.id,
        loggedAt: DateTime(2026, 10, 1),
        entries: const [
          LoggedSetInput(
            exerciseId: 'EX_FP',
            setNumber: 1,
            reps: 12,
            weight: 20,
          ),
        ],
      );

      final incoming = planToJson(local);
      incoming['updated_at'] = DateTime(2026, 10, 5).toIso8601String();
      final session =
          ((incoming['weeks'] as List).first as Map)['sessions'] as List;
      ((session.first as Map)['exercises'] as List).first['sets'] = 'three';

      await expectLater(
        applyIncomingPlan(incoming, db),
        throwsA(isA<PlanJsonFormatException>()),
      );

      final after = await db.planDao.getPlanDetails('shared');
      expect(after, isNotNull);
      expect(after!.sessions.single.exercises.single.sets, 3);
      final logs = await db.sessionLogDao.getLogsForPlanSession(
        after.sessions.single.session.id,
      );
      expect(logs.map((l) => l.id), ['log-1']);
    },
  );
}
