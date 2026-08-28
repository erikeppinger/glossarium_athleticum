import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../data/daos/plan_dao.dart';
import '../../data/daos/session_log_dao.dart';
import '../../logic/progression.dart';
import '../../logic/rest_timer.dart';
import '../../logic/muscle_group_colors.dart';
import '../../logic/units.dart';
import '../calendar/calendar_screen.dart';
import '../settings/app_preferences.dart';
import '../shared/muscle_area_stripe.dart';
import 'rest_timer_controller.dart';

final _sessionDetailsProvider = FutureProvider.family<PlanSessionDetails?, int>(
  (ref, sessionId) {
    final db = ref.watch(appDatabaseProvider);
    return db.planDao.getSessionDetails(sessionId);
  },
);

/// Library rows keyed by id - a plan exercise stores only a name and an id,
/// so the muscle-area colour has to come from the library entry behind it.
final exerciseLookupProvider = FutureProvider<Map<String, Exercise>>((
  ref,
) async {
  final db = ref.watch(appDatabaseProvider);
  final all = await db.exerciseDao.getAllExercises();
  return {for (final e in all) e.id: e};
});

/// Execution mode: mobile-optimized session logging, distinct from the
/// desktop-oriented "creation mode" (Phase 7). Large touch targets, one
/// screen per session with every set logged inline plus a rest timer.
class ExecutionScreen extends ConsumerStatefulWidget {
  final int planSessionId;

  const ExecutionScreen({super.key, required this.planSessionId});

  @override
  ConsumerState<ExecutionScreen> createState() => _ExecutionScreenState();
}

class _LoggedSetForm {
  final TextEditingController reps;
  final TextEditingController weight;
  final TextEditingController rpe;
  bool logged = false;
  bool isPr = false;

  _LoggedSetForm({String repsHint = '', String weightHint = ''})
    : reps = TextEditingController(text: repsHint),
      weight = TextEditingController(text: weightHint),
      rpe = TextEditingController();

  void dispose() {
    reps.dispose();
    weight.dispose();
    rpe.dispose();
  }
}

class _ExecutionScreenState extends ConsumerState<ExecutionScreen> {
  final Map<int, List<_LoggedSetForm>> _formsByExerciseRowId = {};
  final Map<String, List<double>> _priorWeightsByExerciseId = {};
  bool _finishing = false;

  @override
  void dispose() {
    for (final forms in _formsByExerciseRowId.values) {
      for (final f in forms) {
        f.dispose();
      }
    }
    super.dispose();
  }

  List<_LoggedSetForm> _formsFor(PlanExercise exercise, WeightUnit unit) {
    return _formsByExerciseRowId.putIfAbsent(exercise.id, () {
      final weightHintKg = double.tryParse(
        RegExp(r'[\d.]+').stringMatch(exercise.weightIntensity) ?? '',
      );
      final weightHint = weightHintKg == null
          ? ''
          : formatWeightNumber(kgToDisplay(weightHintKg, unit));
      final repsHint = RegExp(r'^\d+').stringMatch(exercise.reps) ?? '';
      return List.generate(
        exercise.sets,
        (_) => _LoggedSetForm(
          repsHint: repsHint,
          weightHint: weightHint,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(_sessionDetailsProvider(widget.planSessionId));
    final restTimer = ref.watch(restTimerControllerProvider);
    final unit = ref.watch(appPreferencesProvider).weightUnit;

    return PopScope(
      // Sets live in memory until "Finish session", so backing out silently
      // discards them. That mattered less before the floating rest timer -
      // which now actively encourages leaving the screen mid-session.
      canPop: !_hasUnsavedSets,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
      appBar: AppBar(title: const Text('Log session')),
      body: detailsAsync.when(
        data: (details) {
          if (details == null) {
            return const Center(child: Text('Session not found.'));
          }
          return Column(
            children: [
              if (restTimer.isRunning) _RestTimerBanner(state: restTimer),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      '${details.session.sessionName} • Week ${details.session.weekNumber} • ${details.session.day}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    for (final exercise in details.exercises)
                      _ExerciseCard(
                        exercise: exercise,
                        forms: _formsFor(exercise, unit),
                        unit: unit,
                        palette: ref.watch(appPreferencesProvider).colorPalette,
                        libraryExercise: ref
                            .watch(exerciseLookupProvider)
                            .valueOrNull?[exercise.exerciseId],
                        onSetLogged: (form) => _logSet(exercise, form, unit),
                        onSetUnlogged: (form) => _unlogSet(exercise, form, unit),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: _finishing ? null : () => _finishSession(details, unit),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                    child: const Text('Finish session'),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      ),
    );
  }

  /// Whether anything would be lost by leaving now. False once _finishing
  /// starts, so the screen's own successful pop isn't intercepted.
  bool get _hasUnsavedSets =>
      !_finishing &&
      _formsByExerciseRowId.values.any((forms) => forms.any((f) => f.logged));

  Future<void> _confirmDiscard() async {
    final loggedCount = _formsByExerciseRowId.values
        .expand((forms) => forms)
        .where((f) => f.logged)
        .length;

    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave without finishing?'),
        content: Text(
          "You've logged $loggedCount set${loggedCount == 1 ? '' : 's'} that "
          "haven't been saved yet. Leaving now discards them.\n\n"
          'Tip: the rest timer keeps running if you switch tabs, so you can '
          'come back to this session without losing anything.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep training'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Discard',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (discard == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _logSet(
    PlanExercise exercise,
    _LoggedSetForm form,
    WeightUnit unit,
  ) async {
    final db = ref.read(appDatabaseProvider);
    final typedWeight = double.tryParse(form.weight.text);
    final weight = typedWeight == null ? null : displayToKg(typedWeight, unit);

    if (weight != null) {
      final priorWeights = _priorWeightsByExerciseId.putIfAbsent(
        exercise.exerciseId ?? exercise.exerciseName,
        () => [],
      );
      final priorFromDb = exercise.exerciseId == null
          ? const <double>[]
          : await db.sessionLogDao.getPriorWeights(exercise.exerciseId!);
      final allPrior = [...priorFromDb, ...priorWeights];
      form.isPr = isPersonalRecord(weight, allPrior);
      if (form.isPr) priorWeights.add(weight);
    }

    setState(() => form.logged = true);

    final restSec = exercise.restSec ?? 90;
    ref.read(restTimerControllerProvider.notifier).start(
      Duration(seconds: restSec),
      planSessionId: widget.planSessionId,
    );
  }

  /// Reverts a mis-tapped or mis-typed set back to editable, before
  /// "Finish session" writes anything - nothing's persisted yet, so this is
  /// purely in-memory. Also un-counts it from this session's own PR
  /// tracking, so a later set of the same exercise isn't compared against a
  /// PR that got undone.
  void _unlogSet(PlanExercise exercise, _LoggedSetForm form, WeightUnit unit) {
    if (form.isPr) {
      final typedWeight = double.tryParse(form.weight.text);
      if (typedWeight != null) {
        final weight = displayToKg(typedWeight, unit);
        final key = exercise.exerciseId ?? exercise.exerciseName;
        _priorWeightsByExerciseId[key]?.remove(weight);
      }
    }
    setState(() {
      form.logged = false;
      form.isPr = false;
    });
  }

  Future<void> _finishSession(
    PlanSessionDetails details,
    WeightUnit unit,
  ) async {
    setState(() => _finishing = true);
    final db = ref.read(appDatabaseProvider);
    final entries = <LoggedSetInput>[];

    for (final exercise in details.exercises) {
      if (exercise.exerciseId == null) continue;
      final forms = _formsFor(exercise, unit);
      for (var i = 0; i < forms.length; i++) {
        final form = forms[i];
        if (!form.logged) continue;
        final typedWeight = double.tryParse(form.weight.text);
        entries.add(
          LoggedSetInput(
            exerciseId: exercise.exerciseId!,
            setNumber: i + 1,
            reps: int.tryParse(form.reps.text),
            weight: typedWeight == null
                ? null
                : displayToKg(typedWeight, unit),
            rpe: double.tryParse(form.rpe.text),
            isPr: form.isPr,
          ),
        );
      }
    }

    if (entries.isNotEmpty) {
      await db.sessionLogDao.createSessionLog(
        id: const Uuid().v4(),
        planSessionId: widget.planSessionId,
        loggedAt: DateTime.now(),
        entries: entries,
      );
      // One-shot FutureProvider - won't notice this write on its own.
      ref.invalidate(loggedPlanSessionIdsProvider);
    }

    if (mounted) Navigator.of(context).pop();
  }
}

class _RestTimerBanner extends ConsumerWidget {
  final RestTimerState state;

  const _RestTimerBanner({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = state.remaining ?? Duration.zero;
    final progress = state.total.inMilliseconds == 0
        ? 0.0
        : 1 - (remaining.inMilliseconds / state.total.inMilliseconds);
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(
              'Rest: ${formatRestTime(remaining)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LinearProgressIndicator(value: progress.clamp(0, 1)),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () =>
                  ref.read(restTimerControllerProvider.notifier).skip(),
              child: const Text('Skip'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final PlanExercise exercise;
  final List<_LoggedSetForm> forms;
  final WeightUnit unit;
  final AppColorPalette palette;
  final Exercise? libraryExercise;
  final void Function(_LoggedSetForm form) onSetLogged;
  final void Function(_LoggedSetForm form) onSetUnlogged;

  const _ExerciseCard({
    required this.exercise,
    required this.forms,
    required this.unit,
    required this.palette,
    required this.libraryExercise,
    required this.onSetLogged,
    required this.onSetUnlogged,
  });

  @override
  Widget build(BuildContext context) {
    final area = areaForExercise(
      muscleGroups: libraryExercise?.muscleGroups ?? '',
      category: libraryExercise?.category ?? '',
      movementPattern: libraryExercise?.movementPattern ?? '',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MuscleAreaStripe(area: area, palette: palette, height: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    exercise.exerciseName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            Text(
              'Target: ${exercise.sets} x ${exercise.reps}'
              '${exercise.weightIntensity.isEmpty ? '' : ' @ ${exercise.weightIntensity}'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < forms.length; i++)
              _SetRow(
                setNumber: i + 1,
                form: forms[i],
                unit: unit,
                onLog: () => onSetLogged(forms[i]),
                onUnlog: () => onSetUnlogged(forms[i]),
              ),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final int setNumber;
  final _LoggedSetForm form;
  final WeightUnit unit;
  final VoidCallback onLog;
  final VoidCallback onUnlog;

  const _SetRow({
    required this.setNumber,
    required this.form,
    required this.unit,
    required this.onLog,
    required this.onUnlog,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('$setNumber')),
          Expanded(
            child: TextField(
              controller: form.reps,
              enabled: !form.logged,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Reps'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: form.weight,
              enabled: !form.logged,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: unit == WeightUnit.lbs ? 'Weight (lbs)' : 'Weight (kg)',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: form.rpe,
              enabled: !form.logged,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'RPE'),
            ),
          ),
          const SizedBox(width: 8),
          if (form.logged)
            IconButton(
              onPressed: onUnlog,
              tooltip: 'Undo - edit this set again',
              icon: Icon(
                form.isPr ? Icons.emoji_events : Icons.check_circle,
                color: form.isPr ? Colors.amber.shade700 : Colors.green,
              ),
            )
          else
            IconButton.filled(
              // onLog (-> _logSet) calls its own setState once form.logged
              // actually flips to true - forcing a second, redundant
              // rebuild here (before that state change lands, since onLog
              // isn't awaited) only risked painting a stale frame.
              onPressed: onLog,
              icon: const Icon(Icons.check),
              tooltip: 'Log set',
            ),
        ],
      ),
    );
  }
}
