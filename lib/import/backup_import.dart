import 'dart:io';

import '../data/app_database.dart';
import '../data/daos/session_log_dao.dart';
import '../data/seed/exercise_seed_loader.dart';
import '../export/exercise_json.dart' show exerciseFromJson, restoreExerciseImage;
import 'plan_json_import.dart';

class BackupJsonFormatException implements Exception {
  final String message;
  const BackupJsonFormatException(this.message);
  @override
  String toString() => message;
}

const _supportedSchemaVersion = 1;

/// Restores a full backup (schema/backup.schema.json, produced by
/// `buildBackupJson`). This is a full RESTORE, not a merge: it wipes all
/// existing data first, matching the exit criteria "a full encrypted backup
/// can be restored from scratch". The caller is expected to have already
/// decrypted the file (see lib/security/backup_encryption.dart) before
/// calling this - this function only handles the plaintext JSON shape.
Future<void> importBackupJson(
  Map<String, dynamic> json,
  AppDatabase db, {
  Directory? attachmentsDirectory,
}) async {
  if (json['schema_version'] != _supportedSchemaVersion) {
    throw BackupJsonFormatException(
      'Unsupported backup file version: ${json['schema_version']}.',
    );
  }
  final exercisesJson = json['exercises'];
  final plansJson = json['plans'];
  final sessionLogsJson = json['session_logs'] as List? ?? const [];
  // Absent in backups taken before body measurements existed - treated as
  // "none recorded" rather than a malformed file.
  final measurementsJson = json['body_measurements'] as List? ?? const [];
  if (exercisesJson is! List || plansJson is! List) {
    throw const BackupJsonFormatException('Not a valid backup file.');
  }

  await db.maintenanceDao.wipeAllData();
  await seedExerciseLibrary(db);

  for (final exerciseJson in exercisesJson) {
    final map = exerciseJson as Map<String, dynamic>;
    await db.exerciseDao.upsertExercise(exerciseFromJson(map));
    await restoreExerciseImage(map, directory: attachmentsDirectory);
  }

  for (final planJson in plansJson) {
    final map = planJson as Map<String, dynamic>;
    // Preserve the original plan id so the session_logs below (matched by
    // plan_id + week/day/session_name) can find the sessions just created.
    await importPlanJson(
      map,
      db,
      planId: map['id'] as String,
      attachmentsDirectory: attachmentsDirectory,
    );
  }

  for (final logJson in sessionLogsJson) {
    final map = logJson as Map<String, dynamic>;

    // An ad-hoc activity (see activityLogToJson) has no plan session to
    // relink to at all - restore it directly rather than going through the
    // natural-key lookup below, which only makes sense for a plan-tied log.
    final activityName = map['activity_name'] as String?;
    if (activityName != null) {
      await db.sessionLogDao.createAdHocActivity(
        id: map['id'] as String,
        loggedAt: DateTime.parse(map['logged_at'] as String),
        activityName: activityName,
        durationSec: (map['duration_sec'] as num?)?.toDouble(),
        distance: (map['distance'] as num?)?.toDouble(),
        notes: map['notes'] as String?,
      );
      continue;
    }

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
      notes: map['notes'] as String?,
    );
  }

  for (final measurementJson in measurementsJson) {
    final map = measurementJson as Map<String, dynamic>;
    await db.bodyMeasurementDao.upsert(
      id: map['id'] as String,
      measuredAt: DateTime.parse(map['measured_at'] as String),
      weightKg: (map['weight_kg'] as num?)?.toDouble(),
      bodyFatPercent: (map['body_fat_percent'] as num?)?.toDouble(),
      chestCm: (map['chest_cm'] as num?)?.toDouble(),
      waistCm: (map['waist_cm'] as num?)?.toDouble(),
      hipsCm: (map['hips_cm'] as num?)?.toDouble(),
      thighCm: (map['thigh_cm'] as num?)?.toDouble(),
      armCm: (map['arm_cm'] as num?)?.toDouble(),
      notes: map['notes'] as String? ?? '',
    );
  }
}
