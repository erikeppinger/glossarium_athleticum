import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/data/daos/session_log_dao.dart';
import 'package:training_app/export/backup_export.dart';
import 'package:training_app/import/backup_import.dart';
import 'package:training_app/security/backup_encryption.dart';

void main() {
  // importBackupJson re-seeds the exercise library, which reads the bundled
  // CSV asset via rootBundle - that needs the Flutter test binding even
  // though this file otherwise has no widgets.
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> seedFullState() async {
    // A seed-library exercise (should NOT be duplicated into the backup)...
    await db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: 'EX_BP',
        name: 'Bench Press',
        category: 'Main Lift',
        movementPattern: 'Push',
        muscleGroups: 'Chest, Triceps',
        equipment: 'Barbell',
        difficulty: 'Intermediate',
        measurementType: 'Weight x Reps',
      ),
    );
    // ...and a custom exercise (should be backed up).
    await db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: 'CUSTOM1',
        name: 'My Weird Machine',
        category: 'Custom',
        movementPattern: '',
        muscleGroups: 'Back, Shoulders',
        equipment: '',
        difficulty: 'Beginner',
        measurementType: 'Weight x Reps',
        isCustom: const Value(true),
      ),
    );

    await db.planDao.createPlan(
      id: 'plan-1',
      name: 'My Plan',
      sessions: [
        const PlanSessionInput(
          weekNumber: 1,
          day: 'Mon',
          sessionName: 'Push Day',
          exercises: [
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
        // Same session name in a different week - the ambiguity case
        // week_number/day/session_name matching is meant to handle.
        const PlanSessionInput(
          weekNumber: 2,
          day: 'Mon',
          sessionName: 'Push Day',
          exercises: [
            PlanExerciseInput(
              order: 1,
              exerciseId: 'EX_BP',
              exerciseName: 'Bench Press',
              sets: 4,
              reps: '8-10',
              weightIntensity: '65kg',
              restSec: 90,
            ),
          ],
        ),
      ],
    );

    final details = await db.planDao.getPlanDetails('plan-1');
    final week1Session = details!.sessions
        .firstWhere((s) => s.session.weekNumber == 1)
        .session
        .id;
    final week2Session = details.sessions
        .firstWhere((s) => s.session.weekNumber == 2)
        .session
        .id;

    await db.sessionLogDao.createSessionLog(
      id: 'log-week1',
      planSessionId: week1Session,
      loggedAt: DateTime(2026, 8, 20),
      entries: const [
        LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
      ],
    );
    await db.sessionLogDao.createSessionLog(
      id: 'log-week2',
      planSessionId: week2Session,
      loggedAt: DateTime(2026, 8, 27),
      entries: const [
        LoggedSetInput(
          exerciseId: 'EX_BP',
          setNumber: 1,
          reps: 8,
          weight: 65,
          isPr: true,
        ),
      ],
    );
  }

  test('buildBackupJson only includes custom exercises, not seed ones', () async {
    await seedFullState();
    final backup = await buildBackupJson(db);
    final exerciseIds = (backup['exercises'] as List)
        .map((e) => (e as Map)['id'])
        .toList();
    expect(exerciseIds, ['CUSTOM1']);
  });

  test(
    'full restore round-trip: wipe -> import -> logs re-linked to the correct week',
    () async {
      await seedFullState();
      final backup = await buildBackupJson(db, appVersion: '1.0.0-test');

      await importBackupJson(backup, db);

      final customExercises = await db.exerciseDao.getCustomExercises();
      expect(customExercises.map((e) => e.name), ['My Weird Machine']);
      expect(customExercises.single.muscleGroups, 'Back, Shoulders');

      final plans = await db.planDao.getAllPlans();
      expect(plans.map((p) => p.name), ['My Plan']);

      final details = await db.planDao.getPlanDetails('plan-1');
      expect(details, isNotNull);
      final week1 = details!.sessions.firstWhere(
        (s) => s.session.weekNumber == 1,
      );
      final week2 = details.sessions.firstWhere(
        (s) => s.session.weekNumber == 2,
      );

      final week1Logs = await db.sessionLogDao.getLogsForPlanSession(
        week1.session.id,
      );
      final week2Logs = await db.sessionLogDao.getLogsForPlanSession(
        week2.session.id,
      );
      expect(week1Logs, hasLength(1));
      expect(week2Logs, hasLength(1));

      final week1Sets = await db.sessionLogDao.getLoggedSetsForSessionLog(
        week1Logs.single.id,
      );
      final week2Sets = await db.sessionLogDao.getLoggedSetsForSessionLog(
        week2Logs.single.id,
      );
      // The critical assertion: week 1's log has the 60kg set and week 2's
      // has the 65kg PR set - if the week_number/day disambiguation didn't
      // work, these could easily end up swapped or merged.
      expect(week1Sets.single.weight, 60.0);
      expect(week2Sets.single.weight, 65.0);
      expect(week2Sets.single.isPr, isTrue);
    },
  );

  test('encrypted round-trip: export -> encrypt -> decrypt -> restore', () async {
    await seedFullState();
    const passphrase = 'a very good passphrase';
    final backup = await buildBackupJson(db);

    final envelope = await encryptBackup(jsonEncode(backup), passphrase);
    final decryptedJson = await decryptBackup(envelope, passphrase);
    final decryptedBackup = jsonDecode(decryptedJson) as Map<String, dynamic>;

    await importBackupJson(decryptedBackup, db);

    final plans = await db.planDao.getAllPlans();
    expect(plans.map((p) => p.name), ['My Plan']);
  });

  test('body measurements survive an export/restore round-trip', () async {
    await seedFullState();
    await db.bodyMeasurementDao.upsert(
      id: 'bm-1',
      measuredAt: DateTime(2026, 8, 20),
      weightKg: 82.5,
      waistCm: 88,
      notes: 'Morning, fasted',
    );

    final backup = await buildBackupJson(db);
    await importBackupJson(backup, db);

    final measurements = await db.bodyMeasurementDao.getAll();
    expect(measurements, hasLength(1));
    expect(measurements.single.weightKg, 82.5);
    expect(measurements.single.waistCm, 88);
    expect(measurements.single.notes, 'Morning, fasted');
    expect(measurements.single.measuredAt, DateTime(2026, 8, 20));
  });

  test('an ad-hoc activity survives an export/restore round-trip', () async {
    await seedFullState();
    await db.sessionLogDao.createAdHocActivity(
      id: 'activity-1',
      loggedAt: DateTime(2026, 8, 22),
      activityName: 'Walk',
      durationSec: 1800,
      distance: 3.2,
      notes: 'Around the block',
    );

    final backup = await buildBackupJson(db);
    final activityJson = (backup['session_logs'] as List).firstWhere(
      (e) => (e as Map)['activity_name'] == 'Walk',
    );
    expect(
      activityJson['plan_id'],
      isNull,
      reason: 'an ad-hoc activity has no plan session to key back onto',
    );

    await importBackupJson(backup, db);

    final activities = await db.sessionLogDao.getAdHocActivities();
    expect(activities, hasLength(1));
    expect(activities.single.activityName, 'Walk');
    expect(activities.single.durationSec, 1800);
    expect(activities.single.distance, 3.2);
    expect(activities.single.notes, 'Around the block');
    expect(activities.single.loggedAt, DateTime(2026, 8, 22));
  });

  test('a backup with no body_measurements key still restores', () async {
    // Backups taken before body measurements existed omit the key entirely;
    // that's "none recorded", not a malformed file.
    await seedFullState();
    final backup = await buildBackupJson(db);
    backup.remove('body_measurements');

    await importBackupJson(backup, db);

    expect(await db.bodyMeasurementDao.getAll(), isEmpty);
    expect((await db.planDao.getAllPlans()).map((p) => p.name), ['My Plan']);
  });

  test('custom exercise attribution and image survive a round-trip', () async {
    // Regression: author/sourcePlanName/imagePath were silently dropped by
    // export, so a restored library lost creator attribution entirely.
    // Extended when image *bytes* started travelling with the backup too -
    // restoring onto a fresh attachments directory (simulating a different
    // device) should recreate the actual file, not just the filename.
    final tempRoot = await Directory.systemTemp.createTemp(
      'backup_image_test',
    );
    final sourceDir = Directory('${tempRoot.path}/source');
    final restoredDir = Directory('${tempRoot.path}/restored');
    await sourceDir.create(recursive: true);
    await File('${sourceDir.path}/12345.jpg').writeAsBytes([1, 2, 3, 4, 5]);

    await db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: 'EX_CUSTOM',
        name: 'Coach Special',
        category: 'Custom',
        movementPattern: '',
        muscleGroups: '',
        equipment: '',
        difficulty: 'Beginner',
        measurementType: 'Weight x Reps',
        isCustom: const Value(true),
        author: const Value('Coach Erik'),
        sourcePlanName: const Value('Nine-Block Strength Program'),
        imagePath: const Value('12345.jpg'),
        imagePaths: const Value('12345.jpg'),
      ),
    );

    final backup = await buildBackupJson(db, attachmentsDirectory: sourceDir);
    expect(
      (backup['exercises'] as List).single['images_data_base64'],
      isNotNull,
      reason: 'the image bytes should be embedded in the backup itself',
    );

    await importBackupJson(
      backup,
      db,
      attachmentsDirectory: restoredDir,
    );

    final restored = await db.exerciseDao.getExerciseById('EX_CUSTOM');
    expect(restored, isNotNull);
    expect(restored!.author, 'Coach Erik');
    expect(restored.sourcePlanName, 'Nine-Block Strength Program');
    expect(restored.imagePaths, '12345.jpg');
    expect(
      await File('${restoredDir.path}/12345.jpg').readAsBytes(),
      [1, 2, 3, 4, 5],
      reason: 'the actual image file should be recreated on restore, not '
          'just the filename reference',
    );

    await tempRoot.delete(recursive: true);
  });

  test('importBackupJson throws for an unsupported schema version', () async {
    await expectLater(
      importBackupJson({
        'schema_version': 999,
        'exercises': [],
        'plans': [],
      }, db),
      throwsA(isA<BackupJsonFormatException>()),
    );
  });

  test('importBackupJson throws for missing required structure', () async {
    await expectLater(
      importBackupJson({'schema_version': 1}, db),
      throwsA(isA<BackupJsonFormatException>()),
    );
  });
}
