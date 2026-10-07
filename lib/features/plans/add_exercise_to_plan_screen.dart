import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../data/daos/plan_dao.dart';
import '../../logic/week_label.dart';
import '../calendar/calendar_screen.dart' show scheduledSessionsProvider;
import '../shared/numeric_input_formatters.dart';
import 'exercise_prescription_form.dart';
import 'plan_providers.dart';

const _newPlanSentinel = '__new_plan__';
const _newSessionSentinel = -1;

// Matches the day values used by the CSV plan template and existing
// imported plans (e.g. templates/training_plan_template.csv).
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Lets the user add an exercise (already in the library) into a plan,
/// creating a new plan and/or a new session inline if needed - the "add
/// from the library" path called out alongside the long-press quick-add,
/// since building a plan previously only worked via spreadsheet/JSON import.
class AddExerciseToPlanScreen extends ConsumerStatefulWidget {
  final String exerciseId;
  final String exerciseName;

  const AddExerciseToPlanScreen({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
  });

  @override
  ConsumerState<AddExerciseToPlanScreen> createState() =>
      _AddExerciseToPlanScreenState();
}

class _AddExerciseToPlanScreenState
    extends ConsumerState<AddExerciseToPlanScreen> {
  String? _selectedPlanId;
  int? _selectedSessionId;
  String? _newSessionDay;
  bool _submitting = false;

  final _newPlanNameController = TextEditingController();
  final _newSessionWeekController = TextEditingController(text: '1');
  final _newSessionNameController = TextEditingController();

  final _prescription = ExercisePrescriptionControllers();

  late final List<TextEditingController> _allControllers = [
    _newPlanNameController,
    _newSessionWeekController,
    _newSessionNameController,
    ..._prescription.all,
  ];
  late final _initialControllerTexts = _allControllers
      .map((c) => c.text)
      .toList(growable: false);

  bool get _hasUnsavedChanges {
    if (_selectedPlanId != null) return true;
    if (_selectedSessionId != null) return true;
    if (_newSessionDay != null) return true;
    for (var i = 0; i < _allControllers.length; i++) {
      if (_allControllers[i].text != _initialControllerTexts[i]) return true;
    }
    return false;
  }

  @override
  void dispose() {
    for (final controller in _allControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(plansListProvider);

    // canPop is read fresh on every pop attempt from whatever's last built,
    // but plain TextFields don't rebuild their parent on each keystroke - so
    // without this listener, typing wouldn't ever flip canPop to false.
    return ListenableBuilder(
      listenable: Listenable.merge(_allControllers),
      builder: (context, _) => PopScope(
        canPop: _submitting || !_hasUnsavedChanges,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _confirmDiscard();
        },
        child: _buildScaffold(context, plansAsync),
      ),
    );
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'The plan/session choice and set details entered here have not '
          'been saved yet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildScaffold(
    BuildContext context,
    AsyncValue<List<Plan>> plansAsync,
  ) {
    return Scaffold(
      appBar: AppBar(title: Text('Add "${widget.exerciseName}" to plan')),
      body: _submitting
          ? const Center(child: CircularProgressIndicator())
          : plansAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (plans) => ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  Text('Plan', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => _pickPlan(context, plans),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(_planLabel(plans)),
                    ),
                  ),
                  if (_selectedPlanId == _newPlanSentinel) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _newPlanNameController,
                      decoration: const InputDecoration(
                        labelText: 'New plan name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  if (_selectedPlanId != null &&
                      _selectedPlanId != _newPlanSentinel) ...[
                    const SizedBox(height: 24),
                    _SessionPicker(
                      planId: _selectedPlanId!,
                      selectedSessionId: _selectedSessionId,
                      onChanged: (value) =>
                          setState(() => _selectedSessionId = value),
                    ),
                  ],
                  if (_selectedPlanId == _newPlanSentinel ||
                      _selectedSessionId == _newSessionSentinel) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newSessionWeekController,
                            keyboardType: TextInputType.number,
                            inputFormatters: integerInputFormatters,
                            decoration: const InputDecoration(
                              labelText: 'Week',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Day',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            child: InkWell(
                              onTap: () => _pickDay(context),
                              child: Text(_newSessionDay ?? 'Choose a day'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _newSessionNameController,
                      decoration: const InputDecoration(
                        labelText: 'Session name',
                        hintText: 'e.g. Push Day',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Exercise details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ExercisePrescriptionFields(controllers: _prescription),
                  const SizedBox(height: 24),
                  // Scoped to just this button, rather than a whole-screen
                  // setState() on every keystroke: _canSubmit() depends on
                  // several TextEditingControllers' text, so the button
                  // needs to rebuild when any of them change, or it would
                  // stay stuck in whatever enabled/disabled state it was in
                  // at the initial build (typically permanently disabled).
                  ListenableBuilder(
                    listenable: Listenable.merge(_allControllers),
                    builder: (context, _) => FilledButton(
                      onPressed: _canSubmit() ? _submit : null,
                      child: const Text('Add to plan'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _planLabel(List<Plan> plans) {
    if (_selectedPlanId == _newPlanSentinel) return 'New plan';
    if (_selectedPlanId == null) return 'Choose a plan';
    return plans
        .firstWhere((p) => p.id == _selectedPlanId)
        .name;
  }

  Future<void> _pickPlan(BuildContext context, List<Plan> plans) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose a plan'),
        children: [
          for (final plan in plans)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(plan.id),
              child: Text(plan.name),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(_newPlanSentinel),
            child: const Text('+ Create new plan'),
          ),
        ],
      ),
    );
    if (choice == null) return;
    setState(() {
      _selectedPlanId = choice;
      _selectedSessionId = null;
    });
  }

  Future<void> _pickDay(BuildContext context) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose a day'),
        children: [
          for (final day in _weekdays)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(day),
              child: Text(day),
            ),
        ],
      ),
    );
    if (choice == null) return;
    setState(() => _newSessionDay = choice);
  }

  bool _canSubmit() {
    if (_selectedPlanId == null) return false;
    if (_selectedPlanId == _newPlanSentinel &&
        _newPlanNameController.text.trim().isEmpty) {
      return false;
    }
    if (_selectedPlanId != _newPlanSentinel && _selectedSessionId == null) {
      return false;
    }
    final needsNewSessionFields =
        _selectedPlanId == _newPlanSentinel ||
        _selectedSessionId == _newSessionSentinel;
    if (needsNewSessionFields &&
        (_newSessionDay == null ||
            _newSessionNameController.text.trim().isEmpty)) {
      return false;
    }
    if (!_prescription.isValid) return false;
    return true;
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final db = ref.read(appDatabaseProvider);

    var planId = _selectedPlanId;
    if (planId == _newPlanSentinel) {
      planId = await db.planDao.createEmptyPlan(
        name: _newPlanNameController.text.trim(),
      );
    }

    var sessionId = _selectedSessionId;
    if (sessionId == null || sessionId == _newSessionSentinel) {
      sessionId = await db.planDao.addSession(
        planId: planId!,
        weekNumber: int.tryParse(_newSessionWeekController.text.trim()) ?? 1,
        day: _newSessionDay!,
        sessionName: _newSessionNameController.text.trim(),
      );
    }

    await db.planDao.addExerciseToSession(
      sessionId: sessionId,
      input: _prescription.toInput(
        order: 0, // ignored - addExerciseToSession assigns the real next order
        exerciseId: widget.exerciseId,
        exerciseName: widget.exerciseName,
      ),
    );

    ref.invalidate(planDetailsProvider(planId!));
    // A session in a new week changes whether scheduled ones show the week.
    ref.invalidate(scheduledSessionsProvider);

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.exerciseName} added to plan.')),
    );
  }
}

class _SessionPicker extends ConsumerWidget {
  final String planId;
  final int? selectedSessionId;
  final ValueChanged<int?> onChanged;

  const _SessionPicker({
    required this.planId,
    required this.selectedSessionId,
    required this.onChanged,
  });

  static String _sessionLabel(
    PlanSessionDetails s,
    List<PlanSessionDetails> sessions,
  ) => joinSessionLabel([
    if (showsWeekNumber(sessions.map((other) => other.session.weekNumber)))
      'Week ${s.session.weekNumber}',
    s.session.day,
    s.session.sessionName,
  ]);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(planDetailsProvider(planId));
    return detailsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('Error: $error'),
      data: (details) {
        final sessions = details?.sessions ?? const [];
        final label = selectedSessionId == _newSessionSentinel
            ? 'New session'
            : selectedSessionId == null
            ? 'Choose a session'
            : _sessionLabel(
                sessions.firstWhere((s) => s.session.id == selectedSessionId),
                sessions,
              );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Session', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _pickSession(context, sessions),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(label),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickSession(
    BuildContext context,
    List<PlanSessionDetails> sessions,
  ) async {
    final choice = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose a session'),
        children: [
          for (final s in sessions)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(s.session.id),
              child: Text(_sessionLabel(s, sessions)),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(_newSessionSentinel),
            child: const Text('+ Create new session'),
          ),
        ],
      ),
    );
    if (choice == null) return;
    onChanged(choice);
  }
}
