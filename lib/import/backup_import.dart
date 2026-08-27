import 'package:drift/drift.dart' show Value;

import '../data/app_database.dart';
import '../data/daos/session_log_dao.dart';
import '../data/seed/exercise_seed_loader.dart';
import 'plan_json_import.dart';

class BackupJsonFormatException implements Exception {
  final String message;
  const BackupJsonFormatException(this.message);
  @override
  String toString() => message;
}

const _supportedSchemaVersion = 1;

ExercisesCompanion _exerciseFromJson(Map<String, dynamic> json) {
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
  );
}

/// Restores a full backup (schema/backup.schema.json, produced by
/// `buildBackupJson`). This is a full RESTORE, not a merge: it wipes all
/// existing data first, matching the exit criteria "a full encrypted backup
/// can be restored from scratch". The caller is expected to have already
/// decrypted the file (see lib/security/backup_encryption.dart) before
/// calling this - this function only handles the plaintext JSON shape.
Future<void> importBackupJson(
  Map<String, dynamic> json,
  AppDatabase db,
) async {
  if (json['schema_version'] != _supportedSchemaVersion) {
    throw BackupJsonFormatException(
      'Unsupported backup file version: ${json['schema_version']}.',
    );
  }
  final exercisesJson = json['exercises'];
  final plansJson = json['plans'];
  final sessionLogsJson = json['session_logs'] as List? ?? const [];
  if (exercisesJson is! List || plansJson is! List) {
    throw const BackupJsonFormatException('Not a valid backup file.');
  }

  await db.maintenanceDao.wipeAllData();
  await seedExerciseLibrary(db);

  for (final exerciseJson in exercisesJson) {
    await db.exerciseDao.upsertExercise(
      _exerciseFromJson(exerciseJson as Map<String, dynamic>),
    );
  }

  for (final planJson in plansJson) {
    final map = planJson as Map<String, dynamic>;
    // Preserve the original plan id so the session_logs below (matched by
    // plan_id + week/day/session_name) can find the sessions just created.
    await importPlanJson(map, db, planId: map['id'] as String);
  }

  for (final logJson in sessionLogsJson) {
    final map = logJson as Map<String, dynamic>;
    final session = await db.planDao.findSessionByNaturalKey(
      planId: map['plan_id'] as String,
      weekNumber: map['week_number'] as int,
      day: map['day'] as String,
      sessionName: map['session_name'] as String,
    );
    // The session this log belonged to no longer exists (e.g. the backup
    // was hand-edited, or a plan failed to import) - skip this one log
    // rather than aborting the entire restore over it.
    if (session == null) continue;

    final entries = (map['entries'] as List).map((entryJson) {
      final entry = entryJson as Map<String, dynamic>;
      return LoggedSetInput(
        exerciseId: entry['exercise_id'] as String,
        setNumber: entry['set_number'] as int,
        reps: entry['reps'] as int?,
        weight: (entry['weight'] as num?)?.toDouble(),
        durationSec: (entry['duration_sec'] as num?)?.toDouble(),
        distance: (entry['distance'] as num?)?.toDouble(),
        rpe: (entry['rpe'] as num?)?.toDouble(),
        isPr: entry['is_pr'] as bool? ?? false,
      );
    }).toList();

    await db.sessionLogDao.createSessionLog(
      id: map['id'] as String,
      planSessionId: session.id,
      loggedAt: DateTime.parse(map['logged_at'] as String),
      entries: entries,
    );
  }
}
