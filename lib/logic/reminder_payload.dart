/// What tapping a scheduled reminder notification should open. The single
/// place both sides of the tap-handling round-trip agree on the string
/// format - `notification_schedule.dart` builds these, `NotificationService`
/// (via `HomeScreen`) parses them back - so the format can't drift out of
/// sync between the two independently.
sealed class ReminderPayload {
  const ReminderPayload();
}

/// Opens execution mode for this specific scheduled session.
class WorkoutReminderPayload extends ReminderPayload {
  final int planSessionId;
  const WorkoutReminderPayload(this.planSessionId);
}

/// Opens the Progress tab.
class WeeklyDigestPayload extends ReminderPayload {
  const WeeklyDigestPayload();
}

/// Opens the Progress tab - same destination as the weekly digest for now;
/// see plan_report_prompt.dart for why a full plan-detail deep link wasn't
/// worth the extra DB round-trip for a first pass.
class PlanReportPayload extends ReminderPayload {
  final String planId;
  const PlanReportPayload(this.planId);
}

const weeklyDigestPayload = 'digest';

String buildWorkoutReminderPayload(int planSessionId) =>
    'workout:$planSessionId';

String buildPlanReportPayload(String planId) => 'plan_report:$planId';

/// Null for a payload that's missing, empty, or doesn't match any known
/// format (e.g. a notification left over from a version of the app that
/// used a different scheme) - callers should just no-op rather than throw,
/// since a notification tap is not a place to surface a parse error.
ReminderPayload? parseReminderPayload(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  if (raw == weeklyDigestPayload) return const WeeklyDigestPayload();
  if (raw.startsWith('workout:')) {
    final id = int.tryParse(raw.substring('workout:'.length));
    return id == null ? null : WorkoutReminderPayload(id);
  }
  if (raw.startsWith('plan_report:')) {
    final planId = raw.substring('plan_report:'.length);
    return planId.isEmpty ? null : PlanReportPayload(planId);
  }
  return null;
}
