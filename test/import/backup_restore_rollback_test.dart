import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/export/backup_export.dart';
import 'package:training_app/import/backup_import.dart';

// Restoring a backup wipes the device's data and then imports the backup.
// If anything in the backup fails to import part-way through, the device
// must keep the data it had - not end up with a wiped, half-restored state.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test(
    'a backup that fails part-way leaves the existing data untouched',
    () async {
      await db.planDao.createPlan(
        id: 'plan-1',
        name: 'My Plan',
        sessions: const [
          PlanSessionInput(
            weekNumber: 1,
            day: 'Mon',
            sessionName: 'Push Day',
            exercises: [],
          ),
        ],
      );

      // A valid backup of that data, plus one damaged activity at the end.
      final backup = await buildBackupJson(db);
      backup['session_logs'] = [
        ...(backup['session_logs'] as List? ?? const []),
        {'id': 'broken', 'activity_name': 'Run', 'logged_at': 'not-a-date'},
      ];

      // Data that exists on the device before the restore is attempted.
      await db.planDao.createPlan(
        id: 'plan-2',
        name: 'Only On This Device',
        sessions: const [],
      );

      await expectLater(
        importBackupJson(backup, db),
        throwsA(isA<BackupJsonFormatException>()),
      );

      final plans = await db.planDao.getAllPlans();
      expect(
        plans.map((p) => p.name),
        unorderedEquals(['My Plan', 'Only On This Device']),
      );
    },
  );
}
