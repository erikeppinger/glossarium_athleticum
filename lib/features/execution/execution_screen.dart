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
import '../shared/numeric_input_formatters.dart';
import 'rest_timer_controller.dart';

/// Every top set ever logged for one exercise, most recent first - backs the
/// "Best: ..." half of the "Last: ... / Best: ..." line shown while logging
/// that exercise, and reuses [SessionLogDao.getProgressionHistory] rather
/// than a bespoke query since it's already exactly "one row per session,
/// reduced to the top set".
final _exerciseHistoryProvider =
    FutureProvider.family<List<ProgressionHistoryEntry>, String>((
      ref,
      exerciseId,
    ) {
      final db = ref.watch(appDatabaseProvider);
      return db.sessionLogDao.getProgressionHistory(exerciseId);
    });

/// The full "Last: ..." half - every set from only the most recent session,
/// not reduced to one number the way [_exerciseHistoryProvider] is. Someone
/// re-doing an exercise wants to see what they actually did last time
/// (every set), not just its heaviest one.
final _lastSessionSetsProvider =
    FutureProvider.family<List<LoggedSet>, String>((ref, exerciseId) {
      final db = ref.watch(appDatabaseProvider);
      return db.sessionLogDao.getLastLoggedSets(exerciseId);
    });

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
  // Set synchronously the instant "log" is tapped, before the async PR
  // lookup resolves - closes a real race where a fast double-tap on the
  // same row (still showing an enabled check button mid-await) fired two
  // overlapping _logSet calls. Suspected but unconfirmed cause of a
  // user-reported "checking exercises is still inconsistent" report that
  // couldn't be reproduced on demand; hardening this is cheap regardless.
  bool pending = false;

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

/// One plan session's execution-mode progress - every set checked off, every
/// typed-but-unlogged number, which exercises are skipped or added
/// mid-session, all of it. Used to live directly on [_ExecutionScreenState],
/// which meant leaving the screen at all (even just navigating back to a
/// tab and returning) silently threw it all away, contradicting the leave
/// dialog's own promise that "the rest timer keeps running... so you can
/// come back to this session without losing anything" - the timer survived,
/// nothing else did. Held in [_inProgressSessionProvider] instead (plain
/// `Provider.family`, not autoDispose, same "survives navigation" shape as
/// `restTimerControllerProvider`) so a session is only ever actually thrown
/// away by [disposeAll] - finishing successfully, or explicitly choosing
/// "Discard" in the leave dialog. Nothing here is reactive state Riverpod
/// needs to notify anyone about - only [_ExecutionScreenState] itself reads
/// or mutates it, triggering its own rebuilds via `setState` exactly as
/// before, just against an object that outlives the widget instead of one
/// of its fields.
class _InProgressSession {
  final Map<int, List<_LoggedSetForm>> formsByExerciseRowId = {};
  final Map<String, List<double>> priorWeightsByExerciseId = {};
  final Set<int> skippedExerciseRowIds = {};
  bool finishing = false;

  // Exercises added via "Add exercise" mid-session, kept purely in memory -
  // never written to plan_exercises. Adding one used to call
  // PlanDao.addExerciseToSession directly, which permanently added it to the
  // plan's *template*: every future time this session was started (or the
  // plan was viewed), the one-off addition showed up as if it had always
  // been prescribed. A change made while training should only ever apply to
  // that one training, not silently rewrite the plan. Negative, decrementing
  // ids keep these from ever colliding with a real (auto-increment, always
  // positive) plan_exercises.id.
  final List<PlanExercise> adHocExercises = [];
  int nextAdHocExerciseId = -1;

  /// Only ever called on a genuine end - finishing successfully or
  /// discarding - never on a plain navigation-away, which is the entire
  /// point of pulling this out of `State.dispose()`.
  void disposeAll() {
    for (final forms in formsByExerciseRowId.values) {
      for (final f in forms) {
        f.dispose();
      }
    }
  }
}

final _inProgressSessionProvider = Provider.family<_InProgressSession, int>(
  (ref, planSessionId) => _InProgressSession(),
);

enum _LeaveChoice { keepTraining, leave, discard }

class _ExecutionScreenState extends ConsumerState<ExecutionScreen> {
  _InProgressSession get _session =>
      ref.read(_inProgressSessionProvider(widget.planSessionId));

  List<PlanExercise> _allExercises(PlanSessionDetails details) => [
    ...details.exercises,
    ..._session.adHocExercises,
  ];

  // No dispose() override here anymore - the forms' TextEditingControllers
  // are now owned by _InProgressSession, which outlives this State on
  // purpose (see its own doc comment). _InProgressSession.disposeAll() is
  // the only thing that ever disposes them, called from _finishSession and
  // from choosing "Discard" in _confirmDiscard.

  List<_LoggedSetForm> _formsFor(PlanExercise exercise, WeightUnit unit) {
    return _session.formsByExerciseRowId.putIfAbsent(exercise.id, () {
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

  void _addSet(PlanExercise exercise, WeightUnit unit) {
    final forms = _formsFor(exercise, unit);
    setState(() => forms.add(_LoggedSetForm()));
  }

  /// Removes one not-yet-logged set. A logged set must be undone first (via
  /// the existing undo icon) - this keeps "what does removing a set even
  /// mean once it's saved" from being a question at all. Always leaves at
  /// least one row; use "Skip" on the whole exercise for zero sets.
  void _removeSet(PlanExercise exercise, WeightUnit unit, int index) {
    final forms = _formsFor(exercise, unit);
    if (forms.length <= 1 || forms[index].logged) return;
    setState(() => forms.removeAt(index).dispose());
  }

  void _toggleSkip(int exerciseRowId) {
    setState(() {
      if (!_session.skippedExerciseRowIds.remove(exerciseRowId)) {
        _session.skippedExerciseRowIds.add(exerciseRowId);
      }
    });
  }

  Future<void> _addExerciseMidSession(int sessionId) async {
    final library = ref.read(exerciseLookupProvider).valueOrNull;
    if (library == null || !mounted) return;

    final chosen = await showDialog<Exercise>(
      context: context,
      builder: (context) => _ExercisePickerDialog(
        library: library.values.toList()..sort((a, b) => a.name.compareTo(b.name)),
      ),
    );
    if (chosen == null || !mounted) return;

    setState(() {
      _session.adHocExercises.add(
        PlanExercise(
          id: _session.nextAdHocExerciseId--,
          sessionId: sessionId,
          order: 0,
          exerciseId: chosen.id,
          exerciseName: chosen.name,
          sets: 3,
          reps: '8-10',
          weightIntensity: '',
          restSec: 90,
          notes: '',
          videoUrl: '',
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
                    for (final exercise in _allExercises(details))
                      _ExerciseCard(
                        exercise: exercise,
                        forms: _formsFor(exercise, unit),
                        unit: unit,
                        palette: ref.watch(appPreferencesProvider).colorPalette,
                        libraryExercise: ref
                            .watch(exerciseLookupProvider)
                            .valueOrNull?[exercise.exerciseId],
                        skipped: _session.skippedExerciseRowIds.contains(exercise.id),
                        onSetLogged: (form) => _logSet(exercise, form, unit),
                        onSetUnlogged: (form) => _unlogSet(exercise, form, unit),
                        onAddSet: () => _addSet(exercise, unit),
                        onRemoveSet: (index) =>
                            _removeSet(exercise, unit, index),
                        onToggleSkip: () => _toggleSkip(exercise.id),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _addExerciseMidSession(widget.planSessionId),
                      icon: const Icon(Icons.add),
                      label: const Text('Add exercise'),
                    ),
                    const SizedBox(height: 24),
                    // Part of the scrollable list, not a footer pinned
                    // outside it - a footer gets pushed up by
                    // resizeToAvoidBottomInset to sit right above the
                    // on-screen keyboard while a weight/rep field is
                    // focused, close enough to invite an accidental tap
                    // that ends the whole session mid-entry.
                    FilledButton(
                      onPressed: _session.finishing
                          ? null
                          : () => _finishSession(details, unit),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                      child: const Text('Finish session'),
                    ),
                    SizedBox(
                      height: MediaQuery.paddingOf(context).bottom + 16,
                    ),
                  ],
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
  /// starts, so the screen's own successful pop isn't intercepted. Counts
  /// both logged sets and sets with typed-but-unconfirmed numbers - the
  /// latter look just as "entered" to someone glancing at the screen, even
  /// though "Finish session" would otherwise drop them silently (see
  /// _unloggedFilledForms).
  bool get _hasUnsavedSets =>
      !_session.finishing &&
      (_session.formsByExerciseRowId.values.any(
            (forms) => forms.any((f) => f.logged),
          ) ||
          _unloggedFilledForms.isNotEmpty);

  /// Sets where someone typed reps and/or weight but never tapped the
  /// per-set "Log set" check - easy to do, since typing the numbers looks
  /// and feels like the whole job. Without this check, "Finish session"
  /// would silently drop that data with no warning at all.
  List<_LoggedSetForm> get _unloggedFilledForms =>
      _session.formsByExerciseRowId.values
          .expand((forms) => forms)
          .where(
            (f) =>
                !f.logged &&
                (f.reps.text.trim().isNotEmpty ||
                    f.weight.text.trim().isNotEmpty),
          )
          .toList();

  Future<void> _confirmDiscard() async {
    final loggedCount = _session.formsByExerciseRowId.values
        .expand((forms) => forms)
        .where((f) => f.logged)
        .length;
    final unloggedCount = _unloggedFilledForms.length;
    final totalCount = loggedCount + unloggedCount;

    final choice = await showDialog<_LeaveChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave without finishing?'),
        content: Text(
          "You've entered $totalCount set${totalCount == 1 ? '' : 's'} that "
          "haven't been saved yet.\n\n"
          '"Leave" keeps everything exactly as it is, including the rest '
          "timer - start this session again (or tap the timer's own chip) "
          'to pick up right where you left off. "Discard" erases it for '
          'good.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_LeaveChoice.keepTraining),
            child: const Text('Keep training'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_LeaveChoice.leave),
            child: const Text('Leave'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_LeaveChoice.discard),
            child: Text(
              'Discard',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (choice == _LeaveChoice.discard) {
      _session.disposeAll();
      ref.invalidate(_inProgressSessionProvider(widget.planSessionId));
    }
    if ((choice == _LeaveChoice.discard || choice == _LeaveChoice.leave) &&
        mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _logSet(
    PlanExercise exercise,
    _LoggedSetForm form,
    WeightUnit unit, {
    bool startTimer = true,
  }) async {
    if (form.logged || form.pending) return;
    // Flips synchronously, before the DB round-trip below - closes the
    // window where a fast double-tap on the same row (still showing an
    // enabled check button mid-await) could fire two overlapping _logSet
    // calls for the same set.
    setState(() => form.pending = true);

    final db = ref.read(appDatabaseProvider);
    final typedWeight = double.tryParse(form.weight.text);
    final weight = typedWeight == null ? null : displayToKg(typedWeight, unit);

    if (weight != null) {
      final priorWeights = _session.priorWeightsByExerciseId.putIfAbsent(
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

    setState(() {
      form.logged = true;
      form.pending = false;
    });

    if (!startTimer) return;
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
        _session.priorWeightsByExerciseId[key]?.remove(weight);
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
    // Typing reps/weight looks like the whole job, but a set only counts
    // once its own check is tapped (see _unloggedFilledForms) - so anyone
    // who filled numbers in and went straight to "Finish session" would
    // otherwise have all of it silently dropped with no warning at all.
    final unloggedPairs = <(PlanExercise, _LoggedSetForm)>[
      for (final exercise in _allExercises(details))
        if (exercise.exerciseId != null)
          for (final form in _formsFor(exercise, unit))
            if (!form.logged &&
                (form.reps.text.trim().isNotEmpty ||
                    form.weight.text.trim().isNotEmpty))
              (exercise, form),
    ];

    if (unloggedPairs.isNotEmpty) {
      final logThem = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unlogged sets'),
          content: Text(
            '${unloggedPairs.length} set${unloggedPairs.length == 1 ? '' : 's'} '
            "have numbers typed in but weren't logged with the check button. "
            'Log them now and finish, or go back and review them?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Review'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Log & finish'),
            ),
          ],
        ),
      );
      if (logThem != true) return;
      if (!mounted) return;
      for (final (exercise, form) in unloggedPairs) {
        await _logSet(exercise, form, unit, startTimer: false);
      }
      if (!mounted) return;
    }

    setState(() => _session.finishing = true);
    final db = ref.read(appDatabaseProvider);
    final entries = <LoggedSetInput>[];

    for (final exercise in _allExercises(details)) {
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
      final note = await _promptForNote();
      if (!mounted) return;
      await db.sessionLogDao.createSessionLog(
        id: const Uuid().v4(),
        planSessionId: widget.planSessionId,
        loggedAt: DateTime.now(),
        entries: entries,
        notes: note,
      );
      // One-shot FutureProvider - won't notice this write on its own.
      ref.invalidate(loggedPlanSessionIdsProvider);
    }

    // The rest timer is meant to survive leaving this screen unfinished
    // (see _confirmDiscard's own "come back to this session" tip) - but
    // once the session is actually finished there's no next set left to
    // rest before, so a timer left running would just float in the overlay
    // for no reason until it happens to time out on its own. Only stops
    // this session's own timer - if it's since been overwritten by a
    // different session started elsewhere, that one is left alone.
    final restTimer = ref.read(restTimerControllerProvider);
    if (restTimer.planSessionId == widget.planSessionId) {
      ref.read(restTimerControllerProvider.notifier).skip();
    }

    // The session is genuinely over now - free its forms/controllers and
    // drop the cached _InProgressSession, so a later Start on this same
    // plan session begins from a clean slate rather than the just-finished
    // one's leftover (now-persisted) state.
    _session.disposeAll();
    ref.invalidate(_inProgressSessionProvider(widget.planSessionId));

    if (mounted) Navigator.of(context).pop();
  }

  /// Asks for an optional free-text note once there's actually a workout to
  /// attach it to. Barrier-dismissal is disabled so this can't be left
  /// half-answered - "Skip" is the explicit way to decline.
  Future<String?> _promptForNote() async {
    final note = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _NotePromptDialog(),
    );
    return (note == null || note.isEmpty) ? null : note;
  }
}

class _NotePromptDialog extends StatefulWidget {
  const _NotePromptDialog();

  @override
  State<_NotePromptDialog> createState() => _NotePromptDialogState();
}

class _NotePromptDialogState extends State<_NotePromptDialog> {
  // Owned by this State (not created-and-disposed inline in the caller) so
  // dispose() only runs once the dialog route is actually removed from the
  // tree - disposing it right after showDialog's Future resolves raced the
  // dialog's own exit transition, which keeps rebuilding the same TextField
  // for a few frames while it animates out.
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add a note?'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'How did it go? (optional)',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Skip'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ExercisePickerDialog extends StatefulWidget {
  final List<Exercise> library;

  const _ExercisePickerDialog({required this.library});

  @override
  State<_ExercisePickerDialog> createState() => _ExercisePickerDialogState();
}

class _ExercisePickerDialogState extends State<_ExercisePickerDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _query.isEmpty
        ? widget.library
        : widget.library
              .where((e) => e.name.toLowerCase().contains(_query))
              .toList();

    return AlertDialog(
      title: const Text('Add exercise'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: matches.isEmpty
                  ? const Center(child: Text('No matches.'))
                  : ListView.builder(
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final e = matches[index];
                        return ListTile(
                          title: Text(e.name),
                          subtitle: Text(e.category),
                          onTap: () => Navigator.of(context).pop(e),
                        );
                      },
                    ),
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

class _ExerciseCard extends ConsumerWidget {
  final PlanExercise exercise;
  final List<_LoggedSetForm> forms;
  final WeightUnit unit;
  final AppColorPalette palette;
  final Exercise? libraryExercise;
  final bool skipped;
  final void Function(_LoggedSetForm form) onSetLogged;
  final void Function(_LoggedSetForm form) onSetUnlogged;
  final VoidCallback onAddSet;
  final void Function(int index) onRemoveSet;
  final VoidCallback onToggleSkip;

  const _ExerciseCard({
    required this.exercise,
    required this.forms,
    required this.unit,
    required this.palette,
    required this.libraryExercise,
    required this.skipped,
    required this.onSetLogged,
    required this.onSetUnlogged,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onToggleSkip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      decoration: skipped ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onToggleSkip,
                  tooltip: skipped
                      ? 'Include this exercise again'
                      : 'Skip this exercise',
                  icon: Icon(
                    skipped
                        ? Icons.replay
                        : Icons.remove_circle_outline,
                  ),
                ),
              ],
            ),
            Text(
              'Target: ${exercise.sets} x ${exercise.reps}'
              '${exercise.weightIntensity.isEmpty ? '' : ' @ ${exercise.weightIntensity}'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            // A negative id marks an exercise added via "Add exercise"
            // mid-session (see _InProgressSession.adHocExercises) - never
            // written to the plan, so this makes that explicit rather than
            // letting it look identical to a normally-prescribed row.
            if (exercise.id < 0)
              Text(
                'Added for this session only - not saved to the plan.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            if (exercise.exerciseId != null)
              _LastAndBestLine(exerciseId: exercise.exerciseId!, unit: unit),
            if (skipped)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Skipped for this session.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else ...[
              const SizedBox(height: 12),
              for (var i = 0; i < forms.length; i++)
                _SetRow(
                  setNumber: i + 1,
                  form: forms[i],
                  unit: unit,
                  canRemove: forms.length > 1,
                  onLog: () => onSetLogged(forms[i]),
                  onUnlog: () => onSetUnlogged(forms[i]),
                  onRemove: () => onRemoveSet(i),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onAddSet,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add set'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Last: 8×60kg, 7×60kg, 6×55kg · Best: 65kg" - every set from the last
/// time this exercise was actually logged (not reduced to one number - a
/// single "Last: 8 reps @ 60kg" line hid whether that was set 1 of 1 or set
/// 1 of 4), plus the heaviest it's ever been, as a reference point without
/// leaving this screen for the history tab.
class _LastAndBestLine extends ConsumerWidget {
  final String exerciseId;
  final WeightUnit unit;

  const _LastAndBestLine({required this.exerciseId, required this.unit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastSets = ref.watch(_lastSessionSetsProvider(exerciseId)).valueOrNull;
    final history = ref.watch(_exerciseHistoryProvider(exerciseId)).valueOrNull;

    final weightedLastSets =
        lastSets?.where((s) => s.weight != null && s.reps != null).toList() ??
        const [];
    if (weightedLastSets.isEmpty && (history == null || history.isEmpty)) {
      return const SizedBox.shrink();
    }

    final lastText = weightedLastSets.isEmpty
        ? null
        : 'Last: ${weightedLastSets.map((s) => '${s.reps}×${formatWeightInUnit(s.weight!, unit)}').join(', ')}';

    final best = (history == null || history.isEmpty)
        ? null
        : history.reduce((a, b) => a.weight >= b.weight ? a : b);
    final bestText = best == null
        ? null
        : 'Best: ${formatWeightInUnit(best.weight, unit)}';

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        [?lastText, ?bestText].join('  •  '),
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final int setNumber;
  final _LoggedSetForm form;
  final WeightUnit unit;
  final bool canRemove;
  final VoidCallback onLog;
  final VoidCallback onUnlog;
  final VoidCallback onRemove;

  const _SetRow({
    required this.setNumber,
    required this.form,
    required this.unit,
    required this.canRemove,
    required this.onLog,
    required this.onUnlog,
    required this.onRemove,
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
              inputFormatters: integerInputFormatters,
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
              inputFormatters: decimalInputFormatters,
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
              inputFormatters: decimalInputFormatters,
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
          else if (form.pending)
            const SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
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
          if (canRemove && !form.logged && !form.pending)
            IconButton(
              onPressed: onRemove,
              tooltip: 'Remove this set',
              icon: const Icon(Icons.close, size: 18),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
