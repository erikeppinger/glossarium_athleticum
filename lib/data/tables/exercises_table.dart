import 'package:drift/drift.dart';

/// One entry in the local exercise library. Mirrors schema/exercise.schema.json
/// and seed-data/strongman_exercise_database.csv.
class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get movementPattern => text()();

  /// Comma-separated (e.g. "Shoulders,Upper Back"); split at the call site.
  TextColumn get muscleGroups => text()();

  TextColumn get equipment => text()();
  TextColumn get difficulty => text()();

  /// One of "Weight x Reps", "Time", "Distance" - drives session-logging inputs.
  TextColumn get measurementType => text()();

  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get safetyNotes => text().withDefault(const Constant(''))();
  TextColumn get videoReference => text().withDefault(const Constant(''))();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
