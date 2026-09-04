import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../data/local_storage.dart';
import '../plans/add_exercise_to_plan_screen.dart';
import '../plans/plan_providers.dart';
import '../shared/attachment_image.dart';
import 'exercise_library_providers.dart';

const _difficulties = ['Beginner', 'Intermediate', 'Advanced'];
const _measurementTypes = [
  'Weight x Reps',
  'Time',
  'Distance',
  'Max Load',
  'Reps',
];

/// Creates a new exercise, or edits an existing custom one.
///
/// One screen for both: the fields, validation, and preview are identical, and
/// a separate near-duplicate edit screen would drift out of sync. Pass
/// [existing] to edit; omit it to create.
class CreateExerciseScreen extends ConsumerStatefulWidget {
  /// The exercise being edited, or null when creating a new one.
  final Exercise? existing;

  const CreateExerciseScreen({super.key, this.existing});

  @override
  ConsumerState<CreateExerciseScreen> createState() =>
      _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends ConsumerState<CreateExerciseScreen> {
  bool _previewing = false;
  bool _saving = false;

  Exercise? get _existing => widget.existing;
  bool get _isEditing => _existing != null;

  late String? _category = _existing?.category;
  late String? _difficulty = _existing?.difficulty;
  late String? _measurementType = _existing?.measurementType;
  late String? _imagePath = _existing?.imagePath;

  late final String? _initialCategory = _existing?.category;
  late final String? _initialDifficulty = _existing?.difficulty;
  late final String? _initialMeasurementType = _existing?.measurementType;
  late final String? _initialImagePath = _existing?.imagePath;

  late final _nameController = TextEditingController(
    text: _existing?.name ?? '',
  );
  late final _movementPatternController = TextEditingController(
    text: _existing?.movementPattern ?? '',
  );
  late final _muscleGroupsController = TextEditingController(
    text: _existing?.muscleGroups ?? '',
  );
  late final _equipmentController = TextEditingController(
    text: _existing?.equipment ?? '',
  );
  late final _descriptionController = TextEditingController(
    text: _existing?.description ?? '',
  );
  late final _safetyNotesController = TextEditingController(
    text: _existing?.safetyNotes ?? '',
  );
  late final _videoReferenceController = TextEditingController(
    text: _existing?.videoReference ?? '',
  );
  late final _authorController = TextEditingController(
    text: _existing?.author ?? '',
  );

  late final _controllers = [
    _nameController,
    _movementPatternController,
    _muscleGroupsController,
    _equipmentController,
    _descriptionController,
    _safetyNotesController,
    _videoReferenceController,
    _authorController,
  ];
  late final _initialControllerTexts = _controllers
      .map((c) => c.text)
      .toList(growable: false);

  bool get _hasUnsavedChanges {
    if (_category != _initialCategory) return true;
    if (_difficulty != _initialDifficulty) return true;
    if (_measurementType != _initialMeasurementType) return true;
    if (_imagePath != _initialImagePath) return true;
    for (var i = 0; i < _controllers.length; i++) {
      if (_controllers[i].text != _initialControllerTexts[i]) return true;
    }
    return false;
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canPreview =>
      _nameController.text.trim().isNotEmpty &&
      _category != null &&
      _category!.isNotEmpty &&
      _difficulty != null &&
      _measurementType != null;

  @override
  Widget build(BuildContext context) {
    // canPop is read fresh on every pop attempt from whatever's last built,
    // but plain TextFields don't rebuild their parent on each keystroke - so
    // without this listener, typing wouldn't ever flip canPop to false.
    return ListenableBuilder(
      listenable: Listenable.merge(_controllers),
      builder: (context, _) => PopScope(
        // The form (photo included) lives only in memory until "Save" -
        // backing out silently would otherwise discard it with no way back.
        canPop: _saving || !_hasUnsavedChanges,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _confirmDiscard();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              _previewing
                  ? 'Preview'
                  : _isEditing
                  ? 'Edit exercise'
                  : 'Create exercise',
            ),
          ),
          body: _saving
              ? const Center(child: CircularProgressIndicator())
              : _previewing
              ? _buildPreview(context)
              : _buildForm(context),
        ),
      ),
    );
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: Text(
          _isEditing
              ? 'Your edits to "${_existing!.name}" have not been saved.'
              : 'This exercise has not been saved yet.',
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

  Widget _buildForm(BuildContext context) {
    final categoriesAsync = ref.watch(exerciseCategoriesProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ImagePickerField(
          fileName: _imagePath,
          onPicked: (name) => setState(() => _imagePath = name),
          onCleared: () => setState(() => _imagePath = null),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        categoriesAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (categories) => _PickerField(
            label: 'Category',
            value: _category,
            onTap: () => _pickCategory(context, categories),
          ),
        ),
        const SizedBox(height: 12),
        _PickerField(
          label: 'Difficulty',
          value: _difficulty,
          onTap: () => _pickFromList(
            context,
            title: 'Difficulty',
            options: _difficulties,
            onPicked: (v) => setState(() => _difficulty = v),
          ),
        ),
        const SizedBox(height: 12),
        _PickerField(
          label: 'Measurement type',
          value: _measurementType,
          onTap: () => _pickMeasurementType(context),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _movementPatternController,
          decoration: const InputDecoration(
            labelText: 'Movement pattern',
            hintText: 'e.g. Push, Pull, Hinge',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _muscleGroupsController,
          decoration: const InputDecoration(
            labelText: 'Muscle groups',
            hintText: 'Comma-separated, e.g. Chest, Triceps',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _equipmentController,
          decoration: const InputDecoration(
            labelText: 'Equipment',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _safetyNotesController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Safety notes',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _videoReferenceController,
          decoration: const InputDecoration(
            labelText: 'Reference video URL',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _authorController,
          decoration: const InputDecoration(
            labelText: 'Author (optional)',
            hintText: "e.g. a coach's name",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        ListenableBuilder(
          listenable: Listenable.merge(_controllers),
          builder: (context, _) => FilledButton(
            onPressed: _canPreview
                ? () => setState(() => _previewing = true)
                : null,
            child: const Text('Preview'),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(BuildContext context) {
    final muscleGroups = _muscleGroupsController.text
        .split(',')
        .map((g) => g.trim())
        .where((g) => g.isNotEmpty)
        .toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                _nameController.text.trim(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(_category!)),
                  if (_movementPatternController.text.trim().isNotEmpty)
                    Chip(label: Text(_movementPatternController.text.trim())),
                  if (_equipmentController.text.trim().isNotEmpty)
                    Chip(label: Text(_equipmentController.text.trim())),
                  Chip(label: Text(_difficulty!)),
                  Chip(label: Text(_measurementType!)),
                ],
              ),
              if (muscleGroups.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Muscle groups',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(muscleGroups.join(', ')),
              ],
              if (_descriptionController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(_descriptionController.text.trim()),
              ],
              if (_safetyNotesController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Safety notes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(_safetyNotesController.text.trim()),
              ],
              if (_videoReferenceController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Reference video',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(_videoReferenceController.text.trim()),
              ],
              if (_authorController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Author', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(_authorController.text.trim()),
              ],
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _previewing = false),
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(
                      _isEditing ? 'Save changes' : 'Save exercise',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickCategory(
    BuildContext context,
    List<String> existing,
  ) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Category'),
        children: [
          for (final category in existing)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(category),
              child: Text(category),
            ),
          SimpleDialogOption(
            onPressed: () async {
              Navigator.of(context).pop();
              final custom = await _promptText(context, 'New category');
              if (custom != null && custom.trim().isNotEmpty) {
                setState(() => _category = custom.trim());
              }
            },
            child: const Text('+ New category'),
          ),
        ],
      ),
    );
    if (choice != null) setState(() => _category = choice);
  }

  Future<void> _pickMeasurementType(BuildContext context) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Measurement type'),
        children: [
          for (final type in _measurementTypes)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(type),
              child: Text(type),
            ),
        ],
      ),
    );
    if (choice != null) setState(() => _measurementType = choice);
  }

  Future<void> _pickFromList(
    BuildContext context, {
    required String title,
    required List<String> options,
    required ValueChanged<String> onPicked,
  }) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(title),
        children: [
          for (final option in options)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(option),
              child: Text(option),
            ),
        ],
      ),
    );
    if (choice != null) onPicked(choice);
  }

  Future<String?> _promptText(BuildContext context, String label) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final db = ref.read(appDatabaseProvider);
    // Editing reuses the existing id so plans and logged sets keep pointing
    // at the same row; only creating mints a new one.
    final id = _existing?.id ?? const Uuid().v4();
    final name = _nameController.text.trim();

    // An image that was swapped out or removed leaves an orphan file behind
    // otherwise - nothing else references it, so clean it up now.
    final previousImage = _existing?.imagePath;
    if (previousImage != null && previousImage != _imagePath) {
      await deleteAttachment(previousImage);
    }

    await db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: id,
        name: name,
        category: _category!,
        movementPattern: _movementPatternController.text.trim(),
        muscleGroups: _muscleGroupsController.text.trim(),
        equipment: _equipmentController.text.trim(),
        difficulty: _difficulty!,
        measurementType: _measurementType!,
        description: Value(_descriptionController.text.trim()),
        safetyNotes: Value(_safetyNotesController.text.trim()),
        videoReference: Value(_videoReferenceController.text.trim()),
        isCustom: const Value(true),
        author: Value(
          _authorController.text.trim().isEmpty
              ? null
              : _authorController.text.trim(),
        ),
        imagePath: Value(_imagePath),
        // Preserve provenance on edit - re-saving an imported exercise
        // shouldn't make it look like it was created from scratch.
        sourcePlanName: Value(_existing?.sourcePlanName),
      ),
    );
    // One-shot FutureProviders - won't notice this write on their own.
    ref.invalidate(filteredExercisesProvider);
    ref.invalidate(exerciseCategoriesProvider);
    ref.invalidate(creatorFilterOptionsProvider);
    ref.invalidate(allExercisesForMatchingProvider);

    if (!mounted) return;

    // Editing already has somewhere to go back to; only creation needs the
    // "what now?" prompt.
    if (_isEditing) {
      Navigator.of(context).pop(true);
      return;
    }

    final addToPlan = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exercise saved'),
        content: Text('"$name" was added to your exercise library.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Done'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Add to plan'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (addToPlan == true) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              AddExerciseToPlanScreen(exerciseId: id, exerciseName: name),
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _PickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 24,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(value ?? 'Choose $label'.toLowerCase()),
          ),
        ),
      ),
    );
  }
}

/// Picks an image for an exercise from the device.
///
/// User-supplied rather than bundled stock imagery, deliberately: shipping
/// scraped exercise photos would be a licensing problem for anyone publishing
/// the app, and a photo of your own bar setup or a coach's whiteboard cue is
/// more useful than a generic render anyway.
class _ImagePickerField extends StatefulWidget {
  final String? fileName;
  final ValueChanged<String> onPicked;
  final VoidCallback onCleared;

  const _ImagePickerField({
    required this.fileName,
    required this.onPicked,
    required this.onCleared,
  });

  @override
  State<_ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<_ImagePickerField> {
  bool _picking = false;

  Future<void> _pick() async {
    setState(() => _picking = true);
    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      final path = file?.path;
      if (path == null) return;
      // Copied into the app's own attachments directory so the image
      // survives the source being moved or deleted, and so "delete all data"
      // can reliably wipe it.
      widget.onPicked(await saveAttachment(path));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_picking) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.fileName == null) {
      return InkWell(
        onTap: _pick,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined, color: scheme.primary),
              const SizedBox(height: 6),
              Text('Add a photo', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                'Optional - your own image of the setup or cue',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AttachmentImage(
            fileName: widget.fileName!,
            height: 180,
            width: double.infinity,
            semanticLabel: 'Your selected photo',
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Row(
            children: [
              _OverlayButton(
                icon: Icons.edit,
                tooltip: 'Change photo',
                onPressed: _pick,
              ),
              const SizedBox(width: 6),
              _OverlayButton(
                icon: Icons.close,
                tooltip: 'Remove photo',
                onPressed: widget.onCleared,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _OverlayButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // A hand-rolled Material+InkWell (rather than IconButton, everywhere
    // else's pattern) for a compact circular overlay chip - but that meant
    // no tooltip and no accessible name at all, missed by an earlier
    // accessibility pass since it only checked real IconButtons. IconButton
    // itself, restyled, gives the same look back with the label for free.
    return IconButton(
      icon: Icon(icon, size: 18, color: Colors.white),
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black54,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
