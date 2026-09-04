import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;

import '../data/app_database.dart';
import '../data/local_storage.dart';

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
    'is_custom': exercise.isCustom,
    // Attribution was previously dropped by backup/restore, so a restored
    // library lost track of which plan an exercise came from and who wrote it.
    if (exercise.sourcePlanName != null)
      'source_plan_name': exercise.sourcePlanName,
    if (exercise.author != null) 'author': exercise.author,
    if (exercise.imagePath != null) 'image_path': exercise.imagePath,
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
    isCustom: Value(json['is_custom'] as bool? ?? true),
    // Absent in files produced before these fields existed - null is the
    // correct "not recorded" value, so no special-casing is needed.
    sourcePlanName: Value(json['source_plan_name'] as String?),
    author: Value(json['author'] as String?),
    imagePath: Value(json['image_path'] as String?),
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
  final imagePath = exercise.imagePath;
  if (imagePath == null) return json;

  final bytes = await readAttachmentBytes(imagePath, directory: directory);
  if (bytes == null) return json;

  return {...json, 'image_data_base64': base64Encode(bytes)};
}

/// Writes back the image embedded in an [exerciseToJsonWithImage]-shaped
/// entry, if present. A no-op when the entry has no `image_data_base64` -
/// either it never had an image, or it came from a backup/plan export taken
/// before this existed (in which case `image_path` alone still restores,
/// just pointing at a file that isn't there, rendered as a placeholder).
Future<void> restoreExerciseImage(
  Map<String, dynamic> json, {
  Directory? directory,
}) async {
  final imagePath = json['image_path'] as String?;
  final dataBase64 = json['image_data_base64'] as String?;
  if (imagePath == null || dataBase64 == null) return;
  await saveAttachmentBytes(
    base64Decode(dataBase64),
    imagePath,
    directory: directory,
  );
}
