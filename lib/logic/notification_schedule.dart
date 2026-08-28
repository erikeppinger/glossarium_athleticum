/// A reminder the app wants the OS to deliver at a specific moment.
class ScheduledReminder {
  /// Stable per-reminder id, so re-scheduling replaces rather than duplicates.
  final int id;
  final String title;
  final String body;
  final DateTime when;

  const ScheduledReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.when,
  });

  @override
  bool operator ==(Object other) =>
      other is ScheduledReminder &&
      other.id == id &&
      other.title == title &&
      other.body == body &&
      other.when == when;

  @override
  int get hashCode => Object.hash(id, title, body, when);

  @override
  String toString() => 'ScheduledReminder($id, "$title", $when)';
}

/// One scheduled session, reduced to just what reminder-building needs.
class ReminderSession {
  final int planSessionId;
  final String sessionName;
  final String planName;
  final DateTime date;

  const ReminderSession({
    required this.planSessionId,
    required this.sessionName,
    required this.planName,
    required this.date,
  });
}

/// Notification ids are namespaced by offset so a workout reminder and the
/// weekly digest can never collide, and so cancelling one kind is possible
/// without touching the other.
const weeklyDigestNotificationId = 1;
const _workoutReminderIdBase = 1000;

int workoutReminderIdFor(int planSessionId) =>
    _workoutReminderIdBase + planSessionId;

/// Reminders for each scheduled session, at [reminderTimeOfDayMinutes] past
/// midnight on that session's day. Sessions whose reminder moment has already
/// passed relative to [now] are skipped - the OS rejects past-dated schedules,
/// and a reminder for a workout that was due this morning isn't useful.
List<ScheduledReminder> buildWorkoutReminders({
  required List<ReminderSession> sessions,
  required int reminderTimeOfDayMinutes,
  required DateTime now,
}) {
  final reminders = <ScheduledReminder>[];
  for (final session in sessions) {
    final when = DateTime(
      session.date.year,
      session.date.month,
      session.date.day,
    ).add(Duration(minutes: reminderTimeOfDayMinutes));
    if (!when.isAfter(now)) continue;
    reminders.add(
      ScheduledReminder(
        id: workoutReminderIdFor(session.planSessionId),
        title: 'Workout today: ${session.sessionName}',
        body: session.planName,
        when: when,
      ),
    );
  }
  return reminders;
}

/// The next weekly-overview reminder: the upcoming [digestWeekday]
/// (DateTime.monday..DateTime.sunday) at [reminderTimeOfDayMinutes]. If today
/// is that weekday but the time has already passed, rolls to next week.
ScheduledReminder buildWeeklyDigestReminder({
  required int digestWeekday,
  required int reminderTimeOfDayMinutes,
  required DateTime now,
  required int sessionsPlannedThisWeek,
}) {
  final today = DateTime(now.year, now.month, now.day);
  var daysAhead = (digestWeekday - today.weekday) % 7;
  var when = today
      .add(Duration(days: daysAhead))
      .add(Duration(minutes: reminderTimeOfDayMinutes));
  if (!when.isAfter(now)) {
    daysAhead += 7;
    when = today
        .add(Duration(days: daysAhead))
        .add(Duration(minutes: reminderTimeOfDayMinutes));
  }

  return ScheduledReminder(
    id: weeklyDigestNotificationId,
    title: 'Your training week',
    body: sessionsPlannedThisWeek == 0
        ? 'No sessions scheduled yet this week.'
        : '$sessionsPlannedThisWeek session${sessionsPlannedThisWeek == 1 ? '' : 's'} planned this week.',
    when: when,
  );
}
