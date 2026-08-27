import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/exercises_table.dart';
import '../tables/plans_table.dart';
import '../tables/session_logs_table.dart';

part 'maintenance_dao.g.dart';

/// Cross-cutting database operations that don't belong to one feature -
/// currently just the "delete all data" wipe (Phase 3).
@DriftAccessor(
  tables: [Exercises, Plans, PlanSessions, PlanExercises, SessionLogs, LoggedSets],
)
class MaintenanceDao extends DatabaseAccessor<AppDatabase>
    with _$MaintenanceDaoMixin {
  MaintenanceDao(super.db);

  /// Deletes every row from every table, children before parents (so this
  /// works regardless of whether SQLite's foreign_keys pragma happens to be
  /// on). Does not re-seed the exercise library - callers that want a
  /// "fresh install" feel should call [seedExerciseLibrary] afterward.
  Future<void> wipeAllData() {
    return transaction(() async {
      await delete(loggedSets).go();
      await delete(sessionLogs).go();
      await delete(planExercises).go();
      await delete(planSessions).go();
      await delete(plans).go();
      await delete(exercises).go();
    });
  }
}
