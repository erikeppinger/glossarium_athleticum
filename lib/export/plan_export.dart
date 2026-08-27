import 'package:csv/csv.dart';

import '../data/daos/plan_dao.dart';

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
    'schema_version': 1,
    'id': details.plan.id,
    'name': details.plan.name,
    'created_at': details.plan.createdAt.toIso8601String(),
    'updated_at': details.plan.updatedAt.toIso8601String(),
    'notes': details.plan.notes,
    'weeks': [
      for (final weekNumber in sortedWeekNumbers)
        {
          'week_number': weekNumber,
          'sessions': [
            for (final session in weeks[weekNumber]!)
              {
                'day': session.session.day,
                'session_name': session.session.sessionName,
                'assigned_date': session.session.assignedDate
                    ?.toIso8601String()
                    .split('T')
                    .first,
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
