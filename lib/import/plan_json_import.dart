import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../data/app_database.dart';
import '../data/daos/plan_dao.dart';
import '../logic/exercise_name_matching.dart';

/// Thrown for a plan JSON file that isn't usable at all - wrong/missing
/// schema_version, or missing structure. Unlike the spreadsheet importer,
/// there's no per-row preview here: a JSON plan export is produced by this
/// same app, so a structural problem means the file is the wrong kind of
/// file, not a typo a user needs to fix row-by-row.
class PlanJsonFormatException implements Exception {
  final String message;
  const PlanJsonFormatException(this.message);
  @override
  String toString() => message;
}

const _supportedSchemaVersion = 1;

/// Imports a single-plan JSON export (schema/plan.schema.json, produced by
/// [planToJson]) into the database, returning the new plan's id. [planId]
/// overrides the freshly-generated id - full backup restore uses this to
/// preserve the original plan id (needed to re-link session logs to the
/// right sessions), while an ordinary single-plan import always generates a
/// fresh one so importing the same file twice doesn't collide.
///
/// Exercise resolution, in order: (1) the embedded `exercise_id` if it
/// exists in this device's library, (2) an exact-after-normalization name
/// match, (3) otherwise create it as a custom exercise. Unlike the
/// spreadsheet importer this never asks the user to resolve a mismatch -
/// a JSON plan export is trusted, same-app data (typically moved between a
/// user's own devices), not an arbitrary external file with free-text
/// exercise names.
Future<String> importPlanJson(
  Map<String, dynamic> json,
  AppDatabase db, {
  String? planId,
}) async {
  if (json['schema_version'] != _supportedSchemaVersion) {
    throw PlanJsonFormatException(
      'Unsupported plan file version: ${json['schema_version']}.',
    );
  }
  final weeksJson = json['weeks'];
  final name = json['name'];
  if (weeksJson is! List || name is! String) {
    throw const PlanJsonFormatException('Not a valid plan file.');
  }

  final library = await db.exerciseDao.getAllExercises();
  final byId = {for (final e in library) e.id: e.id};
  final byNormalizedName = {
    for (final e in library) normalizeExerciseName(e.name): e.id,
  };

  Future<String> resolveExerciseId(String? rawId, String exerciseName) async {
    if (rawId != null && byId.containsKey(rawId)) return rawId;

    final normalized = normalizeExerciseName(exerciseName);
    final byName = byNormalizedName[normalized];
    if (byName != null) return byName;

    final newId = const Uuid().v4();
    await db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: newId,
        name: exerciseName,
        category: 'Custom',
        movementPattern: '',
        muscleGroups: '',
        equipment: '',
        difficulty: 'Beginner',
        measurementType: 'Weight x Reps',
        isCustom: const Value(true),
      ),
    );
    byNormalizedName[normalized] = newId;
    return newId;
  }

  final sessions = <PlanSessionInput>[];
  for (final weekJson in weeksJson) {
    final weekNumber = weekJson['week_number'] as int;
    final sessionsJson = weekJson['sessions'] as List;
    for (final sessionJson in sessionsJson) {
      final exercisesJson = sessionJson['exercises'] as List;
      final exerciseInputs = <PlanExerciseInput>[];
      for (final exerciseJson in exercisesJson) {
        final exerciseName = exerciseJson['exercise_name'] as String;
        exerciseInputs.add(
          PlanExerciseInput(
            order: exerciseJson['order'] as int,
            exerciseId: await resolveExerciseId(
              exerciseJson['exercise_id'] as String?,
              exerciseName,
            ),
            exerciseName: exerciseName,
            sets: exerciseJson['sets'] as int,
            reps: exerciseJson['reps'] as String,
            weightIntensity: exerciseJson['weight_intensity'] as String? ?? '',
            restSec: exerciseJson['rest_sec'] as int?,
            notes: exerciseJson['notes'] as String? ?? '',
            videoUrl: exerciseJson['video_url'] as String? ?? '',
          ),
        );
      }
      final assignedDateStr = sessionJson['assigned_date'] as String?;
      sessions.add(
        PlanSessionInput(
          weekNumber: weekNumber,
          day: sessionJson['day'] as String,
          sessionName: sessionJson['session_name'] as String,
          exercises: exerciseInputs,
          assignedDate: assignedDateStr == null
              ? null
              : DateTime.parse(assignedDateStr),
        ),
      );
    }
  }

  final createdAtStr = json['created_at'] as String?;
  final updatedAtStr = json['updated_at'] as String?;
  return db.planDao.createPlan(
    id: planId ?? const Uuid().v4(),
    name: name,
    notes: json['notes'] as String? ?? '',
    sessions: sessions,
    createdAt: createdAtStr == null ? null : DateTime.parse(createdAtStr),
    updatedAt: updatedAtStr == null ? null : DateTime.parse(updatedAtStr),
  );
}
