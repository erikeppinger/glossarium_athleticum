import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database_provider.dart';
import '../../data/daos/session_log_dao.dart';
import '../../logic/skip_reason.dart';
import '../execution/start_session_helper.dart';
import '../progress/progress_providers.dart';

/// How many make-ups the Today tab lists before collapsing the rest into a
/// count - enough to act on, without turning the landing screen into a
/// backlog.
const _maxShown = 5;

/// "Missed recently" on the Today tab: prescribed exercises skipped in a
/// finished session that haven't been done since. Hidden entirely when
/// there's nothing to make up.
class MissedExercisesCard extends ConsumerWidget {
  const MissedExercisesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingMakeUpsProvider).valueOrNull ?? const [];
    if (pending.isEmpty) return const SizedBox.shrink();

    final shown = pending.take(_maxShown).toList();
    final hiddenCount = pending.length - shown.length;

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.repeat),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Missed recently',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Skipped exercises you haven\'t done since. Doing one again in '
              'any session clears it.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            for (final makeUp in shown) _MakeUpTile(makeUp: makeUp),
            if (hiddenCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Text(
                  '+ $hiddenCount more',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MakeUpTile extends ConsumerWidget {
  final PendingMakeUp makeUp;

  const _MakeUpTile({required this.makeUp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skip = makeUp.skip;
    final reason = SkipReason.fromKey(skip.reason);
    final prescription =
        '${skip.prescribedSets}×${skip.prescribedReps}'
        '${skip.prescribedWeightIntensity.isEmpty ? '' : ' @ ${skip.prescribedWeightIntensity}'}';
    final details = [
      'Skipped ${MaterialLocalizations.of(context).formatMediumDate(makeUp.skippedAt)}',
      ?reason?.label,
      prescription,
    ].join(' • ');

    // A Column with the actions underneath rather than ListTile.trailing -
    // three buttons there squeeze the title into a sliver (see CLAUDE.md).
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(skip.exerciseName, style: Theme.of(context).textTheme.titleSmall),
          Text(details, style: Theme.of(context).textTheme.bodySmall),
          if (skip.queuedForNextSession)
            Text(
              'Will be offered in your next session',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          OverflowBar(
            spacing: 4,
            children: [
              TextButton(
                onPressed: () => _doNow(context, ref),
                child: const Text('Do now'),
              ),
              TextButton(
                onPressed: () => _toggleQueued(ref),
                child: Text(
                  skip.queuedForNextSession
                      ? 'Don\'t add to next session'
                      : 'Add to next session',
                ),
              ),
              TextButton(
                onPressed: () => _dismiss(context, ref),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _doNow(BuildContext context, WidgetRef ref) async {
    final skip = makeUp.skip;
    final exercise = await ref
        .read(appDatabaseProvider)
        .exerciseDao
        .getExerciseById(skip.exerciseId);
    if (!context.mounted) return;
    if (exercise == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${skip.exerciseName} is no longer in your exercise library.',
          ),
        ),
      );
      return;
    }
    await startNowWithExercise(
      context,
      ref,
      exercise,
      sets: skip.prescribedSets,
      reps: skip.prescribedReps,
      weightIntensity: skip.prescribedWeightIntensity,
      restSec: skip.prescribedRestSec,
    );
  }

  Future<void> _toggleQueued(WidgetRef ref) async {
    await ref
        .read(appDatabaseProvider)
        .sessionLogDao
        .setMakeUpQueued(makeUp.skip.id, !makeUp.skip.queuedForNextSession);
    ref.invalidate(pendingMakeUpsProvider);
  }

  Future<void> _dismiss(BuildContext context, WidgetRef ref) async {
    final dao = ref.read(appDatabaseProvider).sessionLogDao;
    // This tile is removed from the tree as soon as the list refreshes, so
    // the Undo callback below can't use `ref` - the container outlives it.
    final container = ProviderScope.containerOf(context, listen: false);
    final id = makeUp.skip.id;
    await dao.setMakeUpDismissed(id, true);
    container.invalidate(pendingMakeUpsProvider);
    if (!context.mounted) return;
    // Reversible, so an undo rather than a confirmation dialog (see the
    // deletion convention in CLAUDE.md).
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${makeUp.skip.exerciseName} removed from your list.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await dao.setMakeUpDismissed(id, false);
            container.invalidate(pendingMakeUpsProvider);
          },
        ),
      ),
    );
  }
}
