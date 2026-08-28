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

  /// Name of the plan whose import/creation flow created this exercise, if
  /// any - a snapshot (not a foreign key) so it survives that plan being
  /// deleted later. Null for seed-library exercises and ones created
  /// standalone via `create_exercise_screen.dart`.
  TextColumn get sourcePlanName => text().nullable()();

  /// Free-text creator/author name (e.g. a coach's name), optionally set
  /// when creating a custom exercise. Null if not provided.
  TextColumn get author => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
