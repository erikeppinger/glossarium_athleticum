import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../data/daos/session_log_dao.dart';
import '../../logic/units.dart';
import '../calendar/calendar_screen.dart' show loggedPlanSessionIdsProvider;
import '../progress/progress_providers.dart';
import '../settings/app_preferences.dart';

final workoutHistoryProvider = FutureProvider<List<CompletedWorkoutSummary>>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.sessionLogDao.getWorkoutHistory();
});

final completedWorkoutProvider =
    FutureProvider.family<CompletedWorkout?, String>((ref, logId) {
      final db = ref.watch(appDatabaseProvider);
      return db.sessionLogDao.getCompletedWorkout(logId);
    });

/// Every completed workout, newest first. The app recorded all of this from
/// day one but had no way to read it back - only aggregate charts.
class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(workoutHistoryProvider);
    final unit = ref.watch(appPreferencesProvider).weightUnit;

    return Scaffold(
      appBar: AppBar(title: const Text('Workout history')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (workouts) {
          if (workouts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No completed workouts yet.\n'
                  'Finish a session and it will show up here.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              final w = workouts[index];
              final detail = w.isAdHocActivity
                  ? [
                      if (w.durationSec != null)
                        formatDurationSec(w.durationSec!),
                      if (w.distance != null) formatDistanceMeters(w.distance!),
                    ].join(' • ')
                  : '${w.setCount} set${w.setCount == 1 ? '' : 's'} • '
                        '${formatWeightInUnit(w.volume, unit)}'
                        '${w.prCount > 0 ? ' • ${w.prCount} PR${w.prCount == 1 ? '' : 's'}' : ''}';
              return ListTile(
                leading: w.isAdHocActivity
                    ? const Icon(Icons.directions_walk)
                    : null,
                title: Text(w.sessionName),
                subtitle: Text(
                  '${DateFormat.yMMMEd().format(w.loggedAt)}'
                  '${detail.isEmpty ? '' : '\n$detail'}',
                ),
                isThreeLine: true,
                trailing: w.prCount > 0
                    ? const Icon(Icons.emoji_events, color: Colors.amber)
                    : const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        CompletedWorkoutScreen(logId: w.logId),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// One completed workout, set by set - what was actually done, as opposed to
/// what the plan prescribed.
class CompletedWorkoutScreen extends ConsumerWidget {
  final String logId;

  const CompletedWorkoutScreen({super.key, required this.logId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(completedWorkoutProvider(logId));
    final unit = ref.watch(appPreferencesProvider).weightUnit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete this workout',
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      body: workoutAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (workout) {
          if (workout == null) {
            return const Center(child: Text('Workout not found.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                workout.sessionName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                DateFormat.yMMMMEEEEd().add_jm().format(workout.log.loggedAt),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (workout.log.planSessionId == null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  children: [
                    if (workout.log.durationSec != null)
                      _StatChip(
                        icon: Icons.timer_outlined,
                        label: formatDurationSec(workout.log.durationSec!),
                      ),
                    if (workout.log.distance != null)
                      _StatChip(
                        icon: Icons.straighten,
                        label: formatDistanceMeters(workout.log.distance!),
                      ),
                  ],
                ),
              ],
              if (workout.log.notes != null &&
                  workout.log.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(workout.log.notes!),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              for (final exercise in workout.exercises)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.exerciseName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        for (var i = 0; i < exercise.sets.length; i++)
                          _SetRow(
                            setNumber: i + 1,
                            set: exercise.sets[i],
                            unit: unit,
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this workout?'),
        content: const Text(
          'This permanently removes the record of what you did in this '
          'session. Your plan is not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final db = ref.read(appDatabaseProvider);
    await db.sessionLogDao.deleteSessionLog(logId);
    ref.invalidate(workoutHistoryProvider);
    ref.invalidate(loggedPlanSessionIdsProvider);
    invalidateProgressProviders(ref);

    if (context.mounted) Navigator.of(context).pop();
  }
}

class _SetRow extends StatelessWidget {
  final int setNumber;
  final LoggedSet set;
  final WeightUnit unit;

  const _SetRow({
    required this.setNumber,
    required this.set,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (set.weight != null) formatWeightInUnit(set.weight!, unit),
      if (set.reps != null) '${set.reps} reps',
      if (set.durationSec != null) '${set.durationSec!.toInt()}s',
      if (set.distance != null) '${set.distance}m',
      if (set.rpe != null) 'RPE ${set.rpe}',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '$setNumber',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Text(
              parts.isEmpty ? 'Logged' : parts.join(' × '),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (set.isPr)
            Icon(Icons.emoji_events, size: 18, color: Colors.amber.shade700),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}
