import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../data/daos/plan_dao.dart';
import '../calendar/calendar_screen.dart';
import '../notifications/reminder_coordinator.dart';
import '../progress/progress_providers.dart';
import 'plan_providers.dart';
import 'plan_report_prompt.dart';

/// Rename / archive / delete for one plan.
///
/// The deletion model here is deliberate: archiving is the reversible way to
/// get a plan out of the way and needs no scary confirmation, while deleting
/// always states its blast radius in real numbers first. Logged workouts are
/// the one thing a user can never recreate, so removing a plan offers to keep
/// them rather than taking them down as collateral.
Future<void> showPlanActions(
  BuildContext context,
  WidgetRef ref,
  Plan plan,
) async {
  final action = await showModalBottomSheet<_PlanAction>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              plan.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              'Created ${DateFormat.yMMMd().format(plan.createdAt)}',
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.drive_file_rename_outline),
            title: const Text('Rename'),
            onTap: () => Navigator.of(context).pop(_PlanAction.rename),
          ),
          ListTile(
            leading: const Icon(Icons.notes_outlined),
            title: const Text('Notes'),
            subtitle: plan.notes.isEmpty
                ? null
                : Text(plan.notes, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => Navigator.of(context).pop(_PlanAction.notes),
          ),
          // Purely free text (this app has no real identity/account system)
          // - for a plan a trainer builds and hands off as a file, so it's
          // still clear whose plan a client is looking at once it's on their
          // own device. See Plans.createdBy's own doc comment.
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Created by'),
            subtitle: Text(plan.createdBy?.isNotEmpty == true
                ? plan.createdBy!
                : 'Not set'),
            onTap: () => Navigator.of(context).pop(_PlanAction.createdBy),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Progress reminders'),
            subtitle: Text(_reportPreferenceSubtitle(plan)),
            onTap: () => Navigator.of(context).pop(_PlanAction.reportPreference),
          ),
          if (plan.archivedAt == null)
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Archive'),
              subtitle: const Text(
                'Hide it from this list. Nothing is deleted, and you can '
                'bring it back any time.',
              ),
              onTap: () => Navigator.of(context).pop(_PlanAction.archive),
            )
          else
            ListTile(
              leading: const Icon(Icons.unarchive_outlined),
              title: const Text('Restore'),
              onTap: () => Navigator.of(context).pop(_PlanAction.unarchive),
            ),
          ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => Navigator.of(context).pop(_PlanAction.delete),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  if (action == null || !context.mounted) return;

  switch (action) {
    case _PlanAction.rename:
      await _rename(context, ref, plan);
    case _PlanAction.notes:
      await _editNotes(context, ref, plan);
    case _PlanAction.createdBy:
      await _editCreatedBy(context, ref, plan);
    case _PlanAction.archive:
      await _archive(context, ref, plan);
    case _PlanAction.unarchive:
      await ref.read(appDatabaseProvider).planDao.unarchivePlan(plan.id);
    case _PlanAction.delete:
      await _delete(context, ref, plan);
    case _PlanAction.reportPreference:
      await _changeReportPreference(context, ref, plan);
  }
}

enum _PlanAction {
  rename,
  notes,
  createdBy,
  archive,
  unarchive,
  delete,
  reportPreference,
}

String _reportPreferenceSubtitle(Plan plan) {
  if (plan.reportPreference != 'enabled') return 'Off';
  switch (plan.reportFrequencyDays) {
    case 7:
      return 'Weekly';
    case 14:
      return 'Every 2 weeks';
    case 30:
      return 'Monthly';
    default:
      return 'On';
  }
}

/// Lets the opt-in choice from `plan_report_prompt.dart`'s first-session
/// prompt be revisited later - turned on, off, or re-cadenced - since that
/// prompt only ever shows once per plan.
Future<void> _changeReportPreference(
  BuildContext context,
  WidgetRef ref,
  Plan plan,
) async {
  final isEnabled = plan.reportPreference == 'enabled';
  final choice = await showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Progress reminders'),
      children: [
        if (isEnabled)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop('change'),
            child: const Text('Change frequency'),
          ),
        if (isEnabled)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop('off'),
            child: const Text('Turn off'),
          )
        else
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop('on'),
            child: const Text('Turn on'),
          ),
      ],
    ),
  );
  if (choice == null) return;

  final db = ref.read(appDatabaseProvider);
  if (choice == 'off') {
    await db.planDao.setReportPreference(
      planId: plan.id,
      preference: 'declined',
    );
    ref.invalidate(planDetailsProvider(plan.id));
    await resyncReminders(ref);
    return;
  }

  if (!context.mounted) return;
  final frequencyDays = await askReportFrequency(context);
  if (frequencyDays == null) return;

  await db.planDao.setReportPreference(
    planId: plan.id,
    preference: 'enabled',
    frequencyDays: frequencyDays,
  );
  ref.invalidate(planDetailsProvider(plan.id));
  await resyncReminders(ref);
}

Future<void> _rename(BuildContext context, WidgetRef ref, Plan plan) async {
  final newName = await showDialog<String>(
    context: context,
    builder: (context) => _RenamePlanDialog(initialName: plan.name),
  );
  if (newName == null) return;

  await ref.read(appDatabaseProvider).planDao.renamePlan(plan.id, newName);
  ref.invalidate(planDetailsProvider(plan.id));
}

class _RenamePlanDialog extends StatefulWidget {
  final String initialName;

  const _RenamePlanDialog({required this.initialName});

  @override
  State<_RenamePlanDialog> createState() => _RenamePlanDialogState();
}

class _RenamePlanDialogState extends State<_RenamePlanDialog> {
  // Owned by this State (not created-and-disposed inline in the caller) so
  // dispose() only runs once the dialog route is actually removed from the
  // tree - disposing it right after showDialog's Future resolves races the
  // dialog's own exit transition (see execution_screen.dart's
  // _NotePromptDialog for the same fix, applied here and to
  // _EditNotesDialog below after both crashed with "'_dependents.isEmpty':
  // is not true" from exactly this race).
  late final _controller = TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename plan'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Plan name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => FilledButton(
            onPressed: _controller.text.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop(_controller.text.trim()),
            child: const Text('Rename'),
          ),
        ),
      ],
    );
  }
}

/// A free-text scratchpad on the plan itself - e.g. "swap deadlifts for RDLs
/// next block" - distinct from a plan exercise's own notes (edited per-row
/// via `edit_session_screen.dart`). See `PlanDao.updatePlanNotes`. Unlike
/// [_rename], an empty result is a valid save (clearing the notes), not a
/// disabled button - there's nothing wrong with a plan having no notes.
Future<void> _editNotes(BuildContext context, WidgetRef ref, Plan plan) async {
  final newNotes = await showDialog<String>(
    context: context,
    builder: (context) => _EditNotesDialog(initialNotes: plan.notes),
  );
  if (newNotes == null) return;

  await ref.read(appDatabaseProvider).planDao.updatePlanNotes(plan.id, newNotes);
  ref.invalidate(planDetailsProvider(plan.id));
}

class _EditNotesDialog extends StatefulWidget {
  final String initialNotes;

  const _EditNotesDialog({required this.initialNotes});

  @override
  State<_EditNotesDialog> createState() => _EditNotesDialogState();
}

class _EditNotesDialogState extends State<_EditNotesDialog> {
  late final _controller = TextEditingController(text: widget.initialNotes);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Plan notes'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 5,
        decoration: const InputDecoration(
          labelText: 'Notes',
          hintText: 'e.g. "Swap deadlifts for RDLs next block"',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Who authored this plan (e.g. a trainer's name) - see `PlanDao.
/// updatePlanCreatedBy`. Round-trips through export/import unchanged, unlike
/// an exercise's own author/sourcePlanName fields (which get regenerated per
/// device) - see `Plans.createdBy`'s own doc comment for why this one field
/// is different. An empty result clears it back to "not set" (null), not an
/// empty string - see `updatePlanCreatedBy`'s own doc comment.
Future<void> _editCreatedBy(BuildContext context, WidgetRef ref, Plan plan) async {
  final newValue = await showDialog<String>(
    context: context,
    builder: (context) => _EditCreatedByDialog(initialValue: plan.createdBy ?? ''),
  );
  if (newValue == null) return;

  await ref
      .read(appDatabaseProvider)
      .planDao
      .updatePlanCreatedBy(plan.id, newValue.isEmpty ? null : newValue);
  ref.invalidate(planDetailsProvider(plan.id));
}

class _EditCreatedByDialog extends StatefulWidget {
  final String initialValue;

  const _EditCreatedByDialog({required this.initialValue});

  @override
  State<_EditCreatedByDialog> createState() => _EditCreatedByDialogState();
}

class _EditCreatedByDialogState extends State<_EditCreatedByDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Created by'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Created by',
          hintText: 'e.g. "Coach Erik"',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Archiving is fully reversible, so it gets an undo rather than a
/// confirmation - asking someone to confirm a harmless action just trains
/// them to dismiss dialogs without reading.
Future<void> _archive(BuildContext context, WidgetRef ref, Plan plan) async {
  final db = ref.read(appDatabaseProvider);
  await db.planDao.archivePlan(plan.id);
  ref.invalidate(scheduledSessionsProvider);
  await resyncReminders(ref);

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('"${plan.name}" archived.'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () async {
          await db.planDao.unarchivePlan(plan.id);
          ref.invalidate(scheduledSessionsProvider);
        },
      ),
    ),
  );
}

Future<void> _delete(BuildContext context, WidgetRef ref, Plan plan) async {
  final db = ref.read(appDatabaseProvider);
  final impact = await db.planDao.getPlanDeletionImpact(plan.id);
  if (!context.mounted) return;

  final choice = await showDialog<_DeleteChoice>(
    context: context,
    builder: (context) => _DeleteDialog(plan: plan, impact: impact),
  );
  if (choice == null) return;

  switch (choice) {
    case _DeleteChoice.keepHistory:
      await db.planDao.deletePlanKeepingHistory(plan.id);
    case _DeleteChoice.deleteEverything:
      await db.planDao.deletePlanAndHistory(plan.id);
  }

  ref.invalidate(scheduledSessionsProvider);
  ref.invalidate(loggedPlanSessionIdsProvider);
  ref.invalidate(exerciseProgressDashboardProvider);
  await resyncReminders(ref);

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('"${plan.name}" deleted.')),
  );
}

enum _DeleteChoice { keepHistory, deleteEverything }

class _DeleteDialog extends StatelessWidget {
  final Plan plan;
  final PlanDeletionImpact impact;

  const _DeleteDialog({required this.plan, required this.impact});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat.yMMMd();

    // Nothing was ever logged: this is just tidying, so keep it simple.
    if (!impact.losesHistory) {
      return AlertDialog(
        title: Text('Delete "${plan.name}"?'),
        content: Text(
          impact.sessions == 0
              ? 'This plan is empty. Nothing else will be affected.'
              : 'This removes ${_count(impact.sessions, 'session')} and '
                    '${_count(impact.exercises, 'exercise')}.\n\n'
                    'You have never logged a workout from this plan, so no '
                    'training history is affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(_DeleteChoice.keepHistory),
            child: const Text('Delete'),
          ),
        ],
      );
    }

    final range = impact.firstLoggedAt == null
        ? ''
        : ' recorded between ${dateFormat.format(impact.firstLoggedAt!)} and '
              '${dateFormat.format(impact.lastLoggedAt!)}';

    return AlertDialog(
      title: Text('Delete "${plan.name}"?'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This plan has '
              '${_count(impact.loggedWorkouts, 'logged workout')} '
              '(${_count(impact.loggedSets, 'set')})$range.',
            ),
            const SizedBox(height: 16),
            Text('Choose what to do with that history:',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            _Option(
              icon: Icons.history,
              title: 'Keep my training history',
              body:
                  'Removes the plan and its sessions, but every workout you '
                  'logged stays in your history and progress charts.',
              recommended: true,
              onTap: () =>
                  Navigator.of(context).pop(_DeleteChoice.keepHistory),
            ),
            const SizedBox(height: 8),
            _Option(
              icon: Icons.delete_forever,
              title: 'Delete everything',
              body:
                  'Also permanently erases all '
                  '${impact.loggedWorkouts} logged workouts. This cannot be '
                  'undone.',
              destructive: true,
              onTap: () =>
                  Navigator.of(context).pop(_DeleteChoice.deleteEverything),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 16, color: scheme.outline),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Not sure? Archive it instead - it disappears from your '
                    'list and nothing is lost.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  static String _count(int n, String noun) =>
      '$n $noun${n == 1 ? '' : 's'}';
}

class _Option extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool recommended;
  final bool destructive;
  final VoidCallback onTap;

  const _Option({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
    this.recommended = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = destructive ? scheme.error : scheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: accent.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(color: accent),
                        ),
                      ),
                      if (recommended) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Recommended',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(body, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
