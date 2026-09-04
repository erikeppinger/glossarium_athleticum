import 'dart:io';

import '../data/app_database.dart';
import 'exercise_json.dart';

const librarySchemaVersion = 1;

/// File extension for a passphrase-encrypted standalone library export -
/// the library analogue of `plan_export.dart`'s `encryptedPlanFileExtension`
/// and `backup_export.dart`'s `backupFileExtension`.
const encryptedLibraryFileExtension = 'tlibrary';

/// Exports every custom exercise on this device, independent of any specific
/// plan - previously the *only* way to move "just my exercise library"
/// somewhere else was a full-device backup (which also drags along every
/// plan and logged session), or a single-plan export (which only carries
/// the custom exercises that one plan actually references). Neither covers
/// "I built up a library of custom exercises and want to hand just that to
/// someone, or back it up on its own."
Future<Map<String, dynamic>> buildLibraryJson(
  AppDatabase db, {
  Directory? attachmentsDirectory,
}) async {
  final customExercises = await db.exerciseDao.getCustomExercises();
  final exerciseJsonList = <Map<String, dynamic>>[];
  for (final e in customExercises) {
    exerciseJsonList.add(
      await exerciseToJsonWithImage(e, directory: attachmentsDirectory),
    );
  }
  return {
    'schema_version': librarySchemaVersion,
    'exported_at': DateTime.now().toIso8601String(),
    'exercises': exerciseJsonList,
  };
}
