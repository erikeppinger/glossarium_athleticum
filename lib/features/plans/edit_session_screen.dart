import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../data/daos/plan_dao.dart';
import '../shared/numeric_input_formatters.dart';
import 'plan_providers.dart';

final _sessionDetailsProvider = FutureProvider.family<PlanSessionDetails?, int>(
  (ref, sessionId) {
    final db = ref.watch(appDatabaseProvider);
    return db.planDao.getSessionDetails(sessionId);
  },
);

/// Lets an already-created session's exercises be edited in place: change
/// sets/reps/weight/rest/notes, reorder, or remove. Previously a plan could
/// only be built up (via import or "Add to plan") and never adjusted, which
/// made it awkward to evolve a plan over weeks.
class EditSessionScreen extends ConsumerWidget {
  final int sessionId;
  final String planId;

  const EditSessionScreen({
    super.key,
    required this.sessionId,
    required this.planId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(_sessionDetailsProvider(sessionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit session')),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (details) {
          if (details == null) {
            return const Center(child: Text('Session not found.'));
          }
          if (details.exercises.isEmpty) {
            return const Center(
              child: Text('This session has no exercises yet.'),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${details.session.sessionName} • Week ${details.session.weekNumber} • ${details.session.day}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < details.exercises.length; i++)
                _ExerciseCard(
                  exercise: details.exercises[i],
                  isFirst: i == 0,
                  isLast: i == details.exercises.length - 1,
                  onEdit: () =>
                      _edit(context, ref, details.exercises[i]),
                  onDelete: () =>
                      _delete(context, ref, details.exercises[i]),
                  onMove: (up) => _move(ref, details.exercises[i], up),
                ),
            ],
          );
        },
      ),
    );
  }

  void _invalidate(WidgetRef ref) {
    ref.invalidate(_sessionDetailsProvider(sessionId));
    ref.invalidate(planDetailsProvider(planId));
  }

  Future<void> _move(WidgetRef ref, PlanExercise exercise, bool up) async {
    final db = ref.read(appDatabaseProvider);
    await db.planDao.movePlanExercise(planExerciseId: exercise.id, up: up);
    _invalidate(ref);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    PlanExercise exercise,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove exercise?'),
        content: Text(
          'Remove "${exercise.exerciseName}" from this session? '
          'Previously logged workouts are not affected.',
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
    if (confirmed != true) return;

    final db = ref.read(appDatabaseProvider);
    await db.planDao.deletePlanExercise(exercise.id);
    _invalidate(ref);
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    PlanExercise exercise,
  ) async {
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
    _invalidate(ref);
  }
}

class _ExerciseCard extends StatelessWidget {
  final PlanExercise exercise;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(bool up) onMove;

  const _ExerciseCard({
    required this.exercise,
    required this.isFirst,
    required this.isLast,
    required this.onEdit,
    required this.onDelete,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
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
              '${exercise.notes.isEmpty ? '' : '\n${exercise.notes}'}',
            ),
          ),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            children: [
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
