import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../data/daos/plan_dao.dart';
import '../calendar/calendar_screen.dart';
import '../notifications/reminder_coordinator.dart';
import '../plans/plan_providers.dart';
import '../plans/plan_report_prompt.dart';
import '../progress/body_tracking_prompt.dart';
import 'execution_screen.dart';

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Starts one specific scheduled occurrence of [session] - [date] is which
/// of its (possibly several) dates is being started, always a real
/// `PlanSessionDates` row, never a placeholder for "no date yet" (a session
/// with zero dates has no Start affordance to tap in the first place - see
/// `plan_detail_screen.dart`'s per-date chips). Prompts first if [date] isn't
/// today - e.g. tapping "Start" on tomorrow's date asks whether to move it
/// to today rather than silently starting an out-of-schedule session (or
/// silently leaving its calendar date stale once logged).
Future<void> startSessionWithMoveToTodayPrompt(
  BuildContext context,
  WidgetRef ref,
  PlanSession session,
  DateTime date,
) async {
  final today = DateTime.now();
  final todayDateOnly = DateTime(today.year, today.month, today.day);

  if (!_isSameDay(date, today)) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to today?'),
        content: Text(
          'This session is scheduled for ${DateFormat.yMMMd().format(date)}. '
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
    await db.planDao.moveSessionDate(
      session.id,
      from: date,
      to: todayDateOnly,
    );
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

/// "Skip straight to logging" for one specific exercise picked outside any
/// plan - creates a throwaway single-session plan (never surfaced as a real
/// plan anywhere else) via `PlanDao.createPlan()` and jumps directly into
/// `ExecutionScreen` for it. Originated on `exercise_detail_screen.dart`'s
/// "Start now" button (per its own doc comment, reusing
/// `random_workout_screen.dart`'s original version of this same trick) and
/// extracted here once `today_screen.dart`'s own quick-start action became a
/// third user - copy this pattern for any future "skip straight to logging"
/// shortcut rather than duplicating it a fourth time.
///
/// Deliberately skips `startSessionWithMoveToTodayPrompt`'s first-session
/// prompts (body tracking, plan reports) - both are keyed to a real ongoing
/// plan and would be confusing noise in front of a session that exists only
/// to log a couple of sets right now.
Future<void> startNowWithExercise(
  BuildContext context,
  WidgetRef ref,
  Exercise exercise, {
  int sets = 3,
  String reps = '8-10',
  String weightIntensity = '',
  int? restSec,
}) async {
  final db = ref.read(appDatabaseProvider);
  const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final now = DateTime.now();
  final planId = const Uuid().v4();
  await db.planDao.createPlan(
    id: planId,
    name:
        'Quick: ${exercise.name} '
        '${MaterialLocalizations.of(context).formatMediumDate(now)}',
    sessions: [
      PlanSessionInput(
        weekNumber: 1,
        day: weekdayNames[now.weekday - 1],
        sessionName: exercise.name,
        exercises: [
          PlanExerciseInput(
            order: 1,
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            sets: sets,
            reps: reps,
            weightIntensity: weightIntensity,
            restSec: restSec,
          ),
        ],
      ),
    ],
  );
  if (!context.mounted) return;

  final details = await db.planDao.getPlanDetails(planId);
  final sessionId = details?.sessions.firstOrNull?.session.id;
  if (sessionId == null || !context.mounted) return;

  ref.invalidate(plansListProvider);
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => ExecutionScreen(planSessionId: sessionId),
    ),
  );
}
