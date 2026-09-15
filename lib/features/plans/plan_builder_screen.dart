import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../data/daos/block_dao.dart';
import '../../data/daos/plan_dao.dart';
import '../../logic/block_info.dart';
import '../../logic/superset_info.dart';
import '../exercise_library/exercise_picker_screen.dart';
import '../shared/info_dialog.dart';
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
            onInsertBlock: () => _insertBlockInto(session),
            onRemoveExercise: (input) =>
                setState(() => session.exercises.remove(input)),
            onRemoveSession: () => setState(() => _sessions.remove(session)),
            onGroupExercises: () => _groupExercisesIn(session),
            onUngroupExercise: (input) => _ungroupExercise(session, input),
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

  /// Nothing is written to the database until "Save plan" - so unlike
  /// `edit_session_screen.dart`'s own "Insert block" (which edits an
  /// already-saved session and has to fork), this just appends the block's
  /// exercises straight into the in-memory draft. Still a fresh, independent
  /// stamped copy of each one (`toPlanInput`), not a link back to the block.
  Future<void> _insertBlockInto(_SessionDraft session) async {
    final db = ref.read(appDatabaseProvider);
    final blocks = await db.blockDao.getAllBlocks();
    if (!mounted) return;

    if (blocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No blocks yet - build one from an existing session\'s '
            'exercises via "Save as block", or from Manage libraries & '
            'blocks.',
          ),
        ),
      );
      return;
    }

    final chosen = await showDialog<Block>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Insert block'),
        children: [
          for (final block in blocks)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(block),
              child: Text(block.name),
            ),
        ],
      ),
    );
    if (chosen == null || !mounted) return;

    final blockDetails = await db.blockDao.getBlockDetails(chosen.id);
    if (blockDetails == null) return;

    setState(() {
      for (final e in blockDetails.exercises) {
        session.exercises.add(e.toPlanInput(order: 0));
      }
    });
  }

  Future<void> _groupExercisesIn(_SessionDraft session) async {
    final selected = await showDialog<List<PlanExerciseInput>>(
      context: context,
      builder: (context) => _GroupExercisesDialog(exercises: session.exercises),
    );
    if (selected == null || selected.length < 2) return;

    final usedGroupIds = session.exercises
        .where((e) => !selected.contains(e))
        .map((e) => e.supersetGroupId)
        .whereType<int>()
        .toSet();
    var newGroupId = 1;
    while (usedGroupIds.contains(newGroupId)) {
      newGroupId++;
    }

    setState(() {
      for (final exercise in selected) {
        final index = session.exercises.indexOf(exercise);
        session.exercises[index] = exercise.withSupersetGroupId(newGroupId);
      }
    });
  }

  void _ungroupExercise(_SessionDraft session, PlanExerciseInput exercise) {
    setState(() {
      final index = session.exercises.indexOf(exercise);
      session.exercises[index] = exercise.withSupersetGroupId(null);
    });
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
  final VoidCallback onInsertBlock;
  final ValueChanged<PlanExerciseInput> onRemoveExercise;
  final VoidCallback onRemoveSession;
  final VoidCallback onGroupExercises;
  final ValueChanged<PlanExerciseInput> onUngroupExercise;

  const _SessionDraftCard({
    required this.session,
    required this.onAddExercise,
    required this.onInsertBlock,
    required this.onRemoveExercise,
    required this.onRemoveSession,
    required this.onGroupExercises,
    required this.onUngroupExercise,
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
                  '${exercise.weightIntensity.isEmpty ? '' : ' @ ${exercise.weightIntensity}'}'
                  '${exercise.supersetGroupId == null ? '' : ' • Superset group ${exercise.supersetGroupId}'}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (exercise.supersetGroupId != null)
                      IconButton(
                        icon: const Icon(Icons.link_off, size: 18),
                        tooltip: 'Ungroup this exercise',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => onUngroupExercise(exercise),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: 'Remove this exercise',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => onRemoveExercise(exercise),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onAddExercise,
                  icon: const Icon(Icons.add),
                  label: const Text('Add exercise'),
                ),
                TextButton.icon(
                  onPressed: onInsertBlock,
                  icon: const Icon(Icons.dynamic_feed_outlined),
                  label: const Text('Insert block'),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 18),
                  tooltip: 'What is a block?',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => showInfoDialog(
                    context,
                    title: 'What is a block?',
                    content: blockExplanationNote,
                  ),
                ),
                if (session.exercises.length >= 2) ...[
                  TextButton.icon(
                    onPressed: onGroupExercises,
                    icon: const Icon(Icons.link),
                    label: const Text('Group exercises'),
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
              ],
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

/// A checkbox list picking 2+ of a session's exercises to group into a
/// superset - selecting an already-grouped exercise moves it into the new
/// group instead of leaving it in its old one.
class _GroupExercisesDialog extends StatefulWidget {
  final List<PlanExerciseInput> exercises;

  const _GroupExercisesDialog({required this.exercises});

  @override
  State<_GroupExercisesDialog> createState() => _GroupExercisesDialogState();
}

class _GroupExercisesDialogState extends State<_GroupExercisesDialog> {
  final Set<PlanExerciseInput> _selected = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Group into a superset'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose 2 or more exercises to do back-to-back.'),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final exercise in widget.exercises)
                    CheckboxListTile(
                      value: _selected.contains(exercise),
                      title: Text(exercise.exerciseName),
                      subtitle: exercise.supersetGroupId == null
                          ? null
                          : Text('Currently in group ${exercise.supersetGroupId}'),
                      onChanged: (checked) => setState(() {
                        if (checked ?? false) {
                          _selected.add(exercise);
                        } else {
                          _selected.remove(exercise);
                        }
                      }),
                    ),
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
        FilledButton(
          onPressed: _selected.length < 2
              ? null
              : () => Navigator.of(context).pop(_selected.toList()),
          child: const Text('Group'),
        ),
      ],
    );
  }
}
