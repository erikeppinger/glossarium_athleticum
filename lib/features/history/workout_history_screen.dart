import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../data/daos/session_log_dao.dart';
import '../../logic/load_input.dart';
import '../../logic/set_measure.dart';
import '../../logic/skip_reason.dart';
import '../../logic/summary_period.dart';
import '../../logic/units.dart';
import '../calendar/calendar_screen.dart' show loggedPlanSessionIdsProvider;
import '../execution/execution_screen.dart' show exerciseLookupProvider;
import '../progress/progress_providers.dart';
import '../settings/app_preferences.dart';
import '../shared/numeric_input_formatters.dart';
import '../shared/screen_padding.dart';

final workoutHistoryProvider = FutureProvider<List<CompletedWorkoutSummary>>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.sessionLogDao.getWorkoutHistory();
});

/// Same data as [workoutHistoryProvider], scoped to one [PeriodRange] and
/// optionally to just ad-hoc activities - backs [WorkoutHistoryScreen] when
/// it's opened from the Progress tab's period controls or activity chips,
/// rather than the all-time "Workout history" entry point.
final workoutHistoryInRangeProvider = FutureProvider.family<
    List<CompletedWorkoutSummary>, ({PeriodRange range, bool adHocOnly})>((
  ref,
  args,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.sessionLogDao.getWorkoutHistory(
    start: args.range.start,
    end: args.range.end,
    adHocOnly: args.adHocOnly,
  );
});

final completedWorkoutProvider =
    FutureProvider.family<CompletedWorkout?, String>((ref, logId) {
      final db = ref.watch(appDatabaseProvider);
      return db.sessionLogDao.getCompletedWorkout(logId);
    });

/// Every completed workout, newest first. The app recorded all of this from
/// day one but had no way to read it back - only aggregate charts.
///
/// [range]/[adHocOnly] scope this to one period (and optionally just its
/// ad-hoc activities) instead of all-time history - used when this screen is
/// pushed from the Progress tab's period controls or activity chips, so
/// what's listed matches whatever period/summary the user was just looking
/// at. Both null/false (the default) is the original all-time behaviour.
class WorkoutHistoryScreen extends ConsumerWidget {
  final PeriodRange? range;
  final bool adHocOnly;
  final String? title;

  const WorkoutHistoryScreen({
    super.key,
    this.range,
    this.adHocOnly = false,
    this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scopedRange = range;
    final historyAsync = scopedRange == null
        ? ref.watch(workoutHistoryProvider)
        : ref.watch(
            workoutHistoryInRangeProvider((
              range: scopedRange,
              adHocOnly: adHocOnly,
            )),
          );
    final unit = ref.watch(appPreferencesProvider).weightUnit;

    return Scaffold(
      appBar: AppBar(title: Text(title ?? 'Workout history')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (workouts) {
          if (workouts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  scopedRange == null
                      ? 'No completed workouts yet.\n'
                            'Finish a session and it will show up here.'
                      : 'Nothing logged in this period.',
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
            padding: screenListPadding(context),
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
              const SizedBox(height: 12),
              if (workout.log.notes != null && workout.log.notes!.isNotEmpty)
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: InkWell(
                    onTap: () => _editSessionNote(context, ref, workout),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(child: Text(workout.log.notes!)),
                          Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _editSessionNote(context, ref, workout),
                    icon: const Icon(Icons.add),
                    label: const Text('Add a note'),
                  ),
                ),
              const SizedBox(height: 8),
              for (final exercise in workout.exercises)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                exercise.exerciseName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  _editExerciseNote(context, ref, exercise),
                              tooltip: _exerciseNote(exercise) == null
                                  ? 'Add a note for your trainer'
                                  : 'Edit your note for the trainer',
                              icon: Icon(
                                _exerciseNote(exercise) == null
                                    ? Icons.sticky_note_2_outlined
                                    : Icons.sticky_note_2,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        if (exercise.substituteFor != null)
                          Text(
                            'In place of ${exercise.substituteFor}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (_exerciseNote(exercise) case final note?)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Your note: $note',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontStyle: FontStyle.italic),
                            ),
                          ),
                        const SizedBox(height: 8),
                        for (var i = 0; i < exercise.sets.length; i++)
                          _SetRow(
                            setNumber: i + 1,
                            set: exercise.sets[i],
                            unit: unit,
                            loadInput: _loadInput(ref, exercise),
                            onEdited: () => _onSetEdited(ref),
                          ),
                      ],
                    ),
                  ),
                ),
              if (workout.skipped.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Skipped', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                // A muted, non-circular marker: the outlined minus used to
                // skip during a session read as a button here.
                for (final skip in workout.skipped)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: skip.replacedByExerciseId != null
                        ? Icon(
                            Icons.swap_horiz,
                            color: Theme.of(context).colorScheme.outline,
                          )
                        : Icon(
                            Icons.skip_next,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    title: Text(skip.exerciseName),
                    subtitle: Text(_skipSubtitle(skip)),
                  ),
              ],
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
    _invalidateAfterChange(ref);

    if (context.mounted) Navigator.of(context).pop();
  }

  /// Reported live (2026-09-16): once a session was finished, correcting a
  /// mistyped value (e.g. the wrong rep count) meant deleting the whole
  /// workout and redoing it - there was no way to fix just one set. A
  /// tapped set now opens [_EditSetDialog]; this refreshes everything an
  /// edited weight/reps could affect (this workout's own detail view via
  /// [completedWorkoutProvider], the history list's volume/PR summary, and
  /// Progress) - the same invalidation set [_delete] already needed, since
  /// both change what a logged set contributes to.
  void _onSetEdited(WidgetRef ref) {
    ref.invalidate(completedWorkoutProvider(logId));
    _invalidateAfterChange(ref);
  }

  LoadInput _loadInput(WidgetRef ref, CompletedExercise exercise) {
    final library = ref
        .watch(exerciseLookupProvider)
        .valueOrNull?[exercise.exerciseId];
    return loadInputFor(
      equipment: library?.equipment ?? '',
      category: library?.category ?? '',
      measurementType: library?.measurementType ?? '',
      prescribedWeight: exercise.prescription?.weightIntensity ?? '',
    );
  }

  /// The trainee's note on [exercise], if any - stored on one of its sets
  /// (see `LoggedSets.notes`).
  String? _exerciseNote(CompletedExercise exercise) {
    for (final set in exercise.sets) {
      final note = set.notes;
      if (note != null && note.isNotEmpty) return note;
    }
    return null;
  }

  Future<void> _editSessionNote(
    BuildContext context,
    WidgetRef ref,
    CompletedWorkout workout,
  ) async {
    final note = await showDialog<String>(
      context: context,
      builder: (context) => _EditNoteDialog(
        title: 'Note on this workout',
        hint: 'How did it go?',
        initialValue: workout.log.notes ?? '',
      ),
    );
    if (note == null) return;
    await ref
        .read(appDatabaseProvider)
        .sessionLogDao
        .updateSessionLogNotes(workout.log.id, note);
    ref.invalidate(completedWorkoutProvider(logId));
  }

  /// Edits the note on whichever set already holds it, or attaches a new
  /// one to the exercise's first set - the same place execution mode puts it.
  Future<void> _editExerciseNote(
    BuildContext context,
    WidgetRef ref,
    CompletedExercise exercise,
  ) async {
    if (exercise.sets.isEmpty) return;
    final holder = exercise.sets.firstWhere(
      (s) => s.notes != null && s.notes!.isNotEmpty,
      orElse: () => exercise.sets.first,
    );
    final note = await showDialog<String>(
      context: context,
      builder: (context) => _EditNoteDialog(
        title: 'Note for your trainer',
        hint: 'e.g. left shoulder felt off',
        initialValue: holder.notes ?? '',
      ),
    );
    if (note == null) return;
    await ref
        .read(appDatabaseProvider)
        .sessionLogDao
        .updateLoggedSetNotes(holder.id, note);
    ref.invalidate(completedWorkoutProvider(logId));
  }

  void _invalidateAfterChange(WidgetRef ref) {
    ref.invalidate(workoutHistoryProvider);
    // Also invalidates every period-scoped list this same log could be
    // showing in (the Progress tab's activity-chip drill-down, a custom
    // range) - found live while testing on Android: deleting from a scoped
    // list left it showing the just-deleted row until a full app restart,
    // since this family provider caches by default like any other
    // FutureProvider.family.
    ref.invalidate(workoutHistoryInRangeProvider);
    ref.invalidate(loggedPlanSessionIdsProvider);
    invalidateProgressProviders(ref);
  }
}

class _SetRow extends ConsumerWidget {
  final int setNumber;
  final LoggedSet set;
  final WeightUnit unit;
  final LoadInput loadInput;
  final VoidCallback onEdited;

  const _SetRow({
    required this.setNumber,
    required this.set,
    required this.unit,
    required this.loadInput,
    required this.onEdited,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightText = set.weight == null
        ? null
        : loadInput == LoadInput.addedWeight
        ? 'BW + ${formatWeightInUnit(set.weight!, unit)}'
        : formatWeightInUnit(set.weight!, unit);
    final measured = set.durationSec != null
        ? formatSetDuration(set.durationSec!)
        : set.distance != null
        ? formatSetDistance(set.distance!)
        : null;
    final parts = <String>[
      // "45s", or "60s @ 40kg" for a loaded hold or carry.
      if (measured != null)
        weightText == null ? measured : '$measured @ $weightText'
      else ...[
        ?weightText,
        if (set.reps != null) '${set.reps} reps',
      ],
      if (set.rpe != null) 'RPE ${set.rpe}',
    ];

    return InkWell(
      onTap: () => _edit(context, ref),
      child: Padding(
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
            const SizedBox(width: 4),
            Icon(
              Icons.edit_outlined,
              size: 16,
              color: Theme.of(context).colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_EditedSetValues>(
      context: context,
      builder: (context) =>
          _EditSetDialog(set: set, unit: unit, loadInput: loadInput),
    );
    if (result == null) return;

    final db = ref.read(appDatabaseProvider);
    await db.sessionLogDao.updateLoggedSet(
      id: set.id,
      reps: result.reps,
      weight: result.weight == null ? null : displayToKg(result.weight!, unit),
      rpe: result.rpe,
      durationSec: result.durationSec,
      distance: result.distance,
    );
    onEdited();
  }
}

class _EditedSetValues {
  final int? reps;
  final double? weight;
  final double? rpe;
  final double? durationSec;
  final double? distance;

  const _EditedSetValues({
    this.reps,
    this.weight,
    this.rpe,
    this.durationSec,
    this.distance,
  });
}

/// Owns its own controllers (disposed in its own `State.dispose()`) rather
/// than ones created inline and disposed after `showDialog` resolves - see
/// this project's own documented dialog-disposal convention for why that
/// races the dialog's exit transition. The counted field follows the set
/// itself: seconds for a timed set, metres for a distance set, reps
/// otherwise.
class _EditSetDialog extends StatefulWidget {
  final LoggedSet set;
  final WeightUnit unit;
  final LoadInput loadInput;

  const _EditSetDialog({
    required this.set,
    required this.unit,
    required this.loadInput,
  });

  @override
  State<_EditSetDialog> createState() => _EditSetDialogState();
}

class _EditSetDialogState extends State<_EditSetDialog> {
  late final TextEditingController _repsController;
  late final TextEditingController _weightController;
  late final TextEditingController _rpeController;
  late final SetMeasure _measure = widget.set.durationSec != null
      ? SetMeasure.time
      : widget.set.distance != null
      ? SetMeasure.distance
      : SetMeasure.reps;

  @override
  void initState() {
    super.initState();
    final set = widget.set;
    final amount = set.durationSec ?? set.distance;
    _repsController = TextEditingController(
      text: amount != null
          ? formatWeightNumber(amount)
          : set.reps?.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: set.weight == null
          ? ''
          : formatWeightNumber(kgToDisplay(set.weight!, widget.unit)),
    );
    _rpeController = TextEditingController(text: set.rpe?.toString() ?? '');
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    _rpeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loadInput = widget.loadInput;
    return AlertDialog(
      title: const Text('Edit set'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _repsController,
            keyboardType: _measure == SetMeasure.reps
                ? TextInputType.number
                : const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: _measure == SetMeasure.reps
                ? integerInputFormatters
                : decimalInputFormatters,
            decoration: InputDecoration(
              labelText: switch (_measure) {
                SetMeasure.reps => 'Reps',
                SetMeasure.time => 'Time (s)',
                SetMeasure.distance => 'Distance (m)',
              },
            ),
          ),
          // Kept for a no-load exercise that somehow has a weight saved, so
          // it can still be corrected - hidden otherwise.
          if (loadInput != LoadInput.none || widget.set.weight != null) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: decimalInputFormatters,
              decoration: InputDecoration(
                labelText: weightFieldLabel(
                  loadInput,
                  lbs: widget.unit == WeightUnit.lbs,
                ),
                hintText: loadInput == LoadInput.addedWeight ? 'BW' : null,
                floatingLabelBehavior: loadInput == LoadInput.addedWeight
                    ? FloatingLabelBehavior.always
                    : null,
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _rpeController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            inputFormatters: decimalInputFormatters,
            decoration: const InputDecoration(labelText: 'RPE'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            _EditedSetValues(
              reps: _measure == SetMeasure.reps
                  ? int.tryParse(_repsController.text.trim())
                  : null,
              durationSec: _measure == SetMeasure.time
                  ? double.tryParse(_repsController.text.trim())
                  : null,
              distance: _measure == SetMeasure.distance
                  ? double.tryParse(_repsController.text.trim())
                  : null,
              weight: double.tryParse(_weightController.text.trim()),
              rpe: double.tryParse(_rpeController.text.trim()),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Owns its controller (see the dialog-disposal convention in CLAUDE.md).
/// Returns the trimmed text; an empty string clears the note.
class _EditNoteDialog extends StatefulWidget {
  final String title;
  final String hint;
  final String initialValue;

  const _EditNoteDialog({
    required this.title,
    required this.hint,
    required this.initialValue,
  });

  @override
  State<_EditNoteDialog> createState() => _EditNoteDialogState();
}

class _EditNoteDialogState extends State<_EditNoteDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: widget.hint,
          border: const OutlineInputBorder(),
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

String _skipSubtitle(SkippedExercise skip) {
  final text = [
    ?SkipReason.fromKey(skip.reason)?.label,
    if (skip.replacedByExerciseName != null)
      'replaced by ${skip.replacedByExerciseName}',
  ].join(', ');
  return text.isEmpty ? 'No reason given' : text;
}
