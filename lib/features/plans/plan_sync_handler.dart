import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database_provider.dart';
import '../../data/daos/plan_dao.dart';
import '../../import/plan_json_import.dart';
import '../../import/plan_sync.dart';
import '../calendar/calendar_screen.dart' show scheduledSessionsProvider;
import '../notifications/reminder_coordinator.dart';
import '../settings/backup_dialogs.dart';
import '../shared/exercise_list_invalidation.dart';
import 'plan_conflict_screen.dart';
import 'plan_providers.dart';

/// Imports a plan JSON, checking first whether it's actually a sync of a
/// plan already on this device (Phase 5, built on Phase 4's file-sharing
/// transport) rather than a brand-new plan. Shared between the manual
/// "Import plan -> From plan file" flow and the incoming-share handler, so
/// a sync conflict is caught the same way regardless of how the file
/// arrived.
Future<void> importOrSyncPlanJson(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> json,
) async {
  final db = ref.read(appDatabaseProvider);

  try {
    switch (await checkPlanSync(json, db)) {
      case PlanSyncNew():
        await importPlanJson(json, db);
        invalidateExerciseListProviders(ref);
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Plan imported.')));

      case PlanSyncUpToDate():
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already up to date.')),
        );

      case PlanSyncUpdate(
        :final local,
        :final incomingJson,
        :final editedHere,
      ):
        if (!context.mounted) return;
        if (editedHere) {
          // Changed on this device too - the user has to choose.
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PlanConflictScreen(
                local: local,
                incomingJson: incomingJson,
                isUpdate: true,
              ),
            ),
          );
        } else {
          await _confirmUpdate(context, ref, local, incomingJson);
        }

      case PlanSyncConflict(:final local, :final incomingJson):
        if (!context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PlanConflictScreen(
              local: local,
              incomingJson: incomingJson,
            ),
          ),
        );
    }
  } on PlanJsonFormatException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.message)));
  }
}

/// Who sent [incomingJson], for messages: its "created by", if stated.
String updateSenderPhrase(Map<String, dynamic> incomingJson) {
  final createdBy = (incomingJson['created_by'] as String?)?.trim();
  return createdBy == null || createdBy.isEmpty ? 'The sender' : createdBy;
}

/// A newer version of a plan that wasn't changed on this device: one
/// confirmation, then the contents are replaced and the user's calendar
/// dates and logged workouts stay.
Future<void> _confirmUpdate(
  BuildContext context,
  WidgetRef ref,
  PlanDetails local,
  Map<String, dynamic> incomingJson,
) async {
  final db = ref.read(appDatabaseProvider);
  final lost = await findLogsThatWouldBeLost(local, incomingJson, db);
  if (!context.mounted) return;
  final title = 'Update "${local.plan.name}"?';
  final intro =
      '${updateSenderPhrase(incomingJson)} sent an updated version of this '
      'plan. Your calendar dates and logged workouts stay as they are.';
  // A plain update is routine; it only gets the red warning when the new
  // version drops sessions that have logged workouts here.
  final confirmed = lost.isEmpty
      ? await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(title),
                content: Text(intro),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Not now'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Update'),
                  ),
                ],
              ),
            ) ??
            false
      : await confirmDestructiveAction(
          context,
          title: title,
          // Not `intro`: "your logged workouts stay" isn't true for these.
          message:
              '${updateSenderPhrase(incomingJson)} sent an updated version '
              'of this plan. It no longer has the sessions behind '
              '${lost.length == 1 ? '1 logged workout' : '${lost.length} logged workouts'} '
              'on this device - updating would delete '
              '${lost.length == 1 ? 'it' : 'them'}. Your other calendar '
              "dates and workouts stay. This can't be undone.",
          confirmLabel: 'Update anyway',
        );
  if (!confirmed || !context.mounted) return;
  try {
    await applyPlanUpdate(local, incomingJson, db);
  } on PlanJsonFormatException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.message)));
    return;
  }
  await refreshAfterPlanReplaced(ref, local.plan.id);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Updated to the new version.')),
  );
}

/// Everything that caches a plan's sessions, after its contents were
/// replaced under the same id: the plan screen, the calendar, and the
/// reminders (which point at the old sessions).
Future<void> refreshAfterPlanReplaced(WidgetRef ref, String planId) async {
  invalidateExerciseListProviders(ref);
  ref.invalidate(planDetailsProvider(planId));
  ref.invalidate(scheduledSessionsProvider);
  await resyncReminders(ref);
}
