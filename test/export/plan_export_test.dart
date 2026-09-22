import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/export/plan_export.dart';
import 'package:training_app/import/plan_spreadsheet_parser.dart';

PlanSessionDetails _fakeSession({
  required int weekNumber,
  required String day,
  required String sessionName,
  required List<PlanExercise> exercises,
  List<DateTime> dates = const [],
}) {
  return PlanSessionDetails(
    session: PlanSession(
      id: weekNumber * 100 + day.hashCode % 100,
      planId: 'plan-1',
      weekNumber: weekNumber,
      day: day,
      sessionName: sessionName,
    ),
    exercises: exercises,
    dates: dates,
  );
}

PlanExercise _fakeExercise({
  required int order,
  required String exerciseName,
  String? exerciseId,
  int sets = 4,
  String reps = '8-10',
  String weightIntensity = '60kg',
  int? restSec = 90,
}) {
  return PlanExercise(
    id: order,
    sessionId: 0,
    order: order,
    exerciseId: exerciseId,
    exerciseName: exerciseName,
    sets: sets,
    reps: reps,
    weightIntensity: weightIntensity,
    restSec: restSec,
    notes: '',
    videoUrl: '',
    embeddingAllowed: false,
  );
}

void main() {
  final details = PlanDetails(
    plan: Plan(
      id: 'plan-1',
      name: 'My Plan',
      notes: '',
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 2),
      reportPreference: 'notAsked',
    ),
    sessions: [
      _fakeSession(
        weekNumber: 1,
        day: 'Mon',
        sessionName: 'Push Day',
        exercises: [
          _fakeExercise(order: 1, exerciseId: 'EX001', exerciseName: 'Bench Press'),
          _fakeExercise(order: 2, exerciseName: 'Overhead Press', weightIntensity: '35kg'),
        ],
        dates: [DateTime(2026, 9, 1), DateTime(2026, 9, 8)],
      ),
      _fakeSession(
        weekNumber: 1,
        day: 'Wed',
        sessionName: 'Pull Day',
        exercises: [
          _fakeExercise(order: 1, exerciseName: 'Deadlift', reps: '5', weightIntensity: '100kg'),
        ],
      ),
    ],
  );

  group('planToJson', () {
    test('matches schema/plan.schema.json shape', () {
      final json = planToJson(details);
      expect(json['schema_version'], 2);
      expect(json['id'], 'plan-1');
      expect(json['name'], 'My Plan');

      final weeks = json['weeks'] as List;
      expect(weeks, hasLength(1));
      final week = weeks.single as Map;
      expect(week['week_number'], 1);

      final sessions = week['sessions'] as List;
      expect(sessions, hasLength(2));
      final pushDay = sessions.first as Map;
      expect(pushDay['session_name'], 'Push Day');
      expect(pushDay['assigned_dates'], ['2026-09-01', '2026-09-08']);
      final exercises = pushDay['exercises'] as List;
      expect(exercises, hasLength(2));
      expect((exercises.first as Map)['exercise_id'], 'EX001');
      expect((exercises.last as Map)['exercise_id'], isNull);
    });
  });

  group('planToCsv', () {
    test('round-trips through the spreadsheet parser', () {
      final csv = planToCsv(details);
      final result = parsePlanCsv(csv);

      expect(result.hasErrors, isFalse);
      expect(result.rows, hasLength(3));

      final grouped = groupIntoSessions(result.rows);
      expect(grouped, hasLength(2));
      expect(grouped[0].sessionName, 'Push Day');
      expect(grouped[0].rows.map((r) => r.exerciseName), [
        'Bench Press',
        'Overhead Press',
      ]);
      expect(grouped[1].sessionName, 'Pull Day');
      expect(grouped[1].rows.single.weightIntensity, '100kg');
    });

    test('produces the canonical header row', () {
      final csv = planToCsv(details);
      final firstLine = csv.split('\r\n').first;
      expect(
        firstLine,
        'Week,Day,Session Name,Order,Exercise Name,Sets,Reps,Weight/Intensity,Rest (sec),Notes,Video URL,Embedding',
      );
    });
  });
}
