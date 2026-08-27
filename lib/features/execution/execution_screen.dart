import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../data/daos/plan_dao.dart';
import '../../data/daos/session_log_dao.dart';
import '../../logic/progression.dart';
import '../../logic/rest_timer.dart';
import 'rest_timer_controller.dart';

final _sessionDetailsProvider = FutureProvider.family<PlanSessionDetails?, int>(
  (ref, sessionId) {
    final db = ref.watch(appDatabaseProvider);
    return db.planDao.getSessionDetails(sessionId);
  },
);

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

  List<_LoggedSetForm> _formsFor(PlanExercise exercise) {
    return _formsByExerciseRowId.putIfAbsent(exercise.id, () {
      final weightHint = RegExp(
        r'[\d.]+',
      ).stringMatch(exercise.weightIntensity);
      final repsHint = RegExp(r'^\d+').stringMatch(exercise.reps) ?? '';
      return List.generate(
        exercise.sets,
        (_) => _LoggedSetForm(
          repsHint: repsHint,
          weightHint: weightHint ?? '',
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(_sessionDetailsProvider(widget.planSessionId));
    final restTimer = ref.watch(restTimerControllerProvider);

    return Scaffold(
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
                        forms: _formsFor(exercise),
                        onSetLogged: (form) => _logSet(exercise, form),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: _finishing ? null : () => _finishSession(details),
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
    );
  }

  Future<void> _logSet(PlanExercise exercise, _LoggedSetForm form) async {
    final db = ref.read(appDatabaseProvider);
    final weight = double.tryParse(form.weight.text);

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
    );
  }

  Future<void> _finishSession(PlanSessionDetails details) async {
    setState(() => _finishing = true);
    final db = ref.read(appDatabaseProvider);
    final entries = <LoggedSetInput>[];

    for (final exercise in details.exercises) {
      if (exercise.exerciseId == null) continue;
      final forms = _formsFor(exercise);
      for (var i = 0; i < forms.length; i++) {
        final form = forms[i];
        if (!form.logged) continue;
        entries.add(
          LoggedSetInput(
            exerciseId: exercise.exerciseId!,
            setNumber: i + 1,
            reps: int.tryParse(form.reps.text),
            weight: double.tryParse(form.weight.text),
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
  final void Function(_LoggedSetForm form) onSetLogged;

  const _ExerciseCard({
    required this.exercise,
    required this.forms,
    required this.onSetLogged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.exerciseName,
              style: Theme.of(context).textTheme.titleMedium,
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
                onLog: () => onSetLogged(forms[i]),
              ),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatefulWidget {
  final int setNumber;
  final _LoggedSetForm form;
  final VoidCallback onLog;

  const _SetRow({
    required this.setNumber,
    required this.form,
    required this.onLog,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  @override
  Widget build(BuildContext context) {
    final form = widget.form;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('${widget.setNumber}')),
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
              decoration: const InputDecoration(labelText: 'Weight'),
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
            Icon(
              form.isPr ? Icons.emoji_events : Icons.check_circle,
              color: form.isPr ? Colors.amber.shade700 : Colors.green,
            )
          else
            IconButton.filled(
              onPressed: () {
                widget.onLog();
                setState(() {});
              },
              icon: const Icon(Icons.check),
              tooltip: 'Log set',
            ),
        ],
      ),
    );
  }
}
