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

  /// Deprecated - superseded by [imagePaths] below (a single exercise can now
  /// have up to `maxExerciseImages` photos, see lib/logic/exercise_images.dart).
  /// Kept only so a very old exported plan/backup JSON's single `image_path`
  /// field still has somewhere to land on import; every current read/write
  /// site uses [imagePaths] instead. Never written by anything but the
  /// schema 11->12 migration's one-time backfill.
  TextColumn get imagePath => text().nullable()();

  /// Comma-separated filenames (relative to the attachments directory, see
  /// lib/data/local_storage.dart - not absolute paths, because the app's
  /// sandbox path changes across reinstalls and OS upgrades) of up to
  /// `maxExerciseImages` user-attached photos, in display order. Null/empty
  /// when none are attached.
  ///
  /// Deliberately user-supplied rather than bundled stock imagery: shipping
  /// scraped exercise photos would be a licensing problem for anyone
  /// publishing the app, and a user's own photos of their actual setup are
  /// more useful anyway.
  TextColumn get imagePaths => text().nullable()();

  /// Starred by the user for quick access via the "Favorites only" filter
  /// chip on the Exercise Library screen - purely a personal-device
  /// convenience, not part of any exported plan/backup JSON.
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  /// Opt-in to show [videoReference] as an embedded player (YouTube only -
  /// see lib/logic/video_embedding.dart) instead of just a tappable link.
  /// Defaults to false: embedding is never turned on implicitly, including
  /// on import, since whoever adds a video is asserting they have the right
  /// to embed it - see docs/DISCLAIMER.md's "Embedded video" section. This
  /// travels with the exercise through export/import/backup exactly like
  /// [videoReference] itself, so a shared library preserves the author's
  /// own choice rather than resetting it.
  BoolColumn get embeddingAllowed =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
