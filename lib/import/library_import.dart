import 'dart:io';

import '../data/app_database.dart';
import '../export/exercise_json.dart' show exerciseFromJson, restoreExerciseImage;
import '../export/library_export.dart' show librarySchemaVersion;

class LibraryJsonFormatException implements Exception {
  final String message;
  const LibraryJsonFormatException(this.message);
  @override
  String toString() => message;
}

/// Imports a standalone library export (produced by [buildLibraryJson]).
/// Upserts by id - matching exercises already on this device are updated in
/// place (same "trusted, same-app data" reasoning as the plan/backup
/// importers), everything else is added. Never touches plans, sessions, or
/// logs; a full-device restore is the only import that does that.
///
/// Returns the number of exercises imported.
Future<int> importLibraryJson(
  Map<String, dynamic> json,
  AppDatabase db, {
  Directory? attachmentsDirectory,
}) async {
  if (json['schema_version'] != librarySchemaVersion) {
    throw LibraryJsonFormatException(
      'Unsupported library file version: ${json['schema_version']}.',
    );
  }
  final exercisesJson = json['exercises'];
  if (exercisesJson is! List) {
    throw const LibraryJsonFormatException('Not a valid library file.');
  }

  // All-or-nothing, like the plan and backup importers: one damaged entry
  // rolls back the exercises already written from this file.
  try {
    await db.transaction(() async {
      for (final exerciseJson in exercisesJson) {
        final map = exerciseJson as Map<String, dynamic>;
        await db.exerciseDao.upsertExercise(exerciseFromJson(map));
        await restoreExerciseImage(map, directory: attachmentsDirectory);
      }
    });
  } catch (_) {
    throw const LibraryJsonFormatException(
      'This library file is damaged and could not be imported. '
      'Nothing was changed.',
    );
  }
  return exercisesJson.length;
}
