import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../data/daos/block_dao.dart';
import '../../data/daos/plan_dao.dart' show PlanExerciseInput;
import '../exercise_library/exercise_picker_screen.dart';
import '../shared/numeric_input_formatters.dart';
import '../shared/screen_padding.dart';
import 'exercise_prescription_form.dart';

final _blockDetailsProvider = FutureProvider.family<BlockDetails?, String>((
  ref,
  blockId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.blockDao.getBlockDetails(blockId);
});

/// Creates an empty block, prompting for its name, then opens it in
/// [BlockEditScreen] to add exercises right away. Shared by every "Insert
/// block" picker (`edit_session_screen.dart`, `plan_builder_screen.dart`) so
/// someone who wants a block that doesn't exist yet can create one on the
/// spot, instead of the only prior from-scratch path (Exercise Library ->
/// "Manage libraries & blocks" -> "+") - reported live as hidden enough that
/// building a whole plan/session first felt like the only way in. Returns
/// the new block's id, or null if the name prompt itself was cancelled -
/// the caller decides what to do if the block was left empty.
Future<String?> createBlockFromScratch(BuildContext context, WidgetRef ref) async {
  final name = await showDialog<String>(
    context: context,
    builder: (context) => const _RenamePromptDialog(
      title: 'New block',
      initialValue: '',
      confirmLabel: 'Create',
    ),
  );
  if (name == null || name.isEmpty || !context.mounted) return null;

  final db = ref.read(appDatabaseProvider);
  final blockId = await db.blockDao.createBlock(name: name, exercises: const []);
  if (!context.mounted) return null;

  await Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => BlockEditScreen(blockId: blockId)),
  );
  return context.mounted ? blockId : null;
}

/// Lets an already-saved block's exercises be edited: reorder, edit,
/// remove, or add more. Unlike `edit_session_screen.dart`, this always
/// mutates in place rather than forking - a block has no logged history of
/// its own to protect (only the stamped copies inserted into real sessions
/// do, and those are already independent - see `block_dao.dart`).
class BlockEditScreen extends ConsumerWidget {
  final String blockId;

  const BlockEditScreen({super.key, required this.blockId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(_blockDetailsProvider(blockId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          detailsAsync.valueOrNull?.block.name ?? 'Edit block',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Rename block',
            onPressed: detailsAsync.valueOrNull == null
                ? null
                : () => _rename(context, ref, detailsAsync.value!.block),
          ),
        ],
      ),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (details) {
          if (details == null) {
            return const Center(child: Text('Block not found.'));
          }
          return ListView(
            padding: screenListPadding(context),
            children: [
              if (details.exercises.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('This block has no exercises yet.'),
                ),
              for (var i = 0; i < details.exercises.length; i++)
                _BlockExerciseCard(
                  exercise: details.exercises[i],
                  isFirst: i == 0,
                  isLast: i == details.exercises.length - 1,
                  onEdit: () => _edit(context, ref, details.exercises[i]),
                  onDelete: () => _confirmDelete(
                    context,
                    ref,
                    details.exercises[i],
                  ),
                  onMove: (up) => _move(ref, details.exercises[i], up),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _addExercise(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add exercise'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _invalidate(WidgetRef ref) =>
      ref.invalidate(_blockDetailsProvider(blockId));

  Future<void> _rename(BuildContext context, WidgetRef ref, Block block) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _RenamePromptDialog(
        title: 'Rename block',
        initialValue: block.name,
        confirmLabel: 'Rename',
      ),
    );
    if (name == null || name.isEmpty || name == block.name) return;

    final db = ref.read(appDatabaseProvider);
    await db.blockDao.renameBlock(blockId, name);
    _invalidate(ref);
  }

  Future<void> _addExercise(BuildContext context, WidgetRef ref) async {
    final exercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(builder: (context) => const ExercisePickerScreen()),
    );
    if (exercise == null || !context.mounted) return;

    final input = await showDialog<PlanExerciseInput>(
      context: context,
      builder: (context) => PrescribeExerciseDialog(
        exerciseName: exercise.name,
        exerciseId: exercise.id,
      ),
    );
    if (input == null) return;

    final db = ref.read(appDatabaseProvider);
    await db.blockDao.addExerciseToBlock(
      blockId: blockId,
      input: BlockExerciseInput(
        order: 0,
        exerciseId: input.exerciseId,
        exerciseName: input.exerciseName,
        sets: input.sets,
        reps: input.reps,
        weightIntensity: input.weightIntensity,
        restSec: input.restSec,
        notes: input.notes,
        videoUrl: input.videoUrl,
      ),
    );
    _invalidate(ref);
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    BlockExercise exercise,
  ) async {
    // Reuses the DAO call directly rather than a shared dialog - the same
    // small sets/reps/weight/rest/notes shape `edit_session_screen.dart`'s
    // own `_EditExerciseDialog` already has, but that dialog is private to
    // that file and keyed to a `PlanExercise`, not a `BlockExercise`.
    final result = await showDialog<_BlockEditResult>(
      context: context,
      builder: (context) => _EditBlockExerciseDialog(exercise: exercise),
    );
    if (result == null || !context.mounted) return;

    final db = ref.read(appDatabaseProvider);
    await db.blockDao.updateBlockExercise(
      blockExerciseId: exercise.id,
      sets: result.sets,
      reps: result.reps,
      weightIntensity: result.weightIntensity,
      restSec: result.restSec,
      notes: result.notes,
    );
    _invalidate(ref);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BlockExercise exercise,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove "${exercise.exerciseName}"?'),
        content: const Text(
          'This only removes it from this block - any session that already '
          'used this block keeps its own copy exactly as it was.',
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
    await db.blockDao.removeBlockExercise(exercise.id);
    _invalidate(ref);
  }

  Future<void> _move(WidgetRef ref, BlockExercise exercise, bool up) async {
    final db = ref.read(appDatabaseProvider);
    await db.blockDao.moveBlockExercise(blockExerciseId: exercise.id, up: up);
    _invalidate(ref);
  }
}

class _BlockExerciseCard extends StatelessWidget {
  final BlockExercise exercise;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(bool up) onMove;

  const _BlockExerciseCard({
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

class _BlockEditResult {
  final int sets;
  final String reps;
  final String weightIntensity;
  final int? restSec;
  final String notes;

  const _BlockEditResult({
    required this.sets,
    required this.reps,
    required this.weightIntensity,
    required this.restSec,
    required this.notes,
  });
}

class _EditBlockExerciseDialog extends StatefulWidget {
  final BlockExercise exercise;

  const _EditBlockExerciseDialog({required this.exercise});

  @override
  State<_EditBlockExerciseDialog> createState() =>
      _EditBlockExerciseDialogState();
}

class _EditBlockExerciseDialogState extends State<_EditBlockExerciseDialog> {
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
                    _BlockEditResult(
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

/// Owns its own controller (disposed in its own `State.dispose()`, once the
/// route is actually removed) rather than one created inline by the caller
/// and disposed right after `showDialog`'s Future resolves - that races the
/// dialog's own exit transition, which keeps rebuilding the same `TextField`
/// for a few frames while it animates out. Same bug/fix
/// `plate_calculator_screen.dart`'s `_AddPlateDialog` already documents.
class _RenamePromptDialog extends StatefulWidget {
  final String title;
  final String initialValue;
  final String confirmLabel;

  const _RenamePromptDialog({
    required this.title,
    required this.initialValue,
    required this.confirmLabel,
  });

  @override
  State<_RenamePromptDialog> createState() => _RenamePromptDialogState();
}

class _RenamePromptDialogState extends State<_RenamePromptDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(controller: _controller, autofocus: true),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(_controller.text.trim()),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
