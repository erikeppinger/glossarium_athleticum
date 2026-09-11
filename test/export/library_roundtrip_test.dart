import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/export/library_export.dart';
import 'package:training_app/import/library_import.dart';
import 'package:training_app/security/backup_encryption.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> seedLibrary() async {
    // A seed-library exercise (should NOT be included in the export)...
    await db.exerciseDao.upsertExercise(
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
    // ...and two custom exercises (should be exported).
    await db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: 'CUSTOM1',
        name: 'Garage Pull-Up Bar',
        category: 'Custom',
        movementPattern: 'Pull',
        muscleGroups: 'Back',
        equipment: 'Pull-up bar',
        difficulty: 'Beginner',
        measurementType: 'Weight x Reps',
        isCustom: const Value(true),
        author: const Value('Coach Erik'),
      ),
    );
    await db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: 'CUSTOM2',
        name: 'Sandbag Carry',
        category: 'Custom',
        movementPattern: 'Carry',
        muscleGroups: 'Full Body',
        equipment: 'Sandbag',
        difficulty: 'Intermediate',
        measurementType: 'Distance',
        isCustom: const Value(true),
      ),
    );
  }

  test('buildLibraryJson only includes custom exercises, not seed ones', () async {
    await seedLibrary();
    final json = await buildLibraryJson(db);
    final ids = (json['exercises'] as List)
        .map((e) => (e as Map)['id'])
        .toList();
    expect(ids, containsAll(['CUSTOM1', 'CUSTOM2']));
    expect(ids, isNot(contains('EX_BP')));
  });

  test('round-trips onto a fresh device: wipe -> import -> identical', () async {
    await seedLibrary();
    final json = await buildLibraryJson(db);

    await db.maintenanceDao.wipeAllData();

    final count = await importLibraryJson(json, db);
    expect(count, 2);

    final restored = await db.exerciseDao.getCustomExercises();
    expect(restored.map((e) => e.name), containsAll(['Garage Pull-Up Bar', 'Sandbag Carry']));
    final pullUp = restored.firstWhere((e) => e.id == 'CUSTOM1');
    expect(pullUp.author, 'Coach Erik');
    expect(pullUp.muscleGroups, 'Back');
  });

  test('importing does not touch plans or session logs', () async {
    await seedLibrary();
    await db.planDao.createPlan(id: 'plan-1', name: 'My Plan', sessions: const []);

    final json = await buildLibraryJson(db);
    await importLibraryJson(json, db);

    final plans = await db.planDao.getAllPlans();
    expect(plans.map((p) => p.name), ['My Plan']);
  });

  test('an exercise\'s image travels through the export/import round-trip', () async {
    final tempRoot = await Directory.systemTemp.createTemp('library_image_test');
    final sourceDir = Directory('${tempRoot.path}/source');
    final restoredDir = Directory('${tempRoot.path}/restored');
    await sourceDir.create(recursive: true);
    await File('${sourceDir.path}/photo.jpg').writeAsBytes([1, 2, 3]);

    await db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: 'CUSTOM1',
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

    final json = await buildLibraryJson(db, attachmentsDirectory: sourceDir);
    await db.maintenanceDao.wipeAllData();
    await importLibraryJson(json, db, attachmentsDirectory: restoredDir);

    final restored = await db.exerciseDao.getExerciseById('CUSTOM1');
    expect(restored!.imagePaths, 'photo.jpg');
    expect(await File('${restoredDir.path}/photo.jpg').readAsBytes(), [1, 2, 3]);

    await tempRoot.delete(recursive: true);
  });

  test('an encrypted library export round-trips with a passphrase', () async {
    await seedLibrary();
    const passphrase = 'a very good passphrase';
    final json = await buildLibraryJson(db);
    final envelope = await encryptBackup(jsonEncode(json), passphrase);

    final decrypted = await decryptBackup(envelope, passphrase);
    final decodedJson = jsonDecode(decrypted) as Map<String, dynamic>;

    await db.maintenanceDao.wipeAllData();
    final count = await importLibraryJson(decodedJson, db);
    expect(count, 2);
  });

  test('throws for an unsupported schema version', () async {
    await expectLater(
      importLibraryJson({'schema_version': 999, 'exercises': []}, db),
      throwsA(isA<LibraryJsonFormatException>()),
    );
  });

  test('throws for a file missing required structure', () async {
    await expectLater(
      importLibraryJson({'schema_version': 1}, db),
      throwsA(isA<LibraryJsonFormatException>()),
    );
  });
}
