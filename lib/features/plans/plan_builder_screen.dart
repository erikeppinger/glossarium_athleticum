import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../data/daos/plan_dao.dart';
import '../exercise_library/exercise_picker_screen.dart';
import '../shared/numeric_input_formatters.dart';
import 'exercise_prescription_form.dart';

// Matches the day values used by the CSV plan template and existing
// imported plans (e.g. templates/training_plan_template.csv) - same list
// add_exercise_to_plan_screen.dart uses.
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class _SessionDraft {
  int weekNumber;
  String day;
  String sessionName;
  final List<PlanExerciseInput> exercises = [];

  _SessionDraft({
    required this.weekNumber,
    required this.day,
    required this.sessionName,
  });
}

/// Builds a whole new plan from scratch, entirely in memory until "Save
/// plan" - name it, add one or more sessions, and add exercises (picked
/// from the library) to each session, all before anything is written.
/// Mirrors `PlanImportScreen`'s own "build it all, then call
/// `PlanDao.createPlan()` once" shape rather than writing session-by-session.
///
/// Previously the *only* way to build a plan without a spreadsheet was
/// `add_exercise_to_plan_screen.dart`, reachable exclusively by starting
/// from an exercise in the Exercise Library and working backward ("add
/// this exercise to a new plan") - there was no way to start from the
/// Plans tab itself.
class PlanBuilderScreen extends ConsumerStatefulWidget {
  const PlanBuilderScreen({super.key});

  @override
  ConsumerState<PlanBuilderScreen> createState() => _PlanBuilderScreenState();
}

class _PlanBuilderScreenState extends ConsumerState<PlanBuilderScreen> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final List<_SessionDraft> _sessions = [];
  bool _saving = false;

  bool get _hasUnsavedChanges =>
      _nameController.text.trim().isNotEmpty ||
      _notesController.text.trim().isNotEmpty ||
      _sessions.isNotEmpty;

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty &&
      _sessions.any((s) => s.exercises.isNotEmpty);

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_nameController, _notesController]),
      builder: (context, _) => PopScope(
        canPop: _saving || !_hasUnsavedChanges,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _confirmDiscard();
        },
        child: _buildScaffold(context),
      ),
    );
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard this plan?'),
        content: const Text(
          "This plan hasn't been saved yet - everything entered here will "
          'be lost.',
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
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Build a new plan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Plan name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sessions', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed: _addSession,
                icon: const Icon(Icons.add),
                label: const Text('Add session'),
              ),
            ],
          ),
          if (_sessions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Add a session (a week/day/name grouping, e.g. "Week 1 • '
                'Mon • Push Day"), then add exercises to it from the '
                'library.',
              ),
            ),
          for (final session in _sessions) _SessionDraftCard(
            session: session,
            onAddExercise: () => _addExerciseTo(session),
            onRemoveExercise: (input) =>
                setState(() => session.exercises.remove(input)),
            onRemoveSession: () => setState(() => _sessions.remove(session)),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: _canSave && !_saving ? _save : null,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save plan'),
        ),
      ),
    );
  }

  Future<void> _addSession() async {
    final existingWeeks = _sessions.map((s) => s.weekNumber).toSet().toList()
      ..sort();
    final draft = await showDialog<_SessionDraft>(
      context: context,
      builder: (context) => _AddSessionDialog(existingWeeks: existingWeeks),
    );
    if (draft == null) return;
    setState(() => _sessions.add(draft));
  }

  Future<void> _addExerciseTo(_SessionDraft session) async {
    final exercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(builder: (context) => const ExercisePickerScreen()),
    );
    if (exercise == null || !mounted) return;

    final input = await showDialog<PlanExerciseInput>(
      context: context,
      builder: (context) => PrescribeExerciseDialog(
        exerciseName: exercise.name,
        exerciseId: exercise.id,
      ),
    );
    if (input == null) return;
    setState(() => session.exercises.add(input));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final db = ref.read(appDatabaseProvider);

    final sessionInputs = [
      for (final session in _sessions)
        if (session.exercises.isNotEmpty)
          PlanSessionInput(
            weekNumber: session.weekNumber,
            day: session.day,
            sessionName: session.sessionName,
            exercises: [
              for (var i = 0; i < session.exercises.length; i++)
                session.exercises[i].withOrder(i + 1),
            ],
          ),
    ];

    await db.planDao.createPlan(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      notes: _notesController.text.trim(),
      sessions: sessionInputs,
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_nameController.text.trim()} created.')),
    );
  }
}

class _SessionDraftCard extends StatelessWidget {
  final _SessionDraft session;
  final VoidCallback onAddExercise;
  final ValueChanged<PlanExerciseInput> onRemoveExercise;
  final VoidCallback onRemoveSession;

  const _SessionDraftCard({
    required this.session,
    required this.onAddExercise,
    required this.onRemoveExercise,
    required this.onRemoveSession,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Week ${session.weekNumber} • ${session.day} • '
                    '${session.sessionName}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Remove this session',
                  visualDensity: VisualDensity.compact,
                  onPressed: onRemoveSession,
                ),
              ],
            ),
            for (final exercise in session.exercises)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(exercise.exerciseName),
                subtitle: Text(
                  '${exercise.sets} x ${exercise.reps}'
                  '${exercise.weightIntensity.isEmpty ? '' : ' @ ${exercise.weightIntensity}'}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Remove this exercise',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onRemoveExercise(exercise),
                ),
              ),
            TextButton.icon(
              onPressed: onAddExercise,
              icon: const Icon(Icons.add),
              label: const Text('Add exercise'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddSessionDialog extends StatefulWidget {
  final List<int> existingWeeks;

  const _AddSessionDialog({required this.existingWeeks});

  @override
  State<_AddSessionDialog> createState() => _AddSessionDialogState();
}

class _AddSessionDialogState extends State<_AddSessionDialog> {
  late final _weekController = TextEditingController(
    text: '${widget.existingWeeks.isEmpty ? 1 : widget.existingWeeks.last}',
  );
  final _nameController = TextEditingController();
  String? _day;

  @override
  void dispose() {
    _weekController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add session'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _weekController,
              keyboardType: TextInputType.number,
              inputFormatters: integerInputFormatters,
              decoration: const InputDecoration(
                labelText: 'Week',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Which week of the plan this session belongs to - use 1 if '
              'every week looks the same; increase it for later weeks in a '
              'plan that changes over time.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (widget.existingWeeks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final week in widget.existingWeeks)
                    ActionChip(
                      label: Text('Week $week'),
                      onPressed: () =>
                          setState(() => _weekController.text = '$week'),
                    ),
                  ActionChip(
                    label: Text('Week ${widget.existingWeeks.last + 1} (new)'),
                    onPressed: () => setState(
                      () => _weekController.text =
                          '${widget.existingWeeks.last + 1}',
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Day',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _day,
                  hint: const Text('Choose a day'),
                  items: [
                    for (final day in _weekdays)
                      DropdownMenuItem(value: day, child: Text(day)),
                  ],
                  onChanged: (value) => setState(() => _day = value),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Session name',
                hintText: 'e.g. Push Day',
                border: OutlineInputBorder(),
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
        FilledButton(
          onPressed: () {
            final week = int.tryParse(_weekController.text.trim());
            if (week == null || _day == null || _nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fill in week, day, and a session name.')),
              );
              return;
            }
            Navigator.of(context).pop(
              _SessionDraft(
                weekNumber: week,
                day: _day!,
                sessionName: _nameController.text.trim(),
              ),
            );
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

