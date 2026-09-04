import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../calendar/calendar_screen.dart';
import '../notifications/reminder_coordinator.dart';
import '../plans/plan_providers.dart';
import '../plans/plan_report_prompt.dart';
import '../progress/body_tracking_prompt.dart';
import 'execution_screen.dart';

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Starts [session], prompting first if it's scheduled for a day other than
/// today - e.g. tapping "Start" on tomorrow's session asks whether to move
/// it to today rather than silently starting an out-of-schedule session (or
/// silently leaving its calendar date stale once logged). A session with no
/// assigned date at all is silently assigned today rather than left unset -
/// the calendar only ever shows a session on its `assignedDate` (see
/// `calendar_screen.dart`), so starting (and finishing) a never-scheduled
/// session - the common case for a session started right after importing a
/// plan - would otherwise complete successfully but never appear on the
/// calendar at all, which reads as "my finished session didn't save." No
/// prompt for this case, unlike the reschedule below: there's no existing
/// date to ask about overwriting.
Future<void> startSessionWithMoveToTodayPrompt(
  BuildContext context,
  WidgetRef ref,
  PlanSession session,
) async {
  final assignedDate = session.assignedDate;
  final today = DateTime.now();
  final todayDateOnly = DateTime(today.year, today.month, today.day);

  if (assignedDate == null) {
    final db = ref.read(appDatabaseProvider);
    await db.planDao.assignSessionDate(session.id, todayDateOnly);
    ref.invalidate(scheduledSessionsProvider);
    ref.invalidate(planDetailsProvider(session.planId));
    await resyncReminders(ref);
  } else if (!_isSameDay(assignedDate, today)) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to today?'),
        content: Text(
          'This session is scheduled for ${DateFormat.yMMMd().format(assignedDate)}. '
          'Move it to today and start now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Move to today'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    if (!context.mounted) return;
    final db = ref.read(appDatabaseProvider);
    await db.planDao.assignSessionDate(session.id, todayDateOnly);
    ref.invalidate(scheduledSessionsProvider);
    ref.invalidate(planDetailsProvider(session.planId));
    await resyncReminders(ref);
  }

  // Asked once, on the way into a first session - the moment someone commits
  // to a programme is when tracking is worth offering, and it's a question
  // rather than a default. See body_tracking_prompt.dart.
  if (!context.mounted) return;
  await maybeAskAboutBodyTracking(context, ref);

  // Same "ask once, on the way into a first session" moment as body
  // tracking above - fetched fresh rather than passed in, since the caller
  // (a session row) doesn't carry its parent plan's report preference.
  if (!context.mounted) return;
  final details = await ref.read(planDetailsProvider(session.planId).future);
  if (details != null) {
    if (!context.mounted) return;
    await maybeAskAboutPlanReports(context, ref, details.plan);
  }

  if (!context.mounted) return;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => ExecutionScreen(planSessionId: session.id),
    ),
  );
}
