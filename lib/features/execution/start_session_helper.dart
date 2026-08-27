import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../calendar/calendar_screen.dart';
import '../plans/plan_providers.dart';
import 'execution_screen.dart';

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Starts [session], prompting first if it's scheduled for a day other than
/// today - e.g. tapping "Start" on tomorrow's session asks whether to move
/// it to today rather than silently starting an out-of-schedule session (or
/// silently leaving its calendar date stale once logged). A session with no
/// assigned date at all starts immediately, no prompt - there's nothing to
/// move.
Future<void> startSessionWithMoveToTodayPrompt(
  BuildContext context,
  WidgetRef ref,
  PlanSession session,
) async {
  final assignedDate = session.assignedDate;
  final today = DateTime.now();

  if (assignedDate != null && !_isSameDay(assignedDate, today)) {
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
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    await db.planDao.assignSessionDate(session.id, todayDateOnly);
    ref.invalidate(scheduledSessionsProvider);
    ref.invalidate(planDetailsProvider(session.planId));
  }

  if (!context.mounted) return;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => ExecutionScreen(planSessionId: session.id),
    ),
  );
}
