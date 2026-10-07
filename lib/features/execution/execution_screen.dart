import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../data/daos/plan_dao.dart';
import '../../data/daos/session_log_dao.dart';
import '../../logic/percentage_prescription.dart';
import '../../logic/progression.dart';
import '../../logic/load_input.dart';
import '../../logic/rest_timer.dart';
import '../../logic/set_measure.dart';
import '../../logic/muscle_group_colors.dart';
import '../../logic/skip_reason.dart';
import '../../logic/superset_info.dart';
import '../../logic/week_label.dart';
import '../../logic/units.dart';
import '../calendar/calendar_screen.dart';
import '../plans/plan_providers.dart';
import '../progress/progress_providers.dart';
import '../settings/app_preferences.dart';
import '../shared/info_dialog.dart';
import '../shared/muscle_area_stripe.dart';
import '../shared/numeric_input_formatters.dart';
import '../shared/pulsing_highlight.dart';
import '../tools/plate_calculator_screen.dart';
import 'rest_timer_controller.dart';

/// The full "Last: ..." half - every set from only the most recent session,
/// not reduced to one number the way [exerciseProgressionHistoryProvider] is.
/// Someone re-doing an exercise wants to see what they actually did last time
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

  /// Seconds for a [SetMeasure.time] set, metres for a distance set -
  /// shown instead of [reps] for those.
  final TextEditingController amount;
  final SetMeasure measure;

  /// The prescribed seconds or metres, if any - the hold timer buzzes once
  /// it's reached.
  final double? target;

  /// Set while the hold timer is running for this set.
  DateTime? timerStartedAt;
  bool targetAnnounced = false;

  bool logged = false;
  bool isPr = false;
  // Set synchronously the instant "log" is tapped, before the async PR
  // lookup resolves - closes a real race where a fast double-tap on the
  // same row (still showing an enabled check button mid-await) fired two
  // overlapping _logSet calls. Suspected but unconfirmed cause of a
  // user-reported "checking exercises is still inconsistent" report that
  // couldn't be reproduced on demand; hardening this is cheap regardless.
  bool pending = false;

  _LoggedSetForm({
    this.measure = SetMeasure.reps,
    this.target,
    String repsHint = '',
    String weightHint = '',
  }) : reps = TextEditingController(text: repsHint),
       weight = TextEditingController(text: weightHint),
       rpe = TextEditingController(),
       amount = TextEditingController(
         text: target == null ? '' : _formatAmount(target),
       );

  /// Another empty row for the same exercise ("+ Add set").
  _LoggedSetForm sibling() => _LoggedSetForm(measure: measure, target: target);

  /// Whether the counted field holds anything - reps, or the seconds or
  /// metres for a timed or distance set.
  bool get hasCountEntered => measure == SetMeasure.reps
      ? reps.text.trim().isNotEmpty
      : amount.text.trim().isNotEmpty;

  void dispose() {
    reps.dispose();
    weight.dispose();
    rpe.dispose();
    amount.dispose();
  }
}

String _formatAmount(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : '$value';

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

  /// Trainee-to-trainer feedback on one exercise in this session (e.g.
  /// "left shoulder felt off"), keyed by the plan-exercise row id - see
  /// `LoggedSets.notes`' own doc comment for why this is attached to that
  /// exercise's first logged set rather than living in its own table.
  final Map<int, String> notesByExerciseRowId = {};

  /// Why each skipped plan exercise was skipped, if a reason was picked.
  final Map<int, SkipReason> skipReasonByExerciseRowId = {};

  /// Skipped plan-exercise row id -> the ad-hoc row done in its place. The
  /// substitute renders right after the exercise it replaces.
  final Map<int, int> substituteRowIdBySkippedRowId = {};

  /// Ad-hoc row id -> the earlier skip it was added to make up.
  final Map<int, PendingMakeUp> makeUpByAdHocRowId = {};

  /// Queued make-ups waved off with "Not today" for this session only.
  final Set<int> hiddenMakeUpIds = {};

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

/// The weight input for [exercise], from its library entry ([library] is
/// null for an exercise missing from the library) and its prescription.
LoadInput _loadInputFor(PlanExercise exercise, Exercise? library) =>
    loadInputFor(
      equipment: library?.equipment ?? '',
      category: library?.category ?? '',
      measurementType: library?.measurementType ?? '',
      prescribedWeight: exercise.weightIntensity,
    );

/// The plan's exercises with any substitute placed directly after the
/// exercise it replaces, then every other mid-session addition (plain
/// additions and make-ups) at the end.
List<PlanExercise> _allExercisesFor(
  _InProgressSession session,
  PlanSessionDetails details,
) {
  final adHocById = {for (final e in session.adHocExercises) e.id: e};
  final substituteIds = session.substituteRowIdBySkippedRowId.values.toSet();
  return [
    for (final exercise in details.exercises) ...[
      exercise,
      ?adHocById[session.substituteRowIdBySkippedRowId[exercise.id]],
    ],
    for (final exercise in session.adHocExercises)
      if (!substituteIds.contains(exercise.id)) exercise,
  ];
}

/// The plan exercises skipped so far, in the shape `createSessionLog`
/// stores. A substitute only counts as a replacement once at least one of
/// its sets was logged - picking one and never doing it is just a skip.
List<SkippedExerciseInput> _skippedEntriesFor(
  _InProgressSession session,
  PlanSessionDetails details,
) {
  final adHocById = {for (final e in session.adHocExercises) e.id: e};
  final result = <SkippedExerciseInput>[];
  for (final exercise in details.exercises) {
    if (exercise.exerciseId == null ||
        !session.skippedExerciseRowIds.contains(exercise.id)) {
      continue;
    }
    final substitute =
        adHocById[session.substituteRowIdBySkippedRowId[exercise.id]];
    final substituteDone =
        substitute != null &&
        (session.formsByExerciseRowId[substitute.id] ?? const [])
            .any((f) => f.logged);
    result.add(
      SkippedExerciseInput(
        exerciseId: exercise.exerciseId!,
        exerciseName: exercise.exerciseName,
        prescribedSets: exercise.sets,
        prescribedReps: exercise.reps,
        prescribedWeightIntensity: exercise.weightIntensity,
        prescribedRestSec: exercise.restSec,
        reason: session.skipReasonByExerciseRowId[exercise.id]?.key,
        replacedByExerciseId: substituteDone ? substitute.exerciseId : null,
        replacedByExerciseName: substituteDone ? substitute.exerciseName : null,
      ),
    );
  }
  return result;
}

/// One item to render in execution mode's exercise list - either a plain
/// solo exercise, or a superset/circuit of 2+ exercises sharing a
/// `supersetGroupId` (see [_groupedExercisesFor]).
sealed class _RenderUnit {}

class _SoloUnit extends _RenderUnit {
  final PlanExercise exercise;
  _SoloUnit(this.exercise);
}

class _SupersetUnit extends _RenderUnit {
  /// Sorted by `order` - determines both round-robin display order and
  /// which member is "last" in a given round for the rest-timer trigger.
  final List<PlanExercise> members;
  _SupersetUnit(this.members);
}

/// Clusters [exercises] by `supersetGroupId`, preserving each item's
/// original position for anything not (or no longer meaningfully) grouped.
/// A group is emitted once, at the position of its first member in
/// [exercises] - a group that's shrunk to a single remaining member (e.g.
/// after ungrouping the others) renders as a plain solo card, matching
/// execution mode having no "one-exercise superset" concept. Ad-hoc
/// mid-session additions are never grouped (their `supersetGroupId` is
/// always null), so they always come through as solo units.
List<_RenderUnit> _groupedExercisesFor(List<PlanExercise> exercises) {
  final membersByGroup = <int, List<PlanExercise>>{};
  for (final exercise in exercises) {
    final groupId = exercise.supersetGroupId;
    if (groupId != null) {
      membersByGroup.putIfAbsent(groupId, () => []).add(exercise);
    }
  }

  final emittedGroups = <int>{};
  final result = <_RenderUnit>[];
  for (final exercise in exercises) {
    final groupId = exercise.supersetGroupId;
    if (groupId == null) {
      result.add(_SoloUnit(exercise));
      continue;
    }
    if (!emittedGroups.add(groupId)) continue;
    final members = membersByGroup[groupId]!
      ..sort((a, b) => a.order.compareTo(b.order));
    result.add(
      members.length < 2 ? _SoloUnit(members.single) : _SupersetUnit(members),
    );
  }
  return result;
}

/// Every set actually checked off so far in [session], in the shape both
/// [autosaveInProgressSessionDraft] and `_ExecutionScreenState._finishSession`
/// need. Ad-hoc exercises added mid-session are deliberately excluded from
/// drafts (though they still count normally at a real Finish) - restoring
/// them after a cold start would mean reconstructing a whole synthetic
/// `PlanExercise` with guessed sets/reps, not just refilling forms that
/// already exist from the plan.
List<LoggedSetInput> _loggedEntriesFor(
  _InProgressSession session,
  PlanSessionDetails details,
  WeightUnit unit,
) {
  final entries = <LoggedSetInput>[];
  for (final exercise in _allExercisesFor(session, details)) {
    if (exercise.exerciseId == null) continue;
    final forms = session.formsByExerciseRowId[exercise.id];
    if (forms == null) continue;
    final note = session.notesByExerciseRowId[exercise.id];
    var noteAttached = false;
    for (var i = 0; i < forms.length; i++) {
      final form = forms[i];
      if (!form.logged) continue;
      final typedWeight = double.tryParse(form.weight.text);
      final amount = double.tryParse(form.amount.text);
      entries.add(
        LoggedSetInput(
          exerciseId: exercise.exerciseId!,
          setNumber: i + 1,
          reps: form.measure == SetMeasure.reps
              ? int.tryParse(form.reps.text)
              : null,
          durationSec: form.measure == SetMeasure.time ? amount : null,
          distance: form.measure == SetMeasure.distance ? amount : null,
          weight: typedWeight == null
              ? null
              : displayToKg(typedWeight, unit),
          rpe: double.tryParse(form.rpe.text),
          isPr: form.isPr,
          // Attached to whichever logged set for this exercise comes first
          // in the saved list, regardless of its literal set number - the
          // note is about the exercise as a whole, and there's no separate
          // per-exercise row to hang it off instead (see LoggedSets.notes).
          notes: (!noteAttached && note != null && note.isNotEmpty)
              ? note
              : null,
        ),
      );
      noteAttached = true;
    }
  }
  return entries;
}

/// Autosaves whatever's been checked off so far for [planSessionId]'s
/// in-progress session, if there is one - called from `home_screen.dart`'s
/// own always-mounted app-lifecycle observer rather than from
/// `ExecutionScreen` itself (see that observer's doc comment for why: a
/// session left via `_LeaveChoice.leave` needs exactly the same safety net
/// while sitting on a different tab, and `ExecutionScreen`'s own lifecycle
/// observer stops receiving callbacks the instant its route is popped, even
/// though the in-memory `_InProgressSession` deliberately survives being
/// left). Reads `_inProgressSessionProvider` directly rather than via
/// `_sessionDetailsProvider`'s cache, since this can run long after
/// `ExecutionScreen` itself has unmounted.
Future<void> autosaveInProgressSessionDraft(
  WidgetRef ref,
  int planSessionId,
) async {
  final db = ref.read(appDatabaseProvider);
  final details = await db.planDao.getSessionDetails(planSessionId);
  if (details == null) return;
  final session = ref.read(_inProgressSessionProvider(planSessionId));
  final unit = ref.read(appPreferencesProvider).weightUnit;
  await db.sessionLogDao.saveDraft(
    planSessionId: planSessionId,
    loggedAt: DateTime.now(),
    entries: _loggedEntriesFor(session, details, unit),
  );
}

enum _LeaveChoice { keepTraining, leave, discard }

class _ExecutionScreenState extends ConsumerState<ExecutionScreen> {
  _InProgressSession get _session =>
      ref.read(_inProgressSessionProvider(widget.planSessionId));

  // Guards _restoreDraftIfAny so it only ever runs once per screen instance,
  // the first time session details resolve - see its own doc comment.
  bool _draftRestoreAttempted = false;

  @override
  void initState() {
    super.initState();
    // Deferred to after the first frame - same reasoning as home_screen.dart's
    // own post-frame provider writes, since mutating a provider synchronously
    // during initState can race the widget tree still being built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(activeInProgressSessionIdProvider.notifier).state =
          widget.planSessionId;
      ref.read(executionScreenVisibleProvider.notifier).state = true;
      ref.read(executionScreenCloseGuardProvider.notifier).state =
          _handleCloseRequest;
      // A hold started before leaving the screen keeps counting from its
      // own start time - just resume the ticker that redraws it.
      _syncHoldTicker();
    });
  }

  /// Clears [executionScreenVisibleProvider] the instant this screen's route
  /// actually pops - called from `build()`'s `PopScope.onPopInvokedWithResult`
  /// (every removal path - system back with `canPop` true, `_confirmDiscard`'s
  /// Leave/Discard, and `_finishSession`'s own pop - routes through popping
  /// this same PopScope's route) rather than from `dispose()`: Riverpod
  /// throws "Cannot use ref after the widget was disposed" from inside
  /// `dispose()` unconditionally in this version, confirmed live - there's no
  /// safe way to read/write a provider there at all, not just during a bulk
  /// tree teardown. `onPopInvokedWithResult` fires while the widget is still
  /// fully mounted, before disposal, so `ref` is fine here.
  void _clearExecutionScreenVisible() {
    ref.read(executionScreenVisibleProvider.notifier).state = false;
    // Guarded the same way _confirmDiscard's own cleanup is: a *different*
    // ExecutionScreen could conceivably have been pushed and registered its
    // own guard in between (e.g. tapping the rest-timer chip to jump into a
    // different session before this one's pop callback ran) - only clear the
    // guard if it's still this screen's own closure.
    if (ref.read(executionScreenCloseGuardProvider) == _handleCloseRequest) {
      ref.read(executionScreenCloseGuardProvider.notifier).state = null;
    }
  }

  // Backgrounding-triggered draft autosaving now happens in
  // home_screen.dart's own always-mounted app-lifecycle observer instead of
  // here - see autosaveInProgressSessionDraft's doc comment for why a
  // per-screen observer isn't enough (it stops receiving callbacks the
  // instant this screen is popped via "Leave," even though the in-memory
  // session it would have autosaved deliberately survives that).

  /// Every set actually checked off so far, in the shape [_finishSession]
  /// needs (see [_loggedEntriesFor], shared with
  /// [autosaveInProgressSessionDraft]).
  List<LoggedSetInput> _loggedEntries(
    PlanSessionDetails details,
    WeightUnit unit,
  ) => _loggedEntriesFor(_session, details, unit);

  /// Restores a previously autosaved draft's checked-off sets (see
  /// autosaveInProgressSessionDraft above) - only relevant after a cold start
  /// following a process kill, where _inProgressSessionProvider itself is
  /// gone along with everything else in memory. A no-op whenever forms are
  /// already populated (the normal case: reopening a screen whose
  /// _InProgressSession survived, or a session with no draft at all), so
  /// this can never clobber live in-progress work.
  Future<void> _restoreDraftIfAny(
    PlanSessionDetails details,
    WeightUnit unit,
  ) async {
    // Not `formsByExerciseRowId.isEmpty`, and not the forms' text fields
    // either - by the time this postFrameCallback runs, build() has already
    // called _formsFor for every exercise on the same frame, which lazily
    // creates a form for each one purely to render the screen, *pre-filled*
    // with a hint straight from the exercise's own prescription (see
    // _formsFor's repsHint/weightHint) - not something the user typed. The
    // only reliable signs of genuine, worth-preserving in-progress activity
    // (from a *live* session that survived normal in-app navigation, e.g.
    // choosing "Leave" and reopening the same screen) are an actually
    // logged set, a skipped exercise, or a mid-session addition.
    final hasRealActivity =
        _session.formsByExerciseRowId.values.any(
          (forms) => forms.any((f) => f.logged),
        ) ||
        _session.skippedExerciseRowIds.isNotEmpty ||
        _session.adHocExercises.isNotEmpty;
    if (hasRealActivity) return;
    final db = ref.read(appDatabaseProvider);
    final draftSets = await db.sessionLogDao.getDraftSets(
      widget.planSessionId,
    );
    if (draftSets.isEmpty || !mounted) return;

    final bySetKey = <String, LoggedSet>{
      for (final s in draftSets) '${s.exerciseId}#${s.setNumber}': s,
    };
    setState(() {
      for (final exercise in details.exercises) {
        if (exercise.exerciseId == null) continue;
        final forms = _formsFor(exercise, unit);
        // _formsFor only ever creates as many forms as the plan's own
        // prescription (exercise.sets) - a set added manually via "+ Add
        // set" beyond that, if checked off before the process was killed,
        // has a draft entry with a setNumber past forms.length, which the
        // restore loop below would silently never reach at all. Reported
        // live (2026-09-10): a manually-added 4th set that had been logged
        // vanished entirely on restore instead of coming back checked off.
        final maxDraftedSetNumber = draftSets
            .where((s) => s.exerciseId == exercise.exerciseId)
            .fold(0, (max, s) => s.setNumber > max ? s.setNumber : max);
        while (forms.length < maxDraftedSetNumber) {
          forms.add(forms.last.sibling());
        }
        for (var i = 0; i < forms.length; i++) {
          final match = bySetKey['${exercise.exerciseId}#${i + 1}'];
          if (match == null) continue;
          final form = forms[i];
          if (match.reps != null) form.reps.text = match.reps.toString();
          final amount = match.durationSec ?? match.distance;
          if (amount != null) form.amount.text = _formatAmount(amount);
          if (match.weight != null) {
            form.weight.text = formatWeightNumber(
              kgToDisplay(match.weight!, unit),
            );
          }
          if (match.rpe != null) form.rpe.text = match.rpe.toString();
          form.logged = true;
          form.isPr = match.isPr;
        }
      }
    });
  }

  List<PlanExercise> _allExercises(PlanSessionDetails details) =>
      _allExercisesFor(_session, details);

  /// A percentage prescription ("70%") resolved against the exercise's
  /// current best estimated 1RM - null when this isn't a percentage
  /// prescription, or when there's no logged history to resolve against
  /// yet (see `_ExerciseCard._weightIntensitySuffix`'s fallback text for
  /// the latter case).
  double? _resolvedPercentageWeightKg(PlanExercise exercise) {
    final exerciseId = exercise.exerciseId;
    if (exerciseId == null ||
        !isPercentagePrescription(exercise.weightIntensity)) {
      return null;
    }
    final percent = parsePercentage(exercise.weightIntensity);
    if (percent == null) return null;
    final estimatedOneRepMaxKg = ref
        .watch(estimatedOneRepMaxProvider(exerciseId))
        .valueOrNull;
    return resolvePercentageWeight(
      percent: percent,
      estimatedOneRepMaxKg: estimatedOneRepMaxKg,
    );
  }

  /// Bundles one superset member's data/callbacks for [_SupersetCard],
  /// mirroring the same per-exercise wiring the solo `_ExerciseCard` gets
  /// directly in `build()`'s loop.
  _SupersetMember _memberFor(PlanExercise exercise, WeightUnit unit) {
    final resolvedWeightKg = _resolvedPercentageWeightKg(exercise);
    return _SupersetMember(
      exercise: exercise,
      forms: _formsFor(
        exercise,
        unit,
        percentageResolvedWeightKg: resolvedWeightKg,
      ),
      resolvedWeightKg: resolvedWeightKg,
      libraryExercise: ref
          .watch(exerciseLookupProvider)
          .valueOrNull?[exercise.exerciseId],
      skipped: _session.skippedExerciseRowIds.contains(exercise.id),
      skipLabel: _skipLabel(exercise),
      onSetLogged: (form, {required startTimer}) =>
          _logSet(exercise, form, unit, startTimer: startTimer),
      onSetUnlogged: (form) => _unlogSet(exercise, form, unit),
      onAddSet: () => _addSet(exercise, unit),
      onRemoveSet: (index) => _removeSet(exercise, unit, index),
      onToggleSkip: () => _toggleSkip(exercise),
      onToggleTimer: _toggleHoldTimer,
    );
  }

  /// Redraws running hold timers. Like the rest timer, the elapsed time is
  /// always recomputed from each set's own start time, so a missed or late
  /// tick costs nothing.
  Timer? _holdTicker;

  Iterable<_LoggedSetForm> get _runningHoldTimers => _session
      .formsByExerciseRowId
      .values
      .expand((forms) => forms)
      .where((f) => f.timerStartedAt != null);

  void _syncHoldTicker() {
    if (_runningHoldTimers.isEmpty) {
      _holdTicker?.cancel();
      _holdTicker = null;
    } else {
      _holdTicker ??= Timer.periodic(
        const Duration(milliseconds: 250),
        (_) => _onHoldTick(),
      );
    }
  }

  void _onHoldTick() {
    if (!mounted) return;
    setState(() {
      for (final form in _runningHoldTimers) {
        final seconds = DateTime.now()
            .difference(form.timerStartedAt!)
            .inSeconds;
        form.amount.text = '$seconds';
        final target = form.target;
        if (target != null && !form.targetAnnounced && seconds >= target) {
          form.targetAnnounced = true;
          HapticFeedback.vibrate();
        }
      }
    });
  }

  void _toggleHoldTimer(_LoggedSetForm form) {
    setState(() {
      if (form.timerStartedAt != null) {
        _stopHoldTimer(form);
      } else {
        form.timerStartedAt = DateTime.now();
        form.targetAnnounced = false;
        form.amount.text = '0';
      }
    });
    _syncHoldTicker();
  }

  /// Freezes the elapsed seconds into the field.
  void _stopHoldTimer(_LoggedSetForm form) {
    final started = form.timerStartedAt;
    if (started == null) return;
    form.amount.text = '${DateTime.now().difference(started).inSeconds}';
    form.timerStartedAt = null;
  }

  // Only the hold ticker is cleaned up here. No `ref` in dispose() (see
  // CLAUDE.md), and the forms' controllers belong to _InProgressSession,
  // which outlives this State on purpose - disposeAll() frees them on
  // Finish or Discard.
  @override
  void dispose() {
    _holdTicker?.cancel();
    super.dispose();
  }

  List<_LoggedSetForm> _formsFor(
    PlanExercise exercise,
    WeightUnit unit, {
    double? percentageResolvedWeightKg,
  }) {
    return _session.formsByExerciseRowId.putIfAbsent(exercise.id, () {
      // A percentage prescription (e.g. "70%") would otherwise be
      // misparsed by the regex below as a flat "70kg" hint - resolve it
      // against the exercise's estimated 1RM instead when available.
      // Only a plain weight ("60", "60kg") pre-fills the field - "45 sec"
      // on a plank must not turn into a 45kg set, least of all now that
      // such exercises hide the weight field entirely.
      final plainWeight = RegExp(
        r'^\s*(\d+(\.\d+)?)\s*(kg)?\s*$',
        caseSensitive: false,
      ).firstMatch(exercise.weightIntensity);
      final weightHintKg = isPercentagePrescription(exercise.weightIntensity)
          ? percentageResolvedWeightKg
          : double.tryParse(plainWeight?.group(1) ?? '');
      final weightHint = weightHintKg == null
          ? ''
          : formatWeightNumber(kgToDisplay(weightHintKg, unit));
      final measure = _measureFor(exercise);
      // A timed or distance set counts seconds or metres, so the "1" in a
      // "3 x 1 @ 45 sec" prescription isn't a rep count to pre-fill.
      final repsHint = measure == SetMeasure.reps
          ? RegExp(r'^\d+').stringMatch(exercise.reps) ?? ''
          : '';
      final target = prescribedAmount(
        measure,
        prescribedReps: exercise.reps,
        prescribedWeight: exercise.weightIntensity,
      );
      return List.generate(
        exercise.sets,
        (_) => _LoggedSetForm(
          measure: measure,
          target: target,
          repsHint: repsHint,
          weightHint: weightHint,
        ),
      );
    });
  }

  /// Reads the library entry, which the body only builds once it's loaded
  /// (see `build`), so a form never gets created with a guessed measure.
  SetMeasure _measureFor(PlanExercise exercise) {
    final library = ref
        .read(exerciseLookupProvider)
        .valueOrNull?[exercise.exerciseId];
    return setMeasureFor(
      measurementType: library?.measurementType ?? '',
      prescribedReps: exercise.reps,
      prescribedWeight: exercise.weightIntensity,
    );
  }

  void _addSet(PlanExercise exercise, WeightUnit unit) {
    final forms = _formsFor(exercise, unit);
    setState(() => forms.add(forms.last.sibling()));
  }

  /// Removes one not-yet-logged set. A logged set must be undone first (via
  /// the existing undo icon) - this keeps "what does removing a set even
  /// mean once it's saved" from being a question at all. Always leaves at
  /// least one row; use "Skip" on the whole exercise for zero sets.
  void _removeSet(PlanExercise exercise, WeightUnit unit, int index) {
    final forms = _formsFor(exercise, unit);
    if (forms.length <= 1 || forms[index].logged) return;
    setState(() => forms.removeAt(index).dispose());
    // The removed row may have been the only running hold timer.
    _syncHoldTicker();
  }

  /// Un-skips straight away; skipping a prescribed exercise asks why (all
  /// optional) and whether to do something else in its place. The skip
  /// itself is only written when the session is finished - see
  /// [_skippedEntriesFor].
  Future<void> _toggleSkip(PlanExercise exercise) async {
    if (_session.skippedExerciseRowIds.contains(exercise.id)) {
      setState(() {
        _session.skippedExerciseRowIds.remove(exercise.id);
        _session.skipReasonByExerciseRowId.remove(exercise.id);
        // Back to doing the original: a substitute nothing was logged on
        // goes away; one already done stays, as a plain addition.
        final substituteId = _session.substituteRowIdBySkippedRowId.remove(
          exercise.id,
        );
        if (substituteId != null) _dropIfUnlogged(substituteId);
      });
      return;
    }
    // A mid-session addition was never prescribed - nothing to record or
    // replace, so no questions.
    if (exercise.id < 0) {
      setState(() {
        _session.skippedExerciseRowIds.add(exercise.id);
        _stopHoldTimersFor(exercise.id);
      });
      return;
    }

    final choice = await showModalBottomSheet<_SkipChoice>(
      context: context,
      showDragHandle: true,
      builder: (context) =>
          _SkipExerciseSheet(exerciseName: exercise.exerciseName),
    );
    if (choice == null || !mounted) return;

    Exercise? substitute;
    if (choice.replace) {
      substitute = await _pickSubstitute(exercise);
      if (substitute == null || !mounted) return;
    }

    setState(() {
      _session.skippedExerciseRowIds.add(exercise.id);
      _stopHoldTimersFor(exercise.id);
      final reason = choice.reason;
      if (reason == null) {
        _session.skipReasonByExerciseRowId.remove(exercise.id);
      } else {
        _session.skipReasonByExerciseRowId[exercise.id] = reason;
      }
      if (substitute != null) _setSubstitute(exercise, substitute);
    });
  }

  /// Puts [substitute] in [skipped]'s place, carrying over its sets, reps
  /// and rest - but not its load, which belongs to a different exercise. A
  /// previous substitute for the same exercise is dropped if nothing was
  /// logged on it yet, otherwise kept as a plain addition.
  void _setSubstitute(PlanExercise skipped, Exercise substitute) {
    final previousId = _session.substituteRowIdBySkippedRowId[skipped.id];
    if (previousId != null) _dropIfUnlogged(previousId);
    final row = PlanExercise(
      id: _session.nextAdHocExerciseId--,
      sessionId: skipped.sessionId,
      order: 0,
      exerciseId: substitute.id,
      exerciseName: substitute.name,
      sets: skipped.sets,
      reps: skipped.reps,
      weightIntensity: '',
      restSec: skipped.restSec,
      notes: '',
      videoUrl: '',
      embeddingAllowed: false,
    );
    _session.adHocExercises.add(row);
    _session.substituteRowIdBySkippedRowId[skipped.id] = row.id;
  }

  /// Removes a mid-session addition nothing was logged on yet.
  void _dropIfUnlogged(int adHocRowId) {
    final forms = _session.formsByExerciseRowId[adHocRowId];
    if (forms != null && forms.any((f) => f.logged)) return;
    _session.adHocExercises.removeWhere((e) => e.id == adHocRowId);
    _session.formsByExerciseRowId.remove(adHocRowId)?.forEach(
      (f) => f.dispose(),
    );
    _syncHoldTicker();
  }

  /// A skipped exercise's timer would otherwise keep counting unseen.
  void _stopHoldTimersFor(int exerciseRowId) {
    for (final form in _session.formsByExerciseRowId[exerciseRowId] ?? []) {
      _stopHoldTimer(form);
    }
    _syncHoldTicker();
  }

  /// The library picker, with this plan's other exercises offered first -
  /// alternatives the trainer already chose are usually the best swap.
  Future<Exercise?> _pickSubstitute(PlanExercise skipped) async {
    final library = ref.read(exerciseLookupProvider).valueOrNull;
    final details = ref
        .read(_sessionDetailsProvider(widget.planSessionId))
        .valueOrNull;
    if (library == null || details == null) return null;
    final plan = await ref.read(
      planDetailsProvider(details.session.planId).future,
    );
    if (!mounted) return null;

    final seen = <String>{?skipped.exerciseId};
    final fromPlan = <Exercise>[];
    for (final session in plan?.sessions ?? const <PlanSessionDetails>[]) {
      for (final exercise in session.exercises) {
        final id = exercise.exerciseId;
        final libraryExercise = id == null ? null : library[id];
        if (libraryExercise != null && seen.add(id!)) {
          fromPlan.add(libraryExercise);
        }
      }
    }

    return showDialog<Exercise>(
      context: context,
      builder: (context) => _ExercisePickerDialog(
        title: 'Replace ${skipped.exerciseName} with',
        suggestionsLabel: 'From this plan',
        suggestions: fromPlan,
        library: library.values.toList()
          ..sort((a, b) => a.name.compareTo(b.name)),
      ),
    );
  }

  /// Adds a queued make-up from an earlier session as a one-off exercise
  /// here, with that session's prescription. Logging it and finishing is
  /// what clears it from the make-up list.
  void _addMakeUp(PendingMakeUp makeUp) {
    final skip = makeUp.skip;
    setState(() {
      final row = PlanExercise(
        id: _session.nextAdHocExerciseId--,
        sessionId: widget.planSessionId,
        order: 0,
        exerciseId: skip.exerciseId,
        exerciseName: skip.exerciseName,
        sets: skip.prescribedSets,
        reps: skip.prescribedReps,
        weightIntensity: skip.prescribedWeightIntensity,
        restSec: skip.prescribedRestSec,
        notes: '',
        videoUrl: '',
        embeddingAllowed: false,
      );
      _session.adHocExercises.add(row);
      _session.makeUpByAdHocRowId[row.id] = makeUp;
    });
  }

  /// Queued make-ups worth offering in this session: not already added,
  /// not waved off, and not an exercise this session prescribes anyway
  /// (doing it here clears it regardless).
  List<PendingMakeUp> _offeredMakeUps(PlanSessionDetails details) {
    final pending = ref.watch(pendingMakeUpsProvider).valueOrNull ?? const [];
    final addedIds = {
      for (final m in _session.makeUpByAdHocRowId.values) m.skip.id,
    };
    final prescribedIds = {
      for (final e in details.exercises) ?e.exerciseId,
    };
    return [
      for (final makeUp in pending)
        if (makeUp.skip.queuedForNextSession &&
            !addedIds.contains(makeUp.skip.id) &&
            !_session.hiddenMakeUpIds.contains(makeUp.skip.id) &&
            !prescribedIds.contains(makeUp.skip.exerciseId))
          makeUp,
    ];
  }

  /// The italic line under a skipped exercise's name.
  String _skipLabel(PlanExercise exercise) {
    final reason = _session.skipReasonByExerciseRowId[exercise.id];
    final substituteId = _session.substituteRowIdBySkippedRowId[exercise.id];
    final substitute = substituteId == null
        ? null
        : _session.adHocExercises
              .where((e) => e.id == substituteId)
              .firstOrNull;
    return [
      'Skipped for this session${reason == null ? '' : ' (${reason.label})'}.',
      if (substitute != null) 'Replaced by ${substitute.exerciseName} below.',
    ].join(' ');
  }

  /// What a mid-session addition is for - null for a prescribed exercise.
  String? _adHocLabel(PlanExercise exercise, PlanSessionDetails details) {
    if (exercise.id >= 0) return null;
    final makeUp = _session.makeUpByAdHocRowId[exercise.id];
    if (makeUp != null) {
      return 'Make-up for '
          '${MaterialLocalizations.of(context).formatMediumDate(makeUp.skippedAt)}'
          ' - not saved to the plan.';
    }
    for (final entry in _session.substituteRowIdBySkippedRowId.entries) {
      if (entry.value != exercise.id) continue;
      final replaced = details.exercises
          .where((e) => e.id == entry.key)
          .firstOrNull;
      if (replaced != null) {
        return 'Replacing ${replaced.exerciseName} for this session only - '
            'not saved to the plan.';
      }
    }
    return 'Added for this session only - not saved to the plan.';
  }

  /// Lets the trainee attach a short note to one exercise for this session
  /// (e.g. "left shoulder felt off") - surfaced to a trainer via the
  /// Progress tab's "Full training log" PDF export, next to that exercise's
  /// actual sets. Purely in-memory until "Finish session" writes it onto
  /// that exercise's first logged set (see `_loggedEntriesFor`); leaving
  /// without finishing loses it the same way an unfinished session's sets
  /// are lost, which is consistent with everything else here.
  Future<void> _editExerciseNote(PlanExercise exercise) async {
    final note = await showDialog<String>(
      context: context,
      builder: (context) => _ExerciseNoteDialog(
        initialValue: _session.notesByExerciseRowId[exercise.id] ?? '',
      ),
    );
    if (note == null || !mounted) return;
    setState(() {
      if (note.isEmpty) {
        _session.notesByExerciseRowId.remove(exercise.id);
      } else {
        _session.notesByExerciseRowId[exercise.id] = note;
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
          embeddingAllowed: false,
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
        if (!didPop) {
          _confirmDiscard();
        } else {
          _clearExecutionScreenVisible();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Log session'),
        actions: [
          // Reported live: mid-session plate math meant leaving the screen
          // entirely (Exercise Library's own toolbar icon) - unsaved sets
          // and the rest timer both survive that, but it's still a detour
          // for something this quick. A modal sheet keeps the session
          // screen mounted underneath instead of pushing a whole new route.
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            tooltip: 'Plate calculator',
            onPressed: () => showPlateCalculatorSheet(context),
          ),
        ],
      ),
      body: detailsAsync.when(
        data: (details) {
          if (details == null) {
            return const Center(child: Text('Session not found.'));
          }
          // Each set row's field (reps, seconds or metres) comes from the
          // library entry, and forms are created once - so wait for it.
          if (!ref.watch(exerciseLookupProvider).hasValue) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!_draftRestoreAttempted) {
            _draftRestoreAttempted = true;
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _restoreDraftIfAny(details, unit),
            );
          }
          final showWeek = showsWeekNumber(
            ref
                    .watch(planDetailsProvider(details.session.planId))
                    .valueOrNull
                    ?.sessions
                    .map((s) => s.session.weekNumber) ??
                const [],
          );
          return Column(
            children: [
              if (restTimer.isVisible) _RestTimerBanner(state: restTimer),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      joinSessionLabel([
                        details.session.sessionName,
                        if (showWeek)
                          'Week ${details.session.weekNumber}',
                        details.session.day,
                      ]),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    if (_offeredMakeUps(details) case final offered
                        when offered.isNotEmpty)
                      _MakeUpOfferCard(
                        makeUps: offered,
                        onAdd: _addMakeUp,
                        onHide: (makeUp) => setState(
                          () => _session.hiddenMakeUpIds.add(makeUp.skip.id),
                        ),
                      ),
                    for (final renderUnit
                        in _groupedExercisesFor(_allExercises(details)))
                      if (renderUnit is _SoloUnit)
                        _ExerciseCard(
                          exercise: renderUnit.exercise,
                          forms: _formsFor(
                            renderUnit.exercise,
                            unit,
                            percentageResolvedWeightKg:
                                _resolvedPercentageWeightKg(renderUnit.exercise),
                          ),
                          unit: unit,
                          palette: ref.watch(appPreferencesProvider).colorPalette,
                          resolvedWeightKg: _resolvedPercentageWeightKg(
                            renderUnit.exercise,
                          ),
                          libraryExercise: ref
                              .watch(exerciseLookupProvider)
                              .valueOrNull?[renderUnit.exercise.exerciseId],
                          skipped: _session.skippedExerciseRowIds.contains(
                            renderUnit.exercise.id,
                          ),
                          skipLabel: _skipLabel(renderUnit.exercise),
                          adHocLabel: _adHocLabel(renderUnit.exercise, details),
                          onSetLogged: (form) =>
                              _logSet(renderUnit.exercise, form, unit),
                          onSetUnlogged: (form) =>
                              _unlogSet(renderUnit.exercise, form, unit),
                          onAddSet: () => _addSet(renderUnit.exercise, unit),
                          onRemoveSet: (index) =>
                              _removeSet(renderUnit.exercise, unit, index),
                          onToggleSkip: () =>
                              _toggleSkip(renderUnit.exercise),
                          onToggleTimer: _toggleHoldTimer,
                          traineeNote: _session.notesByExerciseRowId[renderUnit.exercise.id],
                          onEditNote: () =>
                              _editExerciseNote(renderUnit.exercise),
                        )
                      else if (renderUnit is _SupersetUnit)
                        _SupersetCard(
                          members: [
                            for (final member in renderUnit.members)
                              _memberFor(member, unit),
                          ],
                          unit: unit,
                          palette: ref.watch(appPreferencesProvider).colorPalette,
                          showPrCelebration: !ref
                              .watch(appPreferencesProvider)
                              .hideProgressActive,
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
  /// A skipped exercise's rows still hold their prefilled hints, so they're
  /// left out - otherwise skipping would trigger an "unlogged sets" prompt
  /// whose "Log & finish" logs the very exercise that was skipped.
  List<_LoggedSetForm> get _unloggedFilledForms =>
      _session.formsByExerciseRowId.entries
          .where((e) => !_session.skippedExerciseRowIds.contains(e.key))
          .expand((e) => e.value)
          .where(
            (f) =>
                !f.logged &&
                (f.hasCountEntered || f.weight.text.trim().isNotEmpty),
          )
          .toList();

  /// Shows the same "Leave without finishing?" dialog [_confirmDiscard] (a
  /// blocked back-navigation) and [_handleCloseRequest] (a Windows window-
  /// close request - see that method's own doc comment) both need, and does
  /// the "Discard" cleanup common to both. Deliberately doesn't touch
  /// navigation itself - callers differ on what should happen afterwards (a
  /// blocked pop needs to actually pop; a close request just needs a yes/no
  /// answer, since the whole app is about to exit regardless).
  Future<_LeaveChoice> _promptLeaveChoice() async {
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
      unawaited(
        ref.read(appDatabaseProvider).sessionLogDao.deleteDraft(
          widget.planSessionId,
        ),
      );
      // Guarded the same way the rest timer's own skip() is: a *different*
      // session could legitimately have been started elsewhere (via its own
      // "Leave") while this one sat unfinished, so only clear the marker if
      // it's still pointing at the session actually being discarded here.
      if (ref.read(activeInProgressSessionIdProvider) == widget.planSessionId) {
        ref.read(activeInProgressSessionIdProvider.notifier).state = null;
      }
      // Discarding erases the whole session, so a rest timer still counting
      // down for it makes no sense left running - same guard as above, in
      // case a *different* session's own timer is currently active instead.
      final restTimer = ref.read(restTimerControllerProvider);
      if (restTimer.planSessionId == widget.planSessionId) {
        ref.read(restTimerControllerProvider.notifier).skip();
      }
    }
    return choice ?? _LeaveChoice.keepTraining;
  }

  Future<void> _confirmDiscard() async {
    final choice = await _promptLeaveChoice();
    if ((choice == _LeaveChoice.discard || choice == _LeaveChoice.leave) &&
        mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Registered on [executionScreenCloseGuardProvider] while this screen is
  /// mounted (see `initState`/`_clearExecutionScreenVisible`) - the Windows-
  /// only answer to "is it safe to close the whole app window right now?"
  /// (see `main.dart`'s `AppLifecycleListener`). Reuses the exact same
  /// dialog and Discard cleanup as a blocked back-navigation, but never
  /// navigates itself: the app is about to fully exit either way once this
  /// returns true, and if it returns false the window simply stays open with
  /// this screen exactly as the user left it.
  Future<bool> _handleCloseRequest() async {
    if (!_hasUnsavedSets) return true;
    final choice = await _promptLeaveChoice();
    return choice == _LeaveChoice.discard || choice == _LeaveChoice.leave;
  }

  Future<void> _logSet(
    PlanExercise exercise,
    _LoggedSetForm form,
    WeightUnit unit, {
    bool startTimer = true,
  }) async {
    if (form.logged || form.pending) return;
    // Logging mid-hold takes the time so far.
    if (form.timerStartedAt != null) {
      _stopHoldTimer(form);
      _syncHoldTicker();
    }
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

    // Persists this checked-off set to the drafts table right away, not only
    // when the app is later backgrounded. Reported live (2026-09-10): log a
    // set, "Leave" the session, then press back enough times to fully exit
    // the app - on a real device (and reproduced here via adb/logcat), that
    // sequence can carry the Activity straight from `paused` into `detached`
    // within milliseconds, tearing down the Flutter engine before the
    // fire-and-forget autosave that only fires *on* backgrounding (see
    // autosaveInProgressSessionDraft, still called from home_screen.dart's
    // lifecycle observer as a backup) has any real chance to finish its own
    // DB round-trip - confirmed via logcat: `paused` and `detached` fired
    // 11ms apart, with "autosave completed" never printing for either.
    // Saving synchronously here, the moment a set is actually logged, means
    // the draft is already correct well before any subsequent navigation
    // could plausibly close the app, regardless of how that lifecycle race
    // plays out.
    await autosaveInProgressSessionDraft(ref, widget.planSessionId);

    if (!startTimer) return;
    final restSec = exercise.restSec ?? 90;
    ref.read(restTimerControllerProvider.notifier).start(
      Duration(seconds: restSec),
      planSessionId: widget.planSessionId,
    );
  }

  /// Reverts a mis-tapped or mis-typed set back to editable, before
  /// "Finish session" writes anything for real - only the autosaved draft
  /// (see _logSet's own doc comment) reflects it in the meantime, so this
  /// re-syncs that draft too once the set is unchecked, or a stale draft
  /// could otherwise restore a set that was actually undone. Also un-counts
  /// it from this session's own PR tracking, so a later set of the same
  /// exercise isn't compared against a PR that got undone.
  Future<void> _unlogSet(
    PlanExercise exercise,
    _LoggedSetForm form,
    WeightUnit unit,
  ) async {
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
    await autosaveInProgressSessionDraft(ref, widget.planSessionId);
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
        if (exercise.exerciseId != null &&
            !_session.skippedExerciseRowIds.contains(exercise.id))
          for (final form in _formsFor(exercise, unit))
            if (!form.logged &&
                (form.hasCountEntered || form.weight.text.trim().isNotEmpty))
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

    // Requested directly (2026-09-16): there was previously no way to look
    // over what's about to be saved before it's committed for good - the
    // note prompt right after this was a hard "Skip or Save" commit point
    // with no way back. Skipped when nothing was actually logged (matches
    // the `entries.isEmpty` branch below, which has nothing to review
    // either). Edits made here write straight into the same
    // `_LoggedSetForm` controllers `_loggedEntries` reads from below - see
    // `_SessionReviewScreen`'s own doc comment for why that's deliberate,
    // not an oversight.
    final hasAnyLoggedSet = _session.formsByExerciseRowId.values.any(
      (forms) => forms.any((f) => f.logged),
    );
    if (hasAnyLoggedSet) {
      final confirmed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => _SessionReviewScreen(
            details: details,
            session: _session,
            unit: unit,
            library: ref.read(exerciseLookupProvider).valueOrNull ?? const {},
          ),
        ),
      );
      if (confirmed != true) return;
      if (!mounted) return;
    }

    setState(() => _session.finishing = true);
    final db = ref.read(appDatabaseProvider);
    final entries = _loggedEntries(details, unit);

    if (entries.isNotEmpty) {
      final note = await _promptForNote();
      if (!mounted) return;
      await db.sessionLogDao.createSessionLog(
        id: const Uuid().v4(),
        planSessionId: widget.planSessionId,
        loggedAt: DateTime.now(),
        entries: entries,
        notes: note,
        skipped: _skippedEntriesFor(_session, details),
      );
      // One-shot FutureProviders - won't notice this write on their own.
      ref.invalidate(loggedPlanSessionIdsProvider);
      invalidateProgressProviders(ref);
    } else {
      // createSessionLog (above) already clears any autosaved draft as part
      // of writing the real log - but finishing with nothing logged never
      // reaches that call, so a draft from earlier in this same session
      // (e.g. a set was autosaved, then undone before Finish) needs its own
      // explicit cleanup here instead.
      await db.sessionLogDao.deleteDraft(widget.planSessionId);
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
    // Same guard as the rest-timer skip() just above - only clear the "in
    // progress" marker if it's still this session's.
    if (ref.read(activeInProgressSessionIdProvider) == widget.planSessionId) {
      ref.read(activeInProgressSessionIdProvider.notifier).state = null;
    }

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

/// Shown between "Finish session" and the note prompt, once there's at
/// least one logged set to review. Deliberately edits the *same*
/// `_LoggedSetForm` controllers the exercise list itself uses (not copies) -
/// `_loggedEntriesFor` reads live text at the moment of the actual DB
/// write regardless of which screen last touched it, so an edit made here
/// is picked up correctly with no extra plumbing. This also means an edit
/// survives tapping "Back" rather than being rolled back - treated as a
/// deliberate choice (this is still a draft until the real "Confirm &
/// finish" below, so keeping edits reads more like editing a draft than a
/// transaction that needs an explicit rollback) rather than an oversight.
class _SessionReviewScreen extends StatefulWidget {
  final PlanSessionDetails details;
  final _InProgressSession session;
  final WeightUnit unit;

  /// Library entries by id, for each exercise's weight input.
  final Map<String, Exercise> library;

  const _SessionReviewScreen({
    required this.details,
    required this.session,
    required this.unit,
    required this.library,
  });

  @override
  State<_SessionReviewScreen> createState() => _SessionReviewScreenState();
}

class _SessionReviewScreenState extends State<_SessionReviewScreen> {
  @override
  Widget build(BuildContext context) {
    final exercises = _allExercisesFor(widget.session, widget.details);
    final unitLabel = widget.unit == WeightUnit.lbs ? 'lbs' : 'kg';

    return Scaffold(
      appBar: AppBar(title: const Text('Review before finishing')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Double-check what you logged - tap any field to fix it before '
            'it\'s saved for good.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          for (final exercise in exercises)
            if (exercise.exerciseId != null)
              _buildExerciseCard(context, exercise, unitLabel),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirm & finish'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    PlanExercise exercise,
    String unitLabel,
  ) {
    final forms = widget.session.formsByExerciseRowId[exercise.id] ?? [];
    final loggedForms = [
      for (var i = 0; i < forms.length; i++)
        if (forms[i].logged) (setNumber: i + 1, form: forms[i]),
    ];
    if (loggedForms.isEmpty) return const SizedBox.shrink();
    final loadInput = _loadInputFor(
      exercise,
      widget.library[exercise.exerciseId],
    );

    return Card(
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
            for (final entry in loggedForms)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text(
                        '${entry.setNumber}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Expanded(
                      child: _countField(
                        entry.form,
                        enabled: true,
                        dense: true,
                      ),
                    ),
                    if (loadInput != LoadInput.none) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: entry.form.weight,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: decimalInputFormatters,
                          decoration: InputDecoration(
                            labelText: weightFieldLabel(
                              loadInput,
                              lbs: unitLabel == 'lbs',
                            ),
                            hintText: loadInput == LoadInput.addedWeight
                                ? 'BW'
                                : null,
                            floatingLabelBehavior:
                                loadInput == LoadInput.addedWeight
                                ? FloatingLabelBehavior.always
                                : null,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: entry.form.rpe,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: decimalInputFormatters,
                        decoration: const InputDecoration(
                          labelText: 'RPE',
                          isDense: true,
                        ),
                      ),
                    ),
                    if (entry.form.isPr)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(
                          Icons.emoji_events,
                          size: 18,
                          color: Colors.amber,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Owns its own controller (same reasoning as `_NotePromptDialog` below) -
/// used for a trainee's note on one specific exercise, as opposed to that
/// dialog's whole-session note shown once after finishing.
class _ExerciseNoteDialog extends StatefulWidget {
  final String initialValue;
  const _ExerciseNoteDialog({required this.initialValue});

  @override
  State<_ExerciseNoteDialog> createState() => _ExerciseNoteDialogState();
}

class _ExerciseNoteDialogState extends State<_ExerciseNoteDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Note for your trainer'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'e.g. "Left shoulder felt off on this one"',
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
  final String title;

  /// Shown above the full library while the search box is empty.
  final List<Exercise> suggestions;
  final String suggestionsLabel;

  const _ExercisePickerDialog({
    required this.library,
    this.title = 'Add exercise',
    this.suggestions = const [],
    this.suggestionsLabel = '',
  });

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
    final suggestions = _query.isEmpty ? widget.suggestions : const <Exercise>[];

    Widget sectionLabel(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
    );
    Widget tile(Exercise e) => ListTile(
      title: Text(e.name),
      subtitle: Text(e.category),
      onTap: () => Navigator.of(context).pop(e),
    );

    return AlertDialog(
      title: Text(widget.title),
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
                  : suggestions.isEmpty
                  ? ListView.builder(
                      itemCount: matches.length,
                      itemBuilder: (context, index) => tile(matches[index]),
                    )
                  : ListView(
                      children: [
                        sectionLabel(widget.suggestionsLabel),
                        for (final e in suggestions) tile(e),
                        const Divider(),
                        sectionLabel('All exercises'),
                        for (final e in matches) tile(e),
                      ],
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

/// What the skip sheet returns: an optional reason, and whether to pick
/// something to do in the exercise's place.
class _SkipChoice {
  final SkipReason? reason;
  final bool replace;

  const _SkipChoice({required this.reason, required this.replace});
}

/// Asks why an exercise is being skipped - optional, since a busy gym is
/// no time for forms - and offers to replace it. The reason shows up in the
/// trainer PDF and the Today tab's make-up list.
class _SkipExerciseSheet extends StatefulWidget {
  final String exerciseName;

  const _SkipExerciseSheet({required this.exerciseName});

  @override
  State<_SkipExerciseSheet> createState() => _SkipExerciseSheetState();
}

class _SkipExerciseSheetState extends State<_SkipExerciseSheet> {
  SkipReason? _reason;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Skip ${widget.exerciseName}?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Why? (optional)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final reason in SkipReason.values)
                  ChoiceChip(
                    label: Text(reason.label),
                    selected: _reason == reason,
                    onSelected: (selected) =>
                        setState(() => _reason = selected ? reason : null),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(_SkipChoice(reason: _reason, replace: false)),
                    child: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(_SkipChoice(reason: _reason, replace: true)),
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Skip & replace'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Make-ups the trainee queued from the Today tab, offered at the top of
/// the next session. Adding one is optional - "Not today" hides it for
/// this session only and it stays queued.
class _MakeUpOfferCard extends StatelessWidget {
  final List<PendingMakeUp> makeUps;
  final void Function(PendingMakeUp makeUp) onAdd;
  final void Function(PendingMakeUp makeUp) onHide;

  const _MakeUpOfferCard({
    required this.makeUps,
    required this.onAdd,
    required this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Make up from earlier',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final makeUp in makeUps)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      makeUp.skip.exerciseName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      [
                        'Skipped ${localizations.formatMediumDate(makeUp.skippedAt)}',
                        ?SkipReason.fromKey(makeUp.skip.reason)?.label,
                        '${makeUp.skip.prescribedSets}×${makeUp.skip.prescribedReps}',
                      ].join(' • '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    OverflowBar(
                      spacing: 4,
                      children: [
                        TextButton(
                          onPressed: () => onAdd(makeUp),
                          child: const Text('Add to this session'),
                        ),
                        TextButton(
                          onPressed: () => onHide(makeUp),
                          child: const Text('Not today'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
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
    final alarming = state.overdue || isRestTimerNearEnd(remaining);
    return PulsingHighlight(
      active: alarming,
      child: Material(
        color: alarming
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                state.overdue
                    ? 'Rest over - back to it'
                    : 'Rest: ${formatRestTime(remaining)}',
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
      ),
    );
  }
}

/// The counted field of a set row - reps, seconds or metres depending on
/// [form]'s measure. Shared by the set rows and the review screen.
Widget _countField(
  _LoggedSetForm form, {
  required bool enabled,
  bool dense = false,
}) {
  return switch (form.measure) {
    SetMeasure.reps => TextField(
      controller: form.reps,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: integerInputFormatters,
      decoration: InputDecoration(labelText: 'Reps', isDense: dense),
    ),
    SetMeasure.time => TextField(
      controller: form.amount,
      // Read-only while the hold timer is counting into it.
      enabled: enabled && form.timerStartedAt == null,
      keyboardType: TextInputType.number,
      inputFormatters: integerInputFormatters,
      decoration: InputDecoration(labelText: 'Time (s)', isDense: dense),
    ),
    SetMeasure.distance => TextField(
      controller: form.amount,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: decimalInputFormatters,
      decoration: InputDecoration(labelText: 'Distance (m)', isDense: dense),
    ),
  };
}

class _ExerciseCard extends ConsumerWidget {
  final PlanExercise exercise;
  final List<_LoggedSetForm> forms;
  final WeightUnit unit;
  final AppColorPalette palette;
  final Exercise? libraryExercise;
  final bool skipped;

  /// Shown in place of the sets while [skipped] - includes the reason and
  /// substitute, if any.
  final String skipLabel;

  /// What a mid-session addition is for (a plain addition, a substitute,
  /// or a make-up); null for a prescribed exercise.
  final String? adHocLabel;
  final void Function(_LoggedSetForm form) onSetLogged;
  final void Function(_LoggedSetForm form) onSetUnlogged;
  final VoidCallback onAddSet;
  final void Function(int index) onRemoveSet;
  final VoidCallback onToggleSkip;
  final void Function(_LoggedSetForm form) onToggleTimer;

  /// The trainee's own note on this exercise for this session, if any (see
  /// `_ExecutionScreenState._editExerciseNote`) - distinct from
  /// [exercise]'s own `notes` field, which is the trainer's prescription
  /// note authored into the plan, not something set here.
  final String? traineeNote;
  final VoidCallback onEditNote;

  /// A percentage prescription (e.g. "70%") resolved against the
  /// exercise's current best estimated 1RM, in kg - null either because
  /// this isn't a percentage prescription or because there's no logged
  /// history to resolve it against yet (see the "Target: ..." line below
  /// for the graceful fallback text in the latter case).
  final double? resolvedWeightKg;

  const _ExerciseCard({
    required this.exercise,
    required this.forms,
    required this.unit,
    required this.palette,
    required this.libraryExercise,
    required this.skipped,
    required this.skipLabel,
    required this.onSetLogged,
    required this.onSetUnlogged,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onToggleSkip,
    required this.onToggleTimer,
    required this.onEditNote,
    this.adHocLabel,
    this.traineeNote,
    this.resolvedWeightKg,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final area = areaForExercise(
      muscleGroups: libraryExercise?.muscleGroups ?? '',
      category: libraryExercise?.category ?? '',
      movementPattern: libraryExercise?.movementPattern ?? '',
    );
    final showPrCelebration =
        !ref.watch(appPreferencesProvider).hideProgressActive;

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
                  onPressed: onEditNote,
                  tooltip: traineeNote != null && traineeNote!.isNotEmpty
                      ? 'Edit your note for the trainer'
                      : 'Add a note for your trainer',
                  icon: Icon(
                    traineeNote != null && traineeNote!.isNotEmpty
                        ? Icons.sticky_note_2
                        : Icons.sticky_note_2_outlined,
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
              '${_weightIntensitySuffix()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            // Mid-session additions are never written to the plan, so this
            // says so rather than letting them look identical to a
            // normally-prescribed row.
            if (adHocLabel != null)
              Text(
                adHocLabel!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            if (exercise.exerciseId != null)
              _LastAndBestLine(exerciseId: exercise.exerciseId!, unit: unit),
            if (exercise.notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  exercise.notes,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (traineeNote != null && traineeNote!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Your note: $traineeNote',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            if (skipped)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  skipLabel,
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
                  showPrCelebration: showPrCelebration,
                  loadInput: _loadInputFor(exercise, libraryExercise),
                  onToggleTimer: () => onToggleTimer(forms[i]),
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

  /// " @ 70% (≈52.5kg)" once resolved, " @ 70% (no history yet)" when the
  /// exercise has never been logged, or the plain " @ 60kg" flat-weight
  /// text unchanged for a non-percentage prescription.
  String _weightIntensitySuffix() {
    final weightIntensity = exercise.weightIntensity;
    if (weightIntensity.isEmpty) return '';
    if (!isPercentagePrescription(weightIntensity)) {
      return ' @ $weightIntensity';
    }
    final resolved = resolvedWeightKg;
    final resolvedText = resolved == null
        ? 'no history yet'
        : '≈${formatWeightInUnit(resolved, unit)}';
    return ' @ $weightIntensity ($resolvedText)';
  }
}

/// One superset member's data and bound callbacks, prepared by
/// `_ExecutionScreenState._memberFor` the same way the solo `_ExerciseCard`
/// gets its properties directly in `build()`'s loop.
class _SupersetMember {
  final PlanExercise exercise;
  final List<_LoggedSetForm> forms;
  final double? resolvedWeightKg;
  final Exercise? libraryExercise;
  final bool skipped;
  final String skipLabel;
  final void Function(_LoggedSetForm form, {required bool startTimer})
  onSetLogged;
  final void Function(_LoggedSetForm form) onSetUnlogged;
  final VoidCallback onAddSet;
  final void Function(int index) onRemoveSet;
  final VoidCallback onToggleSkip;
  final void Function(_LoggedSetForm form) onToggleTimer;

  _SupersetMember({
    required this.exercise,
    required this.forms,
    required this.resolvedWeightKg,
    required this.libraryExercise,
    required this.skipped,
    required this.skipLabel,
    required this.onSetLogged,
    required this.onSetUnlogged,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onToggleSkip,
    required this.onToggleTimer,
  });
}

/// A superset/circuit card: 2+ exercises done back-to-back in round-robin
/// order, with one shared rest only after each round rather than after
/// every individual exercise. Members can have different set counts - a
/// round simply omits whichever member has already run out of sets, no
/// forced-equal-sets rule.
class _SupersetCard extends StatelessWidget {
  final List<_SupersetMember> members;
  final WeightUnit unit;
  final AppColorPalette palette;
  final bool showPrCelebration;

  const _SupersetCard({
    required this.members,
    required this.unit,
    required this.palette,
    this.showPrCelebration = true,
  });

  @override
  Widget build(BuildContext context) {
    final activeMembers = members.where((m) => !m.skipped).toList();
    final maxRounds = activeMembers.isEmpty
        ? 0
        : activeMembers.map((m) => m.forms.length).reduce(
            (a, b) => a > b ? a : b,
          );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.link, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Superset',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 18),
                  tooltip: 'What is a superset?',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => showInfoDialog(
                    context,
                    title: 'What is a superset?',
                    content: supersetExplanationNote,
                  ),
                ),
              ],
            ),
            for (final member in members) _SupersetMemberHeader(
              member: member,
              unit: unit,
              palette: palette,
            ),
            const Divider(),
            for (var round = 0; round < maxRounds; round++)
              // Keyed so a round's contents can be located as a subtree in
              // tests (e.g. asserting a shorter-count member is absent from
              // a later round) without relying on flat sibling ordering.
              Column(
                key: ValueKey('superset_round_$round'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Round ${round + 1}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  for (final member in activeMembers)
                    if (round < member.forms.length)
                      _SupersetSetRow(
                        member: member,
                        unit: unit,
                        round: round,
                        showPrCelebration: showPrCelebration,
                        // Only the last still-active member in this round
                        // triggers the rest timer, using its own restSec -
                        // once a shorter-count member runs out of sets, the
                        // remaining member simply becomes "last" every
                        // round and gets normal solo-style rest.
                        isLastActiveInRound: identical(
                          member,
                          activeMembers.lastWhere(
                            (m) => round < m.forms.length,
                          ),
                        ),
                      ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SupersetMemberHeader extends StatelessWidget {
  final _SupersetMember member;
  final WeightUnit unit;
  final AppColorPalette palette;

  const _SupersetMemberHeader({
    required this.member,
    required this.unit,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final exercise = member.exercise;
    final area = areaForExercise(
      muscleGroups: member.libraryExercise?.muscleGroups ?? '',
      category: member.libraryExercise?.category ?? '',
      movementPattern: member.libraryExercise?.movementPattern ?? '',
    );
    return Padding(
      padding: const EdgeInsets.only(top: 8),
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    decoration: member.skipped
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              IconButton(
                onPressed: member.onToggleSkip,
                tooltip: member.skipped
                    ? 'Include this exercise again'
                    : 'Skip this exercise',
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  member.skipped ? Icons.replay : Icons.remove_circle_outline,
                ),
              ),
            ],
          ),
          Text(
            '${exercise.sets} x ${exercise.reps}'
            '${exercise.weightIntensity.isEmpty ? '' : ' @ ${exercise.weightIntensity}'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (member.skipped)
            Text(
              member.skipLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            )
          else if (exercise.exerciseId != null)
            _LastAndBestLine(exerciseId: exercise.exerciseId!, unit: unit),
          if (exercise.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                exercise.notes,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (!member.skipped)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: member.onAddSet,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add set'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SupersetSetRow extends StatelessWidget {
  final _SupersetMember member;
  final WeightUnit unit;
  final int round;
  final bool isLastActiveInRound;
  final bool showPrCelebration;

  const _SupersetSetRow({
    required this.member,
    required this.unit,
    required this.round,
    required this.isLastActiveInRound,
    this.showPrCelebration = true,
  });

  @override
  Widget build(BuildContext context) {
    final form = member.forms[round];
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            member.exercise.exerciseName,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          _SetRow(
            setNumber: round + 1,
            form: form,
            unit: unit,
            canRemove: member.forms.length > 1,
            onLog: () =>
                member.onSetLogged(form, startTimer: isLastActiveInRound),
            onUnlog: () => member.onSetUnlogged(form),
            onRemove: () => member.onRemoveSet(round),
            showPrCelebration: showPrCelebration,
            loadInput: _loadInputFor(member.exercise, member.libraryExercise),
            onToggleTimer: () => member.onToggleTimer(form),
          ),
        ],
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
    final history =
        ref.watch(exerciseProgressionHistoryProvider(exerciseId)).valueOrNull;
    final estimatedOneRepMax = ref
        .watch(estimatedOneRepMaxProvider(exerciseId))
        .valueOrNull;

    final weightedLastSets =
        lastSets?.where((s) => s.weight != null && s.reps != null).toList() ??
        const [];
    // A hold or a carry: what was done last time is the time or distance.
    final measuredLastSets =
        lastSets
            ?.where((s) => s.durationSec != null || s.distance != null)
            .toList() ??
        const [];
    if (weightedLastSets.isEmpty &&
        measuredLastSets.isEmpty &&
        (history == null || history.isEmpty)) {
      return const SizedBox.shrink();
    }

    String measured(LoggedSet s) {
      final amount = s.durationSec != null
          ? formatSetDuration(s.durationSec!)
          : formatSetDistance(s.distance!);
      return s.weight == null
          ? amount
          : '$amount @ ${formatWeightInUnit(s.weight!, unit)}';
    }

    final lastText = weightedLastSets.isNotEmpty
        ? 'Last: ${weightedLastSets.map((s) => '${s.reps}×${formatWeightInUnit(s.weight!, unit)}').join(', ')}'
        : measuredLastSets.isNotEmpty
        ? 'Last: ${measuredLastSets.map(measured).join(', ')}'
        : null;

    final best = (history == null || history.isEmpty)
        ? null
        : history.reduce((a, b) => a.weight >= b.weight ? a : b);
    final bestText = best == null
        ? null
        : 'Best: ${formatWeightInUnit(best.weight, unit)}';

    final oneRepMaxText = estimatedOneRepMax == null
        ? null
        : 'Est. 1RM: ${formatWeightInUnit(estimatedOneRepMax, unit)}';

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        [?lastText, ?bestText, ?oneRepMaxText].join('  •  '),
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

  /// Whether a new PR should actually show as a trophy icon - false while
  /// Focus Mode is hiding progress, in which case a logged set always shows
  /// the plain checkmark regardless of `form.isPr`. Detection itself
  /// (`isPersonalRecord`, set elsewhere) is untouched either way, so nothing
  /// here affects the underlying data - only whether this one icon
  /// celebrates it.
  final bool showPrCelebration;

  /// Whether this exercise gets a weight field at all - see [loadInputFor].
  final LoadInput loadInput;

  /// Starts or stops the hold timer on a timed set.
  final VoidCallback? onToggleTimer;

  const _SetRow({
    required this.setNumber,
    required this.form,
    required this.unit,
    required this.canRemove,
    required this.onLog,
    required this.onUnlog,
    required this.onRemove,
    this.showPrCelebration = true,
    this.loadInput = LoadInput.weight,
    this.onToggleTimer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('$setNumber')),
          Expanded(child: _countField(form, enabled: !form.logged)),
          if (form.measure == SetMeasure.time &&
              !form.logged &&
              onToggleTimer != null)
            IconButton(
              onPressed: onToggleTimer,
              tooltip: form.timerStartedAt == null
                  ? 'Time this set'
                  : 'Stop the timer',
              visualDensity: VisualDensity.compact,
              icon: form.timerStartedAt == null
                  ? const Icon(Icons.timer_outlined)
                  : const Icon(Icons.stop_circle_outlined),
            ),
          if (loadInput != LoadInput.none) ...[
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
                  labelText: weightFieldLabel(
                    loadInput,
                    lbs: unit == WeightUnit.lbs,
                  ),
                  // Shown inside the empty field, so a bodyweight set reads
                  // as "BW" rather than as a missing number.
                  hintText: loadInput == LoadInput.addedWeight ? 'BW' : null,
                  floatingLabelBehavior: loadInput == LoadInput.addedWeight
                      ? FloatingLabelBehavior.always
                      : null,
                ),
              ),
            ),
          ],
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
                form.isPr && showPrCelebration
                    ? Icons.emoji_events
                    : Icons.check_circle,
                color: form.isPr && showPrCelebration
                    ? Colors.amber.shade700
                    : Colors.green,
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
