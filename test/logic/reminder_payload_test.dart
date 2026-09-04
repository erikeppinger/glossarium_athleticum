import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/logic/reminder_payload.dart';

void main() {
  group('parseReminderPayload', () {
    test('null and empty are unparseable', () {
      expect(parseReminderPayload(null), isNull);
      expect(parseReminderPayload(''), isNull);
    });

    test('parses the weekly digest payload', () {
      expect(parseReminderPayload(weeklyDigestPayload), isA<WeeklyDigestPayload>());
    });

    test('parses a workout payload back to its session id', () {
      final payload = parseReminderPayload(buildWorkoutReminderPayload(42));
      expect(payload, isA<WorkoutReminderPayload>());
      expect((payload as WorkoutReminderPayload).planSessionId, 42);
    });

    test('an unparseable trailing id on a workout payload is unparseable', () {
      expect(parseReminderPayload('workout:not-a-number'), isNull);
    });

    test('parses a plan report payload back to its plan id', () {
      final payload = parseReminderPayload(buildPlanReportPayload('plan-1'));
      expect(payload, isA<PlanReportPayload>());
      expect((payload as PlanReportPayload).planId, 'plan-1');
    });

    test('an empty plan id on a plan report payload is unparseable', () {
      expect(parseReminderPayload('plan_report:'), isNull);
    });

    test('an unrecognized format is unparseable', () {
      expect(parseReminderPayload('something_else'), isNull);
    });
  });
}
