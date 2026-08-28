import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database_provider.dart';
import '../../logic/notification_schedule.dart';
import '../../logic/summary_period.dart';
import '../settings/app_preferences.dart';
import 'notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

/// Re-derives every pending reminder from current settings + scheduled
/// sessions and hands them to the OS. Called after anything that could change
/// what should fire: toggling a reminder setting, changing the reminder time,
/// or assigning/moving a session's date.
///
/// Always cancels everything first rather than diffing - the set of pending
/// reminders is small (one per dated session), and a full rebuild can't leave
/// a stale reminder behind for a session that was deleted or rescheduled.
Future<void> resyncReminders(WidgetRef ref) async {
  final service = ref.read(notificationServiceProvider);
  final prefs = ref.read(appPreferencesProvider);

  await service.cancelAll();
  if (!prefs.workoutRemindersEnabled && !prefs.weeklyDigestEnabled) return;

  final db = ref.read(appDatabaseProvider);
  final scheduled = await db.planDao.getAllScheduledSessions();
  final now = DateTime.now();

  if (prefs.workoutRemindersEnabled) {
    final reminders = buildWorkoutReminders(
      sessions: [
        for (final s in scheduled)
          if (s.session.assignedDate != null)
            ReminderSession(
              planSessionId: s.session.id,
              sessionName: s.session.sessionName,
              planName: s.planName,
              date: s.session.assignedDate!,
            ),
      ],
      reminderTimeOfDayMinutes: prefs.reminderTimeMinutes,
      now: now,
    );
    for (final reminder in reminders) {
      await service.schedule(reminder);
    }
  }

  if (prefs.weeklyDigestEnabled) {
    final week = computeSummaryRange(
      period: SummaryPeriod.week,
      weekStart: prefs.weekStart,
      offset: 0,
      now: now,
    );
    final plannedThisWeek = scheduled.where((s) {
      final date = s.session.assignedDate;
      if (date == null) return false;
      return !date.isBefore(week.start) && date.isBefore(week.end);
    }).length;

    await service.schedule(
      buildWeeklyDigestReminder(
        digestWeekday: prefs.digestWeekday,
        reminderTimeOfDayMinutes: prefs.reminderTimeMinutes,
        now: now,
        sessionsPlannedThisWeek: plannedThisWeek,
      ),
    );
  }
}
