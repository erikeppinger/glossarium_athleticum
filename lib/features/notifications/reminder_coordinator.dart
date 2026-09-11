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
/// sessions + per-plan report opt-ins and hands them to the OS. Called after
/// anything that could change what should fire: toggling a reminder setting,
/// changing the reminder time, assigning/moving a session's date, or changing
/// a plan's report opt-in (see plan_report_prompt.dart).
///
/// Always cancels every *pending* reminder first rather than diffing - the
/// set is small (one per dated session), and a full rebuild can't leave a
/// stale reminder behind for a session that was deleted or rescheduled.
/// Deliberately scoped to pending (scheduled-but-not-fired) reminders only,
/// not a blanket `cancelAll()` - this runs on every app launch
/// (`home_screen.dart`'s own `initState`), which used to silently wipe out
/// an already-showing ongoing notification (e.g. "session in progress",
/// re-posted moments earlier during startup) every single time.
Future<void> resyncReminders(WidgetRef ref) async {
  final service = ref.read(notificationServiceProvider);
  final prefs = ref.read(appPreferencesProvider);

  await service.cancelAllScheduledReminders();

  final db = ref.read(appDatabaseProvider);
  final now = DateTime.now();

  final reportPlans = (await db.planDao.getAllPlans()).where(
    (p) => p.archivedAt == null && p.reportPreference == 'enabled',
  );
  for (final plan in reportPlans) {
    if (plan.reportOptInAt == null || plan.reportFrequencyDays == null) {
      continue;
    }
    await service.schedule(
      buildPlanReportReminder(
        planId: plan.id,
        planName: plan.name,
        anchor: plan.reportOptInAt!,
        frequencyDays: plan.reportFrequencyDays!,
        reminderTimeOfDayMinutes: prefs.reminderTimeMinutes,
        now: now,
      ),
    );
  }

  if (!prefs.workoutRemindersEnabled && !prefs.weeklyDigestEnabled) return;

  final scheduled = await db.planDao.getAllScheduledSessions();

  if (prefs.workoutRemindersEnabled) {
    final reminders = buildWorkoutReminders(
      sessions: [
        for (final s in scheduled)
          ReminderSession(
            planSessionId: s.session.id,
            sessionName: s.session.sessionName,
            planName: s.planName,
            date: s.date,
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
      return !s.date.isBefore(week.start) && s.date.isBefore(week.end);
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
