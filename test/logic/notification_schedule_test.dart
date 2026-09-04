import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/logic/notification_schedule.dart';

void main() {
  ReminderSession session(int id, DateTime date) => ReminderSession(
    planSessionId: id,
    sessionName: 'Block 1 - Legs',
    planName: 'Nine-Block Strength Program',
    date: date,
  );

  group('buildWorkoutReminders', () {
    test('builds one reminder per future session at the chosen time', () {
      final reminders = buildWorkoutReminders(
        sessions: [
          session(7, DateTime(2026, 8, 30)),
          session(9, DateTime(2026, 9, 1)),
        ],
        reminderTimeOfDayMinutes: 8 * 60, // 08:00
        now: DateTime(2026, 8, 28, 12),
      );

      expect(reminders, hasLength(2));
      expect(reminders[0].when, DateTime(2026, 8, 30, 8));
      expect(reminders[1].when, DateTime(2026, 9, 1, 8));
      expect(reminders[0].title, contains('Block 1 - Legs'));
      expect(reminders[0].body, 'Nine-Block Strength Program');
    });

    test('skips sessions whose reminder moment has already passed', () {
      final reminders = buildWorkoutReminders(
        sessions: [
          session(1, DateTime(2026, 8, 27)), // yesterday
          session(2, DateTime(2026, 8, 28)), // today, but 08:00 already passed
          session(3, DateTime(2026, 8, 29)), // tomorrow
        ],
        reminderTimeOfDayMinutes: 8 * 60,
        now: DateTime(2026, 8, 28, 12),
      );

      expect(reminders.map((r) => r.id), [
        workoutReminderIdFor(3, DateTime(2026, 8, 29)),
      ]);
    });

    // Regression: a session scheduled on several dates used to collide on
    // one shared id (a pure function of planSessionId alone), silently
    // overwriting one date's pending reminder with the other's.
    test(
      'the same session scheduled on two different dates gets two distinct ids',
      () {
        final reminders = buildWorkoutReminders(
          sessions: [
            session(5, DateTime(2026, 8, 29)),
            session(5, DateTime(2026, 9, 5)),
          ],
          reminderTimeOfDayMinutes: 8 * 60,
          now: DateTime(2026, 8, 28, 12),
        );

        expect(reminders, hasLength(2));
        expect(reminders[0].id, isNot(reminders[1].id));
      },
    );

    test('keeps a same-day session whose reminder time is still ahead', () {
      final reminders = buildWorkoutReminders(
        sessions: [session(4, DateTime(2026, 8, 28))],
        reminderTimeOfDayMinutes: 18 * 60, // 18:00
        now: DateTime(2026, 8, 28, 12),
      );

      expect(reminders, hasLength(1));
      expect(reminders.single.when, DateTime(2026, 8, 28, 18));
    });

    test('ids are namespaced away from the weekly digest id', () {
      final reminders = buildWorkoutReminders(
        sessions: [session(1, DateTime(2026, 9, 1))],
        reminderTimeOfDayMinutes: 8 * 60,
        now: DateTime(2026, 8, 28),
      );
      expect(reminders.single.id, isNot(weeklyDigestNotificationId));
    });
  });

  group('buildWeeklyDigestReminder', () {
    test('picks the upcoming occurrence of the chosen weekday', () {
      // Friday 2026-08-28 -> next Monday is 2026-08-31.
      final reminder = buildWeeklyDigestReminder(
        digestWeekday: DateTime.monday,
        reminderTimeOfDayMinutes: 9 * 60,
        now: DateTime(2026, 8, 28, 12),
        sessionsPlannedThisWeek: 3,
      );

      expect(reminder.when, DateTime(2026, 8, 31, 9));
      expect(reminder.body, contains('3 sessions'));
    });

    test('rolls to next week if today is the day but the time has passed', () {
      // Monday 2026-08-31, 12:00 - 09:00 already gone.
      final reminder = buildWeeklyDigestReminder(
        digestWeekday: DateTime.monday,
        reminderTimeOfDayMinutes: 9 * 60,
        now: DateTime(2026, 8, 31, 12),
        sessionsPlannedThisWeek: 1,
      );

      expect(reminder.when, DateTime(2026, 9, 7, 9));
    });

    test('stays today if the time is still ahead', () {
      final reminder = buildWeeklyDigestReminder(
        digestWeekday: DateTime.monday,
        reminderTimeOfDayMinutes: 18 * 60,
        now: DateTime(2026, 8, 31, 12),
        sessionsPlannedThisWeek: 2,
      );

      expect(reminder.when, DateTime(2026, 8, 31, 18));
    });

    test('singular/empty wording', () {
      expect(
        buildWeeklyDigestReminder(
          digestWeekday: DateTime.monday,
          reminderTimeOfDayMinutes: 9 * 60,
          now: DateTime(2026, 8, 28),
          sessionsPlannedThisWeek: 1,
        ).body,
        contains('1 session planned'),
      );
      expect(
        buildWeeklyDigestReminder(
          digestWeekday: DateTime.monday,
          reminderTimeOfDayMinutes: 9 * 60,
          now: DateTime(2026, 8, 28),
          sessionsPlannedThisWeek: 0,
        ).body,
        contains('No sessions'),
      );
    });
  });

  group('buildPlanReportReminder', () {
    test('fires exactly frequencyDays after the anchor, same time of day', () {
      final reminder = buildPlanReportReminder(
        planId: 'plan-1',
        planName: 'My Plan',
        anchor: DateTime(2026, 8, 1, 14, 30),
        frequencyDays: 7,
        reminderTimeOfDayMinutes: 9 * 60,
        now: DateTime(2026, 8, 1, 15),
      );
      expect(reminder.when, DateTime(2026, 8, 8, 9));
    });

    test('steps forward by whole cycles when the anchor is long past', () {
      // Anchor was 20 days ago on a 7-day cadence - the next occurrence
      // should be the first one still in the future, not day 7 or day 14
      // (both already passed).
      final reminder = buildPlanReportReminder(
        planId: 'plan-1',
        planName: 'My Plan',
        anchor: DateTime(2026, 8, 1, 9),
        frequencyDays: 7,
        reminderTimeOfDayMinutes: 9 * 60,
        now: DateTime(2026, 8, 21, 12),
      );
      expect(reminder.when.isAfter(DateTime(2026, 8, 21, 12)), isTrue);
      expect(reminder.when, DateTime(2026, 8, 22, 9));
    });

    test(
      'opting in earlier the same day than the reminder time fires that '
      'same day, not a full cycle later',
      () {
        // Opted in at 07:00 for an 08:00 reminder - the first occurrence
        // should be 08:00 *today*, an hour away, not next week's 08:00.
        final reminder = buildPlanReportReminder(
          planId: 'plan-1',
          planName: 'My Plan',
          anchor: DateTime(2026, 8, 1, 7),
          frequencyDays: 7,
          reminderTimeOfDayMinutes: 8 * 60,
          now: DateTime(2026, 8, 1, 7),
        );
        expect(reminder.when, DateTime(2026, 8, 1, 8));
      },
    );

    test('different plan ids get different notification ids', () {
      final a = buildPlanReportReminder(
        planId: 'plan-a',
        planName: 'A',
        anchor: DateTime(2026, 8, 1),
        frequencyDays: 7,
        reminderTimeOfDayMinutes: 0,
        now: DateTime(2026, 8, 1),
      );
      final b = buildPlanReportReminder(
        planId: 'plan-b',
        planName: 'B',
        anchor: DateTime(2026, 8, 1),
        frequencyDays: 7,
        reminderTimeOfDayMinutes: 0,
        now: DateTime(2026, 8, 1),
      );
      expect(a.id, isNot(b.id));
    });

    test('the same plan id always gets the same notification id', () {
      expect(
        planReportReminderIdFor('plan-1'),
        planReportReminderIdFor('plan-1'),
      );
    });
  });
}
