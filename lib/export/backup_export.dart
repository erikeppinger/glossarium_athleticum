import '../data/app_database.dart';
import '../data/daos/session_log_dao.dart';
import 'plan_export.dart';

const backupSchemaVersion = 1;

/// File extension used for encrypted full-backup exports (Phase 3/4). Kept
/// as a shared constant since both the Settings screen's manual export/
/// restore and Phase 4's incoming-share handler need to agree on it - the
/// latter uses it to tell an encrypted backup apart from a plain plan file.
const backupFileExtension = 'tabackup';

/// Custom (non-seed) exercise, in schema/exercise.schema.json shape.
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
    // The filename only - the image file itself is not part of the JSON
    // envelope. Restoring onto a different device leaves the reference
    // dangling, which AttachmentImage renders as a placeholder rather than
    // failing.
    if (exercise.imagePath != null) 'image_path': exercise.imagePath,
  };
}

/// One session log, in schema/backup.schema.json's "sessionLog" shape.
/// [planId]/[weekNumber]/[day]/[sessionName] are looked up separately since
/// the DB tables reference the specific PlanSessions row rather than
/// duplicating those as flat fields (see
/// lib/data/tables/session_logs_table.dart). All four are needed together:
/// plan_id+session_name alone is ambiguous when a session name repeats
/// across weeks (e.g. "Push Day" in both week 1 and week 2).
Map<String, dynamic> sessionLogToJson(
  SessionLogWithSets logWithSets, {
  required String planId,
  required int weekNumber,
  required String day,
  required String sessionName,
}) {
  return {
    'id': logWithSets.log.id,
    'plan_id': planId,
    'week_number': weekNumber,
    'day': day,
    'session_name': sessionName,
    'logged_at': logWithSets.log.loggedAt.toIso8601String(),
    'entries': [
      for (final set in logWithSets.sets)
        {
          'exercise_id': set.exerciseId,
          'set_number': set.setNumber,
          'reps': set.reps,
          'weight': set.weight,
          'duration_sec': set.durationSec,
          'distance': set.distance,
          'rpe': set.rpe,
          'is_pr': set.isPr,
        },
    ],
  };
}

/// Builds a full-app backup (schema/backup.schema.json) from the current
/// database state - every plan, every custom exercise, and all execution
/// history. Callers are expected to encrypt the resulting JSON (see
/// lib/security/backup_encryption.dart) before writing it to disk.
Future<Map<String, dynamic>> buildBackupJson(
  AppDatabase db, {
  String appVersion = '',
}) async {
  final customExercises = await db.exerciseDao.getCustomExercises();

  final plans = await db.planDao.getAllPlans();
  final planJsonList = <Map<String, dynamic>>[];
  for (final plan in plans) {
    final details = await db.planDao.getPlanDetails(plan.id);
    if (details != null) planJsonList.add(planToJson(details));
  }

  final logs = await db.sessionLogDao.getAllSessionLogsWithSets();
  final logJsonList = <Map<String, dynamic>>[];
  for (final logWithSets in logs) {
    final sessionDetails = await db.planDao.getSessionDetails(
      logWithSets.log.planSessionId,
    );
    if (sessionDetails == null) {
      continue; // the parent session was deleted; nothing to attach this log to
    }
    logJsonList.add(
      sessionLogToJson(
        logWithSets,
        planId: sessionDetails.session.planId,
        weekNumber: sessionDetails.session.weekNumber,
        day: sessionDetails.session.day,
        sessionName: sessionDetails.session.sessionName,
      ),
    );
  }

  final measurements = await db.bodyMeasurementDao.getAll();

  return {
    'schema_version': backupSchemaVersion,
    'exported_at': DateTime.now().toIso8601String(),
    'app_version': appVersion,
    'exercises': [for (final e in customExercises) exerciseToJson(e)],
    'plans': planJsonList,
    'session_logs': logJsonList,
    'body_measurements': [
      for (final m in measurements) bodyMeasurementToJson(m),
    ],
  };
}

Map<String, dynamic> bodyMeasurementToJson(BodyMeasurement m) {
  return {
    'id': m.id,
    'measured_at': m.measuredAt.toIso8601String(),
    if (m.weightKg != null) 'weight_kg': m.weightKg,
    if (m.bodyFatPercent != null) 'body_fat_percent': m.bodyFatPercent,
    if (m.chestCm != null) 'chest_cm': m.chestCm,
    if (m.waistCm != null) 'waist_cm': m.waistCm,
    if (m.hipsCm != null) 'hips_cm': m.hipsCm,
    if (m.thighCm != null) 'thigh_cm': m.thighCm,
    if (m.armCm != null) 'arm_cm': m.armCm,
    if (m.notes.isNotEmpty) 'notes': m.notes,
  };
}
