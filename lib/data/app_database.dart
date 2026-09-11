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
    PlanSessionDates,
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
  int get schemaVersion => 13;

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
      if (from < 10) {
        // A session's single assignedDate column becomes a child table so a
        // session can have several scheduled dates - carry every existing
        // date forward as that session's first row, then drop the column.
        // No newColumns needed on the TableMigration below: we're only
        // dropping a column here, not adding one, so the "new columns must
        // be listed or the COPY statement fails" gotcha (see the schema
        // 7->8 migration above) doesn't apply.
        await m.createTable(planSessionDates);
        await customStatement(
          'INSERT INTO plan_session_dates (session_id, date) '
          'SELECT id, assigned_date FROM plan_sessions '
          'WHERE assigned_date IS NOT NULL',
        );
        await m.alterTable(TableMigration(planSessions));
      }
      if (from < 11) {
        // Every row that exists before this migration was created by
        // createSessionLog/createAdHocActivity - the only two ways a real
        // log has ever been written - so all of them are "finished" the
        // instant they were created; backfill finishedAt to loggedAt rather
        // than leaving it null (which would now read as an abandoned draft
        // and vanish from Progress/History/Calendar/backup export).
        await m.addColumn(sessionLogs, sessionLogs.finishedAt);
        await customStatement(
          'UPDATE session_logs SET finished_at = logged_at',
        );
      }
      if (from < 12) {
        // A single imagePath becomes a comma-separated imagePaths list (up
        // to maxExerciseImages photos per exercise, see
        // lib/logic/exercise_images.dart) - carry every existing single
        // image forward as that exercise's one-element list. imagePath
        // itself is left in place but unused from here on (see its own
        // doc comment) rather than dropped, matching this migration's
        // usual "additive, no TableMigration needed" shape.
        await m.addColumn(exercises, exercises.imagePaths);
        await customStatement(
          'UPDATE exercises SET image_paths = image_path '
          'WHERE image_path IS NOT NULL',
        );
      }
      if (from < 13) {
        // Two unrelated additive columns for two separate features
        // (favorite exercises, superset/circuit grouping), combined into
        // one migration step since neither needs a TableMigration (no
        // nullability change, no drop) and both are trivial addColumns
        // that can't conflict with each other.
        await m.addColumn(exercises, exercises.isFavorite);
        await m.addColumn(planExercises, planExercises.supersetGroupId);
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
