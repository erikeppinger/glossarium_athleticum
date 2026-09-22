import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../data/local_storage.dart';
import '../../logic/exercise_images.dart';
import '../../logic/video_embedding.dart';
import '../plans/add_exercise_to_plan_screen.dart';
import '../plans/plan_providers.dart';
import '../shared/attachment_image.dart';
import 'exercise_library_providers.dart';

/// Shared with the spreadsheet importer (exercise_spreadsheet_parser.dart)
/// so the two never validate against different value sets.
const difficulties = ['Beginner', 'Intermediate', 'Advanced'];
const measurementTypes = [
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

  /// Editing a seed-library exercise can't mutate it in place - it's
  /// reseeded on every launch, so the edit would silently be undone (see
  /// exercise_detail_screen.dart's own note on this). Instead it saves as a
  /// brand-new custom exercise, leaving the original untouched - the
  /// "moniker: Custom or edited" the user asked for directly, made visible
  /// by pre-filling the name with "(edited)" below rather than a new hidden
  /// data field. Editing an *already*-custom exercise is unaffected -
  /// still a true in-place update, same id.
  bool get _willFork => _isEditing && !_existing!.isCustom;

  late String? _category = _existing?.category;
  late String? _difficulty = _existing?.difficulty;
  late String? _measurementType = _existing?.measurementType;
  // A fork never starts pre-loaded with the original's photos - sharing the
  // same attachment filenames would let removing/replacing one here delete
  // a file the original exercise still points to (see _save's own note).
  late List<String> _imagePaths = _willFork
      ? []
      : parseImagePaths(_existing?.imagePaths);

  late final String? _initialCategory = _existing?.category;
  late final String? _initialDifficulty = _existing?.difficulty;
  late final String? _initialMeasurementType = _existing?.measurementType;
  late final List<String> _initialImagePaths = List.of(_imagePaths);

  // A fork never starts with the original's embedding opt-in either (same
  // reasoning as photos, just above) - forking asserts the video is now
  // this new exercise's own, so re-confirming the activation notice is
  // deliberate, not an oversight.
  late bool _embeddingAllowed =
      _willFork ? false : (_existing?.embeddingAllowed ?? false);
  late final bool _initialEmbeddingAllowed = _embeddingAllowed;

  late final _nameController = TextEditingController(
    text: _willFork ? '${_existing!.name} (edited)' : (_existing?.name ?? ''),
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
    if (_embeddingAllowed != _initialEmbeddingAllowed) return true;
    if (_imagePaths.length != _initialImagePaths.length ||
        !_imagePaths.every(
          (p) => _initialImagePaths.contains(p),
        )) {
      return true;
    }
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

  /// Turning embedding *off* needs no confirmation - only activating it does,
  /// per the feature's own "notice on creation/activation" requirement.
  /// Cancelling the notice leaves the checkbox unchecked rather than
  /// reverting silently, so there's no state where embedding ends up on
  /// without the notice having actually been accepted.
  Future<void> _onEmbeddingToggled(bool? value) async {
    if (value != true) {
      setState(() => _embeddingAllowed = false);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable embedded playback?'),
        content: const Text(embeddingActivationNote),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('I understand, enable it'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _embeddingAllowed = confirmed ?? false);
  }

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
                  : _willFork
                  ? 'Edit exercise (saves as a copy)'
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
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        if (_willFork) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'This is a built-in library exercise, so your changes save as '
              'a new custom exercise - "${_existing!.name}" itself is left '
              'untouched.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 16),
        ],
        _ImageGalleryField(
          fileNames: _imagePaths,
          onChanged: (names) => setState(() => _imagePaths = names),
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
            options: difficulties,
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
        const SizedBox(height: 8),
        // Quick picks for exercises that need no fixed external weight (ab
        // rollouts, band work, ...) - exact values the seed library and
        // lib/logic/equipment_matching.dart already recognize (a
        // "None (Bodyweight)"-style value always counts as doable
        // regardless of what equipment someone has), so typing them by hand
        // isn't the only way to get this right.
        Wrap(
          spacing: 8,
          children: [
            for (final suggestion in const [
              'None (Bodyweight)',
              'Resistance Band',
            ])
              ActionChip(
                label: Text(suggestion),
                onPressed: () => _equipmentController.text = suggestion,
              ),
          ],
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
        CheckboxListTile(
          value: _embeddingAllowed,
          onChanged: _onEmbeddingToggled,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Enable embedded playback (YouTube only)'),
          subtitle: const Text(
            'Personal use only - see the notice shown when you turn this on.',
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
                if (_embeddingAllowed) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Embedded playback enabled (personal use only)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
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
          for (final type in measurementTypes)
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
    // True in-place edits reuse the existing id so plans and logged sets
    // keep pointing at the same row; creating - and forking a built-in
    // exercise, which is really a creation under the hood - both mint a
    // fresh one.
    final id = (_isEditing && !_willFork) ? _existing!.id : const Uuid().v4();
    final name = _nameController.text.trim();

    // An image that was swapped out or removed leaves an orphan file behind
    // otherwise - nothing else references it, so clean it up now. Only for a
    // true in-place edit: a fork never started with the original's images
    // (see _imagePaths' own doc comment), so there's nothing of the
    // original's to ever delete here.
    if (_isEditing && !_willFork) {
      final removed = parseImagePaths(
        _existing!.imagePaths,
      ).where((p) => !_imagePaths.contains(p));
      for (final path in removed) {
        await deleteAttachment(path);
      }
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
        embeddingAllowed: Value(_embeddingAllowed),
        isCustom: const Value(true),
        author: Value(
          _authorController.text.trim().isEmpty
              ? null
              : _authorController.text.trim(),
        ),
        // Kept in sync alongside imagePaths purely as a defensive fallback
        // for any code that still reads the deprecated single field - see
        // its own doc comment on exercises_table.dart.
        imagePath: Value(_imagePaths.isEmpty ? null : _imagePaths.first),
        imagePaths: Value(joinImagePaths(_imagePaths)),
        // Preserve provenance on a true in-place edit - re-saving an
        // imported exercise shouldn't make it look like it was created from
        // scratch. A fork is a new exercise in its own right, so it starts
        // with no inherited provenance instead of misattributing itself to
        // whatever created the original.
        sourcePlanName: Value(_willFork ? null : _existing?.sourcePlanName),
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

/// Picks up to [maxExerciseImages] images for an exercise from the device,
/// shown as a horizontal strip of thumbnails plus an "add" tile.
///
/// User-supplied rather than bundled stock imagery, deliberately: shipping
/// scraped exercise photos would be a licensing problem for anyone publishing
/// the app, and a photo of your own bar setup or a coach's whiteboard cue is
/// more useful than a generic render anyway.
class _ImageGalleryField extends StatefulWidget {
  final List<String> fileNames;
  final ValueChanged<List<String>> onChanged;

  const _ImageGalleryField({required this.fileNames, required this.onChanged});

  @override
  State<_ImageGalleryField> createState() => _ImageGalleryFieldState();
}

class _ImageGalleryFieldState extends State<_ImageGalleryField> {
  bool _picking = false;

  Future<void> _addPhoto() async {
    final remaining = maxExerciseImages - widget.fileNames.length;
    if (remaining <= 0) return;

    setState(() => _picking = true);
    try {
      // pickFiles (plural) - reported live as only ever accepting one image
      // per tap despite the tile's own "Add photos"/"up to 5" wording;
      // file_picker's allowMultiple defaults to true here (the single-file
      // pickFile used for _replace below is the right call there, since
      // that's deliberately a one-for-one swap).
      final files = await FilePicker.pickFiles(type: FileType.image);
      if (files.isEmpty || !mounted) return;

      // Silently picking more than fit would just as silently drop the
      // extras with no explanation - a fit count from a single pick action
      // is common (e.g. selecting a whole camera-roll range), so this is
      // worth telling the user about rather than leaving them to notice a
      // photo missing later.
      final toAdd = files.take(remaining);
      if (files.length > remaining) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Only added $remaining of ${files.length} - up to '
              '$maxExerciseImages photos per exercise.',
            ),
          ),
        );
      }

      // Copied into the app's own attachments directory so the image
      // survives the source being moved or deleted, and so "delete all data"
      // can reliably wipe it.
      final names = <String>[];
      for (final file in toAdd) {
        final path = file.path;
        if (path == null) continue;
        names.add(await saveAttachment(path));
      }
      widget.onChanged([...widget.fileNames, ...names]);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _replace(int index) async {
    setState(() => _picking = true);
    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      final path = file?.path;
      if (path == null) return;
      final name = await saveAttachment(path);
      final updated = List.of(widget.fileNames);
      updated[index] = name;
      widget.onChanged(updated);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _remove(int index) {
    final updated = List.of(widget.fileNames)..removeAt(index);
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (widget.fileNames.isEmpty && !_picking) {
      return InkWell(
        onTap: _addPhoto,
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
              Text('Add photos', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                'Optional - up to $maxExerciseImages of your own',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < widget.fileNames.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 140,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AttachmentImage(
                        fileName: widget.fileNames[i],
                        height: 140,
                        width: 140,
                        semanticLabel: 'Photo ${i + 1} of ${widget.fileNames.length}',
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Row(
                        children: [
                          _OverlayButton(
                            icon: Icons.edit,
                            tooltip: 'Change this photo',
                            onPressed: () => _replace(i),
                          ),
                          const SizedBox(width: 6),
                          _OverlayButton(
                            icon: Icons.close,
                            tooltip: 'Remove this photo',
                            onPressed: () => _remove(i),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_picking)
            const SizedBox(
              width: 140,
              height: 140,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (widget.fileNames.length < maxExerciseImages)
            InkWell(
              onTap: _addPhoto,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.add_photo_alternate_outlined, color: scheme.primary),
              ),
            ),
        ],
      ),
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
