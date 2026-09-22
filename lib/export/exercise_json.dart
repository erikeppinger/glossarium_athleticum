import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;

import '../data/app_database.dart';
import '../data/local_storage.dart';
import '../logic/exercise_images.dart';

/// Custom (non-seed) exercise, in schema/exercise.schema.json shape. Shared
/// by both the full-device backup (every custom exercise) and a single-plan
/// export (only the ones that plan actually references) - kept in its own
/// file so both `backup_export.dart` and `plan_export.dart` can depend on it
/// without importing each other.
Map<String, dynamic> exerciseToJson(Exercise exercise) {
  return {
    'id': exercise.id,
    'name': exercise.name,
    'category': exercise.category,
    'movement_pattern': exercise.movementPattern,
    'muscle_groups': exercise.muscleGroups
        .split(',')
        .map((g) => g.trim())
        .where((g) => g.isNotEmpty)
        .toList(),
    'equipment': exercise.equipment,
    'difficulty': exercise.difficulty,
    'measurement_type': exercise.measurementType,
    'description': exercise.description,
    'safety_notes': exercise.safetyNotes,
    'video_reference': exercise.videoReference,
    'embedding_allowed': exercise.embeddingAllowed,
    'is_custom': exercise.isCustom,
    // Attribution was previously dropped by backup/restore, so a restored
    // library lost track of which plan an exercise came from and who wrote it.
    if (exercise.sourcePlanName != null)
      'source_plan_name': exercise.sourcePlanName,
    if (exercise.author != null) 'author': exercise.author,
    // 'image_path' (singular) is kept alongside the new list purely so a
    // file exported by an older version of this app - or read by one, since
    // this key predates 'image_paths' - still finds a photo, not because
    // anything here still treats it as the source of truth.
    if (exercise.imagePath != null) 'image_path': exercise.imagePath,
    if (parseImagePaths(exercise.imagePaths).isNotEmpty)
      'image_paths': parseImagePaths(exercise.imagePaths),
  };
}

/// The inverse of [exerciseToJson] - reads back one entry from any of the
/// three places this shape is produced (full backup, single-plan export's
/// embedded custom exercises, standalone library export). Kept here as the
/// one shared definition rather than duplicated in each importer, after
/// three near-identical copies had drifted into existence across
/// `backup_import.dart` and `plan_json_import.dart`.
ExercisesCompanion exerciseFromJson(Map<String, dynamic> json) {
  final muscleGroups = (json['muscle_groups'] as List)
      .cast<String>()
      .join(', ');
  return ExercisesCompanion.insert(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String,
    movementPattern: json['movement_pattern'] as String,
    muscleGroups: muscleGroups,
    equipment: json['equipment'] as String,
    difficulty: json['difficulty'] as String,
    measurementType: json['measurement_type'] as String,
    description: Value(json['description'] as String? ?? ''),
    safetyNotes: Value(json['safety_notes'] as String? ?? ''),
    videoReference: Value(json['video_reference'] as String? ?? ''),
    // Absent in a file exported before this field existed - false (never
    // implicitly on) is the correct default, matching the schema column's
    // own default and parseEmbeddingFlag's "unrecognized means off" rule.
    embeddingAllowed: Value(json['embedding_allowed'] as bool? ?? false),
    isCustom: Value(json['is_custom'] as bool? ?? true),
    // Absent in files produced before these fields existed - null is the
    // correct "not recorded" value, so no special-casing is needed.
    sourcePlanName: Value(json['source_plan_name'] as String?),
    author: Value(json['author'] as String?),
    imagePath: Value(json['image_path'] as String?),
    // Prefer the current list field; fall back to the older single
    // 'image_path' (as a one-element list) for a file exported before
    // multi-photo support existed.
    imagePaths: Value(
      joinImagePaths(
        (json['image_paths'] as List?)?.cast<String>() ??
            (json['image_path'] != null
                ? [json['image_path'] as String]
                : const []),
      ),
    ),
  );
}

/// [exerciseToJson] plus the image's actual bytes (base64), so an exported
/// exercise's photo survives being restored onto a different device -
/// `image_path` alone previously left the reference dangling after a
/// restore, since the image file itself was never part of the JSON. Missing
/// on disk (e.g. already lost) is not an error - the export just omits the
/// bytes and `image_path` renders as a placeholder on restore, same as
/// before this existed.
/// [directory] is injectable for testing, same as every function in
/// `local_storage.dart` - real callers omit it and get the actual platform
/// attachments directory.
Future<Map<String, dynamic>> exerciseToJsonWithImage(
  Exercise exercise, {
  Directory? directory,
}) async {
  final json = exerciseToJson(exercise);
  final paths = parseImagePaths(exercise.imagePaths);
  if (paths.isEmpty) return json;

  // Keyed by filename rather than a parallel-indexed list, so restoring
  // never has to assume the two lists stayed in lockstep - and a file
  // that's gone missing on disk is just silently absent from the map,
  // exactly like the single-image version's own "missing isn't an error"
  // behaviour.
  final imagesBase64 = <String, String>{};
  for (final path in paths) {
    final bytes = await readAttachmentBytes(path, directory: directory);
    if (bytes != null) imagesBase64[path] = base64Encode(bytes);
  }
  if (imagesBase64.isEmpty) return json;
  return {...json, 'images_data_base64': imagesBase64};
}

/// Writes back the images embedded in an [exerciseToJsonWithImage]-shaped
/// entry, if present. A no-op when the entry has no `images_data_base64` -
/// either it never had any images, or it came from a backup/plan export
/// taken before multi-photo support existed (in which case `image_path`/
/// `image_paths` alone still restore, just pointing at files that aren't
/// there, rendered as placeholders). Also handles the older single-image
/// `image_data_base64` shape, for a file exported before this existed.
Future<void> restoreExerciseImage(
  Map<String, dynamic> json, {
  Directory? directory,
}) async {
  final imagesBase64 = json['images_data_base64'] as Map<String, dynamic>?;
  if (imagesBase64 != null) {
    for (final entry in imagesBase64.entries) {
      await saveAttachmentBytes(
        base64Decode(entry.value as String),
        entry.key,
        directory: directory,
      );
    }
    return;
  }

  final imagePath = json['image_path'] as String?;
  final dataBase64 = json['image_data_base64'] as String?;
  if (imagePath == null || dataBase64 == null) return;
  await saveAttachmentBytes(
    base64Decode(dataBase64),
    imagePath,
    directory: directory,
  );
}
