import 'dart:io';

import 'package:csv/csv.dart';

import '../data/app_database.dart';
import '../data/daos/plan_dao.dart';
import 'exercise_json.dart';

/// File extension for a passphrase-encrypted single-plan export - the plan
/// analogue of `backup_export.dart`'s `backupFileExtension`. A plan file can
/// now embed a custom exercise's photo (see [planToJsonWithImages]), so
/// there's real reason to encrypt it before sending it somewhere less
/// trusted than a full-device backup already gets.
const encryptedPlanFileExtension = 'tplan';

/// Converts a loaded plan into the shape schema/plan.schema.json describes -
/// the single-plan export/import format (Phase 3). Sessions are grouped by
/// week and sorted the same way [PlanDao.getPlanDetails] already orders them.
Map<String, dynamic> planToJson(PlanDetails details) {
  final weeks = <int, List<PlanSessionDetails>>{};
  for (final session in details.sessions) {
    weeks.putIfAbsent(session.session.weekNumber, () => []).add(session);
  }
  final sortedWeekNumbers = weeks.keys.toList()..sort();

  return {
    // Bumped 1 -> 2: 'assigned_date' (one nullable date) became
    // 'assigned_dates' (an array) so a session can be scheduled on several
    // dates - see plan_json_import.dart's importPlanJson for the
    // backward-compatible reader that still accepts the old singular field.
    'schema_version': 2,
    'id': details.plan.id,
    'name': details.plan.name,
    'created_at': details.plan.createdAt.toIso8601String(),
    'updated_at': details.plan.updatedAt.toIso8601String(),
    'notes': details.plan.notes,
    if (details.plan.createdBy != null) 'created_by': details.plan.createdBy,
    'weeks': [
      for (final weekNumber in sortedWeekNumbers)
        {
          'week_number': weekNumber,
          'sessions': [
            for (final session in weeks[weekNumber]!)
              {
                'day': session.session.day,
                'session_name': session.session.sessionName,
                'assigned_dates': [
                  for (final date in session.dates)
                    date.toIso8601String().split('T').first,
                ],
                'exercises': [
                  for (final exercise in session.exercises)
                    {
                      'order': exercise.order,
                      'exercise_id': exercise.exerciseId,
                      'exercise_name': exercise.exerciseName,
                      'sets': exercise.sets,
                      'reps': exercise.reps,
                      'weight_intensity': exercise.weightIntensity,
                      'rest_sec': exercise.restSec,
                      'notes': exercise.notes,
                      'video_url': exercise.videoUrl,
                    },
                ],
              },
          ],
        },
    ],
  };
}

/// [planToJson] plus full definitions (including image bytes) for every
/// *custom* exercise this plan references - a plain single-plan export only
/// ever carried an exercise's id/name, so a plan built around a custom
/// exercise with a photo silently lost that exercise's full detail and image
/// when imported on a device that didn't already have it. Seed-library
/// exercises are never embedded: every device already has them, and they're
/// reseeded on launch regardless.
Future<Map<String, dynamic>> planToJsonWithImages(
  PlanDetails details,
  AppDatabase db, {
  Directory? attachmentsDirectory,
}) async {
  final json = planToJson(details);

  final referencedIds = <String>{
    for (final session in details.sessions)
      for (final exercise in session.exercises)
        if (exercise.exerciseId != null) exercise.exerciseId!,
  };
  if (referencedIds.isEmpty) return json;

  final customExercises = (await db.exerciseDao.getCustomExercises())
      .where((e) => referencedIds.contains(e.id));

  final exerciseJsonList = <Map<String, dynamic>>[];
  for (final e in customExercises) {
    exerciseJsonList.add(
      await exerciseToJsonWithImage(e, directory: attachmentsDirectory),
    );
  }
  if (exerciseJsonList.isEmpty) return json;

  return {...json, 'exercises': exerciseJsonList};
}

/// The header row, in the canonical column order - shared with the plan
/// spreadsheet importer so the two stay convertible.
const planCsvHeader = [
  'Week',
  'Day',
  'Session Name',
  'Order',
  'Exercise Name',
  'Sets',
  'Reps',
  'Weight/Intensity',
  'Rest (sec)',
  'Notes',
  'Video URL',
];

/// Exports a plan back to the flat spreadsheet template shape (Phase 1/3) -
/// the exact inverse of [parsePlanCsv]/[groupIntoSessions], so a plan can be
/// tweaked in Excel/Sheets and re-imported. In-app media (Phase 4+) can't
/// round-trip through a spreadsheet; only the Video URL/Notes text fields do.
String planToCsv(PlanDetails details) {
  final rows = <List<dynamic>>[planCsvHeader];
  final sortedSessions = [...details.sessions]
    ..sort((a, b) => a.session.weekNumber.compareTo(b.session.weekNumber));

  for (final session in sortedSessions) {
    for (final exercise in session.exercises) {
      rows.add([
        session.session.weekNumber,
        session.session.day,
        session.session.sessionName,
        exercise.order,
        exercise.exerciseName,
        exercise.sets,
        exercise.reps,
        exercise.weightIntensity,
        exercise.restSec ?? '',
        exercise.notes,
        exercise.videoUrl,
      ]);
    }
  }

  return Csv(lineDelimiter: '\r\n').encode(rows);
}
