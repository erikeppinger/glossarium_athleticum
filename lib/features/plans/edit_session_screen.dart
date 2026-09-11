import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../data/daos/plan_dao.dart';
import '../../logic/superset_info.dart';
import '../exercise_library/exercise_picker_screen.dart';
import '../shared/info_dialog.dart';
import '../shared/numeric_input_formatters.dart';
import 'exercise_prescription_form.dart';
import 'plan_detail_screen.dart';
import 'plan_fork.dart';
import 'plan_providers.dart';

final _sessionDetailsProvider = FutureProvider.family<PlanSessionDetails?, int>(
  (ref, sessionId) {
    final db = ref.watch(appDatabaseProvider);
    return db.planDao.getSessionDetails(sessionId);
  },
);

/// Lets an already-created session's exercises be edited in place: change
/// sets/reps/weight/rest/notes, reorder, remove, or group into a superset.
/// Previously a plan could only be built up (via import or "Add to plan")
/// and never adjusted, which made it awkward to evolve a plan over weeks.
class EditSessionScreen extends ConsumerStatefulWidget {
  final int sessionId;
  final String planId;

  const EditSessionScreen({
    super.key,
    required this.sessionId,
    required this.planId,
  });

  @override
  ConsumerState<EditSessionScreen> createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends ConsumerState<EditSessionScreen> {
  int get sessionId => widget.sessionId;
  String get planId => widget.planId;

  bool _selecting = false;
  final Set<int> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(_sessionDetailsProvider(sessionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit session'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'What is a superset?',
            onPressed: () => showInfoDialog(
              context,
              title: 'What is a superset?',
              content: supersetExplanationNote,
            ),
          ),
          TextButton(
            onPressed: () => setState(() {
              _selecting = !_selecting;
              _selectedIds.clear();
            }),
            child: Text(_selecting ? 'Cancel' : 'Group into superset'),
          ),
        ],
      ),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (details) {
          if (details == null) {
            return const Center(child: Text('Session not found.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${details.session.sessionName} • Week ${details.session.weekNumber} • ${details.session.day}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              if (_selecting)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('Select 2 or more exercises to do back-to-back.'),
                ),
              if (details.exercises.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('This session has no exercises yet.'),
                ),
              for (var i = 0; i < details.exercises.length; i++)
                _ExerciseCard(
                  exercise: details.exercises[i],
                  isFirst: i == 0,
                  isLast: i == details.exercises.length - 1,
                  selecting: _selecting,
                  selected: _selectedIds.contains(details.exercises[i].id),
                  onSelectedChanged: (checked) => setState(() {
                    if (checked) {
                      _selectedIds.add(details.exercises[i].id);
                    } else {
                      _selectedIds.remove(details.exercises[i].id);
                    }
                  }),
                  onEdit: () => _edit(details.exercises[i]),
                  onDelete: () => _removeExercise(details, details.exercises[i]),
                  onMove: (up) => _move(details.exercises[i], up),
                  onUngroup: () => _ungroup(details.exercises[i]),
                ),
              const SizedBox(height: 8),
              if (!_selecting)
                OutlinedButton.icon(
                  onPressed: () => _addExercise(details),
                  icon: const Icon(Icons.add),
                  label: const Text('Add exercise'),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: _selecting
          ? SafeArea(
              minimum: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _selectedIds.length >= 2 ? _confirmGroup : null,
                child: Text('Group selected (${_selectedIds.length})'),
              ),
            )
          : null,
    );
  }

  void _invalidate() {
    ref.invalidate(_sessionDetailsProvider(sessionId));
    ref.invalidate(planDetailsProvider(planId));
  }

  Future<void> _confirmGroup() async {
    final db = ref.read(appDatabaseProvider);
    await db.planDao.setSupersetGroup(_selectedIds.toList());
    setState(() {
      _selecting = false;
      _selectedIds.clear();
    });
    _invalidate();
  }

  Future<void> _ungroup(PlanExercise exercise) async {
    final db = ref.read(appDatabaseProvider);
    await db.planDao.clearSupersetGroup(exercise.id);
    _invalidate();
  }

  Future<void> _move(PlanExercise exercise, bool up) async {
    final db = ref.read(appDatabaseProvider);
    await db.planDao.movePlanExercise(planExerciseId: exercise.id, up: up);
    _invalidate();
  }

  /// Removing an exercise is a structural change, like adding one (see
  /// [_addExercise]) - it forks a new plan rather than mutating this one.
  Future<void> _removeExercise(
    PlanSessionDetails details,
    PlanExercise exercise,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove exercise?'),
        content: Text(
          'Removing "${exercise.exerciseName}" saves this session\'s plan '
          'under a new name, so the original plan is left exactly as it '
          'is. Previously logged workouts are not affected either way.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final remaining = [
      for (final e in details.exercises)
        if (e.id != exercise.id) e.toInput(),
    ];
    await _forkAndNavigate(details, remaining);
  }

  /// Adding an exercise to an already-existing session is a structural
  /// change - rather than mutating this plan in place (the way
  /// `PlanDao.addExerciseToSession` does for a plan still being built via
  /// the Exercise Library's own "Add to plan" flow), it forks a new plan
  /// with the addition, leaving the plan actually open here untouched. See
  /// plan_fork.dart's own doc comment for the full reasoning.
  Future<void> _addExercise(PlanSessionDetails details) async {
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
    if (input == null || !mounted) return;

    final updated = [
      for (final e in details.exercises) e.toInput(),
      input,
    ];
    await _forkAndNavigate(details, updated);
  }

  /// Shared by [_addExercise]/[_removeExercise]: asks for the forked
  /// plan's name (pre-filled, editable), performs the fork, then navigates
  /// to the *new* plan's detail screen - staying on this session's edit
  /// screen would be confusing once a different plan now holds the change.
  Future<void> _forkAndNavigate(
    PlanSessionDetails details,
    List<PlanExerciseInput> newExercises,
  ) async {
    // Renumber 1..N regardless of the source rows' original order values -
    // both callers build this list in the final display order already.
    final ordered = [
      for (var i = 0; i < newExercises.length; i++)
        newExercises[i].withOrder(i + 1),
    ];

    final db = ref.read(appDatabaseProvider);
    final source = await db.planDao.getPlanDetails(planId);
    if (source == null || !mounted) return;

    final newName = await _promptForkName(source.plan.name);
    if (newName == null || !mounted) return;

    final newPlanId = await forkPlanWithModifiedSession(
      db,
      sourcePlanId: planId,
      newPlanName: newName,
      editedSessionId: sessionId,
      newExercisesForEditedSession: ordered,
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PlanDetailScreen(planId: newPlanId),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Created "$newName" with your changes.')),
    );
  }

  Future<String?> _promptForkName(String planName) {
    final controller = TextEditingController(text: '$planName (edited)');
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save as a new plan'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'New plan name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((name) {
      controller.dispose();
      return name == null || name.isEmpty ? null : name;
    });
  }

  Future<void> _edit(PlanExercise exercise) async {
    final result = await showDialog<_EditResult>(
      context: context,
      builder: (context) => _EditExerciseDialog(exercise: exercise),
    );
    if (result == null) return;

    final db = ref.read(appDatabaseProvider);
    await db.planDao.updatePlanExercise(
      planExerciseId: exercise.id,
      sets: result.sets,
      reps: result.reps,
      weightIntensity: result.weightIntensity,
      restSec: result.restSec,
      notes: result.notes,
    );
    _invalidate();
  }
}

class _ExerciseCard extends StatelessWidget {
  final PlanExercise exercise;
  final bool isFirst;
  final bool isLast;
  final bool selecting;
  final bool selected;
  final ValueChanged<bool> onSelectedChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(bool up) onMove;
  final VoidCallback onUngroup;

  const _ExerciseCard({
    required this.exercise,
    required this.isFirst,
    required this.isLast,
    required this.selecting,
    required this.selected,
    required this.onSelectedChanged,
    required this.onEdit,
    required this.onDelete,
    required this.onMove,
    required this.onUngroup,
  });

  @override
  Widget build(BuildContext context) {
    if (selecting) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: CheckboxListTile(
          value: selected,
          onChanged: (checked) => onSelectedChanged(checked ?? false),
          title: Text(exercise.exerciseName),
          subtitle: Text('${exercise.sets} x ${exercise.reps}'),
        ),
      );
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(exercise.exerciseName),
            subtitle: Text(
              '${exercise.sets} x ${exercise.reps}'
              '${exercise.weightIntensity.isEmpty ? '' : ' @ ${exercise.weightIntensity}'}'
              '${exercise.restSec == null ? '' : ' • ${exercise.restSec}s rest'}'
              '${exercise.supersetGroupId == null ? '' : ' • Superset group ${exercise.supersetGroupId}'}'
              '${exercise.notes.isEmpty ? '' : '\n${exercise.notes}'}',
            ),
          ),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            children: [
              if (exercise.supersetGroupId != null)
                IconButton(
                  icon: const Icon(Icons.link_off),
                  tooltip: 'Ungroup this exercise',
                  onPressed: onUngroup,
                ),
              IconButton(
                icon: const Icon(Icons.arrow_upward),
                tooltip: 'Move up',
                onPressed: isFirst ? null : () => onMove(true),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward),
                tooltip: 'Move down',
                onPressed: isLast ? null : () => onMove(false),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit',
                onPressed: onEdit,
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                tooltip: 'Remove',
                onPressed: onDelete,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditResult {
  final int sets;
  final String reps;
  final String weightIntensity;
  final int? restSec;
  final String notes;

  const _EditResult({
    required this.sets,
    required this.reps,
    required this.weightIntensity,
    required this.restSec,
    required this.notes,
  });
}

class _EditExerciseDialog extends StatefulWidget {
  final PlanExercise exercise;

  const _EditExerciseDialog({required this.exercise});

  @override
  State<_EditExerciseDialog> createState() => _EditExerciseDialogState();
}

class _EditExerciseDialogState extends State<_EditExerciseDialog> {
  late final _setsController = TextEditingController(
    text: '${widget.exercise.sets}',
  );
  late final _repsController = TextEditingController(
    text: widget.exercise.reps,
  );
  late final _weightController = TextEditingController(
    text: widget.exercise.weightIntensity,
  );
  late final _restController = TextEditingController(
    text: widget.exercise.restSec?.toString() ?? '',
  );
  late final _notesController = TextEditingController(
    text: widget.exercise.notes,
  );

  late final _controllers = [
    _setsController,
    _repsController,
    _weightController,
    _restController,
    _notesController,
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canSave =>
      int.tryParse(_setsController.text.trim()) != null &&
      _repsController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.exercise.exerciseName),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _setsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: integerInputFormatters,
                    decoration: const InputDecoration(labelText: 'Sets'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    decoration: const InputDecoration(labelText: 'Reps'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight/Intensity',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _restController,
                    keyboardType: TextInputType.number,
                    inputFormatters: integerInputFormatters,
                    decoration: const InputDecoration(labelText: 'Rest (sec)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ListenableBuilder(
          listenable: Listenable.merge(_controllers),
          builder: (context, _) => FilledButton(
            onPressed: _canSave
                ? () => Navigator.of(context).pop(
                    _EditResult(
                      sets: int.parse(_setsController.text.trim()),
                      reps: _repsController.text.trim(),
                      weightIntensity: _weightController.text.trim(),
                      restSec: int.tryParse(_restController.text.trim()),
                      notes: _notesController.text.trim(),
                    ),
                  )
                : null,
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }
}
