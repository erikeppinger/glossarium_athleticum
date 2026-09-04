import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'daos/body_measurement_dao.dart';
import 'daos/exercise_dao.dart';
import 'daos/maintenance_dao.dart';
import 'daos/plan_dao.dart';
import 'daos/session_log_dao.dart';
import 'tables/body_measurements_table.dart';
import 'tables/exercises_table.dart';
import 'tables/plans_table.dart';
import 'tables/session_logs_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Exercises,
    Plans,
    PlanSessions,
    PlanExercises,
    SessionLogs,
    LoggedSets,
    BodyMeasurements,
  ],
  daos: [
    ExerciseDao,
    PlanDao,
    SessionLogDao,
    MaintenanceDao,
    BodyMeasurementDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(sessionLogs);
        await m.createTable(loggedSets);
      }
      if (from < 3) {
        await m.addColumn(exercises, exercises.sourcePlanName);
        await m.addColumn(exercises, exercises.author);
      }
      if (from < 4) {
        await m.createTable(bodyMeasurements);
      }
      if (from < 5) {
        await m.addColumn(plans, plans.archivedAt);
      }
      if (from < 6) {
        await m.addColumn(exercises, exercises.imagePath);
      }
      if (from < 7) {
        await m.addColumn(sessionLogs, sessionLogs.notes);
      }
      if (from < 8) {
        // planSessionId's NOT NULL -> nullable change (to allow ad-hoc
        // activities with no scheduled session) isn't an addColumn - SQLite
        // can't ALTER a column's nullability in place, so this recreates
        // the whole table (matching-named columns copy over; the three new
        // ones default to null for existing rows, which is correct).
        // newColumns must list every column that doesn't exist on the old
        // table yet - without it, the generated COPY statement tries to
        // SELECT them from the source table and fails with "no such column".
        await m.alterTable(
          TableMigration(
            sessionLogs,
            newColumns: [
              sessionLogs.activityName,
              sessionLogs.durationSec,
              sessionLogs.distance,
            ],
          ),
        );
      }
      if (from < 9) {
        await m.addColumn(plans, plans.reportPreference);
        await m.addColumn(plans, plans.reportFrequencyDays);
        await m.addColumn(plans, plans.reportOptInAt);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'training_app',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
