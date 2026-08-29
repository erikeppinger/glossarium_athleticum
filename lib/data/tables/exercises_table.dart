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

  /// Filename of a user-attached image, relative to the attachments
  /// directory (see lib/data/local_storage.dart) - not an absolute path,
  /// because the app's sandbox path changes across reinstalls and OS
  /// upgrades, which would silently break every stored absolute path.
  ///
  /// Deliberately user-supplied rather than bundled stock imagery: shipping
  /// ~38 scraped exercise photos would be a licensing problem for anyone
  /// publishing the app, and a user's own photo of their actual setup is
  /// more useful anyway. Null when no image has been attached.
  TextColumn get imagePath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
