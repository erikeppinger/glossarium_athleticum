import 'dart:io';

import '../data/app_database.dart';
import '../data/daos/session_log_dao.dart';
import 'exercise_json.dart';
import 'plan_export.dart';

export 'exercise_json.dart';

const backupSchemaVersion = 1;

/// File extension used for encrypted full-backup exports (Phase 3/4). Kept
/// as a shared constant since both the Settings screen's manual export/
/// restore and Phase 4's incoming-share handler need to agree on it - the
/// latter uses it to tell an encrypted backup apart from a plain plan file.
const backupFileExtension = 'tabackup';

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
    if (logWithSets.log.notes != null) 'notes': logWithSets.log.notes,
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
          if (set.notes != null) 'notes': set.notes,
        },
    ],
    if (logWithSets.skipped.isNotEmpty)
      'skipped_exercises': [
        for (final s in logWithSets.skipped)
          {
            'exercise_id': s.exerciseId,
            'exercise_name': s.exerciseName,
            'prescribed_sets': s.prescribedSets,
            'prescribed_reps': s.prescribedReps,
            'prescribed_weight_intensity': s.prescribedWeightIntensity,
            if (s.prescribedRestSec != null)
              'prescribed_rest_sec': s.prescribedRestSec,
            if (s.reason != null) 'reason': s.reason,
            if (s.replacedByExerciseId != null)
              'replaced_by_exercise_id': s.replacedByExerciseId,
            if (s.replacedByExerciseName != null)
              'replaced_by_exercise_name': s.replacedByExerciseName,
            'queued_for_next_session': s.queuedForNextSession,
            if (s.dismissedAt != null)
              'dismissed_at': s.dismissedAt!.toIso8601String(),
          },
      ],
  };
}

/// An ad-hoc activity (see `lib/data/tables/session_logs_table.dart`), in
/// schema/backup.schema.json's "activityLog" shape - deliberately a
/// different, flatter shape than [sessionLogToJson]'s: there's no plan
/// session to key back onto, so `plan_id`/`week_number`/`day`/`session_name`
/// are simply absent rather than null-filled. The importer tells the two
/// apart by whether `activity_name` is present.
Map<String, dynamic> activityLogToJson(SessionLog log) {
  return {
    'id': log.id,
    'activity_name': log.activityName,
    'logged_at': log.loggedAt.toIso8601String(),
    if (log.durationSec != null) 'duration_sec': log.durationSec,
    if (log.distance != null) 'distance': log.distance,
    if (log.notes != null) 'notes': log.notes,
  };
}

/// Builds a full-app backup (schema/backup.schema.json) from the current
/// database state - every plan, every custom exercise, and all execution
/// history. Callers are expected to encrypt the resulting JSON (see
/// lib/security/backup_encryption.dart) before writing it to disk.
Future<Map<String, dynamic>> buildBackupJson(
  AppDatabase db, {
  String appVersion = '',
  Directory? attachmentsDirectory,
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
    final planSessionId = logWithSets.log.planSessionId;
    if (planSessionId == null) {
      logJsonList.add(activityLogToJson(logWithSets.log));
      continue;
    }
    final sessionDetails = await db.planDao.getSessionDetails(planSessionId);
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

  final exerciseJsonList = <Map<String, dynamic>>[];
  for (final e in customExercises) {
    exerciseJsonList.add(
      await exerciseToJsonWithImage(e, directory: attachmentsDirectory),
    );
  }

  return {
    'schema_version': backupSchemaVersion,
    'exported_at': DateTime.now().toIso8601String(),
    'app_version': appVersion,
    'exercises': exerciseJsonList,
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
