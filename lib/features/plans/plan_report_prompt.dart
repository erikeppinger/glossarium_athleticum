import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../notifications/reminder_coordinator.dart';
import 'plan_providers.dart';

/// Asks once, the first time a session in [plan] is started, whether to get
/// an occasional "check your progress" reminder for it.
///
/// Per-plan and opt-in for the same reason as `body_tracking_prompt.dart`:
/// interest in check-ins varies by plan, and a "no" is remembered rather than
/// asked again. Reachable again later from the plan's own menu (see
/// `plan_actions.dart`) if someone changes their mind either way.
Future<void> maybeAskAboutPlanReports(
  BuildContext context,
  WidgetRef ref,
  Plan plan,
) async {
  if (plan.reportPreference != 'notAsked') return;

  final wantsReports = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.notifications_active_outlined),
      title: const Text('Progress check-ins for this plan?'),
      content: Text(
        'Want an occasional reminder to check how "${plan.name}" is going, '
        'with a quick link to your progress summary?\n\n'
        'This is entirely optional and only applies to this plan - you can '
        "change it later from the plan's menu.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('No thanks'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Yes, remind me'),
        ),
      ],
    ),
  );

  // A dismissed dialog is not an answer - leave it unasked so the question
  // can come back next time, same as body_tracking_prompt.dart.
  if (wantsReports == null) return;

  if (!wantsReports) {
    await ref
        .read(appDatabaseProvider)
        .planDao
        .setReportPreference(planId: plan.id, preference: 'declined');
    // planDetailsProvider is a one-shot FutureProvider - without this, the
    // cached "notAsked" plan sticks around and this prompt fires again on
    // every subsequent session start for the plan.
    ref.invalidate(planDetailsProvider(plan.id));
    return;
  }

  if (!context.mounted) return;
  final frequencyDays = await askReportFrequency(context);
  // Dismissed mid-flow: leave the plan at notAsked rather than half-committing
  // to "enabled" with no chosen cadence.
  if (frequencyDays == null) return;

  await ref
      .read(appDatabaseProvider)
      .planDao
      .setReportPreference(
        planId: plan.id,
        preference: 'enabled',
        frequencyDays: frequencyDays,
      );
  ref.invalidate(planDetailsProvider(plan.id));
  await resyncReminders(ref);
}

/// A plain button-then-`SimpleDialog` picker, matching the rest of the app's
/// convention over `DropdownButtonFormField` (see CLAUDE.md). Shared by the
/// initial prompt above and `plan_actions.dart`'s "change frequency" entry.
Future<int?> askReportFrequency(BuildContext context) {
  return showDialog<int>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('How often?'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop(7),
          child: const Text('Every week'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop(14),
          child: const Text('Every 2 weeks'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop(30),
          child: const Text('Every month'),
        ),
      ],
    ),
  );
}
