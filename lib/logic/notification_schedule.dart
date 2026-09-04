import 'reminder_payload.dart';

/// A reminder the app wants the OS to deliver at a specific moment.
class ScheduledReminder {
  /// Stable per-reminder id, so re-scheduling replaces rather than duplicates.
  final int id;
  final String title;
  final String body;
  final DateTime when;

  /// Identifies what tapping this notification should open - see
  /// `reminder_payload.dart`'s `parseReminderPayload`, which is the single
  /// place both this and the tap-handling side agree on the format, so the
  /// two can't drift out of sync with each other.
  final String payload;

  const ScheduledReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.when,
    required this.payload,
  });

  @override
  bool operator ==(Object other) =>
      other is ScheduledReminder &&
      other.id == id &&
      other.title == title &&
      other.body == body &&
      other.when == when &&
      other.payload == payload;

  @override
  int get hashCode => Object.hash(id, title, body, when, payload);

  @override
  String toString() => 'ScheduledReminder($id, "$title", $when, $payload)';
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
const _planReportIdBase = 100000;

/// A session can now be scheduled on several dates at once, so the id can't
/// be a pure function of [planSessionId] alone any more - two dates for the
/// same session would collide and silently overwrite each other's pending
/// reminder. Folds the date in via the same bounded-hash technique
/// [planReportReminderIdFor] already uses below, kept inside a narrower
/// range (90000, not 900000) so it can't reach into that function's own
/// [_planReportIdBase]-offset range.
int workoutReminderIdFor(int planSessionId, DateTime date) =>
    _workoutReminderIdBase +
    (Object.hash(planSessionId, date.year, date.month, date.day) &
            0x7FFFFFFF) %
        90000;

/// Plans have a String (UUID) id, not the small int a `PlanSessions` row
/// gets, so there's no natural small offset the way [workoutReminderIdFor]
/// has - `hashCode` bounded into a wide-enough range keeps collisions
/// vanishingly unlikely for the handful of plans one person has, without
/// needing to persist a separate int id anywhere.
int planReportReminderIdFor(String planId) =>
    _planReportIdBase + (planId.hashCode & 0x7FFFFFFF) % 900000;

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
        id: workoutReminderIdFor(session.planSessionId, session.date),
        title: 'Workout today: ${session.sessionName}',
        body: session.planName,
        when: when,
        payload: buildWorkoutReminderPayload(session.planSessionId),
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
    payload: weeklyDigestPayload,
  );
}

/// The next occurrence of a per-plan progress reminder, every
/// [frequencyDays] days starting from [anchor] (when the plan owner opted
/// in - see plan_report_prompt.dart) - recomputed fresh each time reminders
/// are rebuilt rather than reading back a persisted "next fire date", same
/// approach as [buildWeeklyDigestReminder]. Always in the future relative
/// to [now]; if the anchor is far in the past this steps forward by whole
/// multiples of the cadence rather than one day at a time.
ScheduledReminder buildPlanReportReminder({
  required String planId,
  required String planName,
  required DateTime anchor,
  required int frequencyDays,
  required int reminderTimeOfDayMinutes,
  required DateTime now,
}) {
  final anchorDay = DateTime(anchor.year, anchor.month, anchor.day)
      .add(Duration(minutes: reminderTimeOfDayMinutes));
  // Duration.inDays truncates toward zero, so anything under 24h - whether
  // anchorDay is a few hours into the past or still a few hours into the
  // future - reads back as 0. Treating "0 or negative" as "no cycle has
  // elapsed yet" (rather than just "negative") lets the loop below still
  // reach anchorDay itself when it's still ahead of now, instead of always
  // preemptively skipping to the next cycle - e.g. opting in at 7am for an
  // 8am reminder should fire later that same day, not a full week out.
  final daysSinceAnchor = now.difference(anchorDay).inDays;
  final cyclesElapsed = daysSinceAnchor <= 0
      ? 0
      : (daysSinceAnchor ~/ frequencyDays) + 1;
  var when = anchorDay.add(Duration(days: cyclesElapsed * frequencyDays));
  while (!when.isAfter(now)) {
    when = when.add(Duration(days: frequencyDays));
  }

  return ScheduledReminder(
    id: planReportReminderIdFor(planId),
    title: 'Check your progress on $planName',
    body: 'See how training has gone, and share a summary if you\'d like.',
    when: when,
    payload: buildPlanReportPayload(planId),
  );
}
