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
  int get schemaVersion => 6;

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
