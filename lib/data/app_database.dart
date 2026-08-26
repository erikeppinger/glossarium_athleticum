import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'daos/exercise_dao.dart';
import 'daos/plan_dao.dart';
import 'tables/exercises_table.dart';
import 'tables/plans_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Exercises, Plans, PlanSessions, PlanExercises],
  daos: [ExerciseDao, PlanDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'training_app',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
