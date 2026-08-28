import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../plans/add_exercise_to_plan_screen.dart';
import 'exercise_library_providers.dart';

const _difficulties = ['Beginner', 'Intermediate', 'Advanced'];
const _measurementTypes = [
  'Weight x Reps',
  'Time',
  'Distance',
  'Max Load',
  'Reps',
];

/// Lets the user define a brand-new exercise (not just a bare name, like the
/// unmatched-exercise-during-import flow does) - full library metadata plus
/// a preview before saving, then a prompt to add it straight into a plan.
class CreateExerciseScreen extends ConsumerStatefulWidget {
  const CreateExerciseScreen({super.key});

  @override
  ConsumerState<CreateExerciseScreen> createState() =>
      _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends ConsumerState<CreateExerciseScreen> {
  bool _previewing = false;
  bool _saving = false;

  String? _category;
  String? _difficulty;
  String? _measurementType;

  final _nameController = TextEditingController();
  final _movementPatternController = TextEditingController();
  final _muscleGroupsController = TextEditingController();
  final _equipmentController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _safetyNotesController = TextEditingController();
  final _videoReferenceController = TextEditingController();

  late final _controllers = [
    _nameController,
    _movementPatternController,
    _muscleGroupsController,
    _equipmentController,
    _descriptionController,
    _safetyNotesController,
    _videoReferenceController,
  ];

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
    return Scaffold(
      appBar: AppBar(
        title: Text(_previewing ? 'Preview' : 'Create exercise'),
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator())
          : _previewing
          ? _buildPreview(context)
          : _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    final categoriesAsync = ref.watch(exerciseCategoriesProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
                    child: const Text('Save exercise'),
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
    final id = const Uuid().v4();
    final name = _nameController.text.trim();

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
      ),
    );
    // One-shot FutureProviders - won't notice this write on their own.
    ref.invalidate(filteredExercisesProvider);
    ref.invalidate(exerciseCategoriesProvider);

    if (!mounted) return;
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
