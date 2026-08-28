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
    case _PlanAction.archive:
      await _archive(context, ref, plan);
    case _PlanAction.unarchive:
      await ref.read(appDatabaseProvider).planDao.unarchivePlan(plan.id);
    case _PlanAction.delete:
      await _delete(context, ref, plan);
  }
}

enum _PlanAction { rename, archive, unarchive, delete }

Future<void> _rename(BuildContext context, WidgetRef ref, Plan plan) async {
  final controller = TextEditingController(text: plan.name);
  final newName = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Rename plan'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Plan name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => FilledButton(
            onPressed: controller.text.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Rename'),
          ),
        ),
      ],
    ),
  );
  controller.dispose();
  if (newName == null) return;

  await ref.read(appDatabaseProvider).planDao.renamePlan(plan.id, newName);
  ref.invalidate(planDetailsProvider(plan.id));
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
