import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../data/daos/exercise_dao.dart';
import '../../data/local_storage.dart';
import '../../export/library_export.dart';
import '../../logic/exercise_images.dart';
import '../../logic/random_workout_generator.dart' show matchesSource, seedLibraryFilter;
import '../plans/block_edit_screen.dart';
import '../settings/app_preferences.dart';
import '../shared/exercise_list_invalidation.dart';
import 'exercise_library_providers.dart';

/// Which half of this screen is showing - two otherwise-unrelated kinds of
/// named, manageable group (source-string library groupings vs. reusable
/// exercise blocks) share one screen/toolbar-icon rather than each getting
/// its own, per the user's explicit ask not to add another icon just for
/// blocks.
enum _ManagementView { libraries, blocks }

/// One "library" grouping - the same buckets the Exercise Library's own
/// creator filter row already surfaces (built-in, per imported plan, per
/// author, "not in library"), given a dedicated management screen: rename
/// the whole group, delete it, or export just it, rather than only being
/// able to filter by it. There's no separate `Libraries` table backing this
/// - a group is still just "every exercise whose `sourcePlanName`/`author`/
/// `isCustom` matches a given value" (see `matchesSource`), so renaming a
/// group means relabelling every exercise in it, and there's nothing to
/// create/delete except the exercises themselves.
class _LibraryGroup {
  final String? source;
  final String label;
  final List<Exercise> exercises;
  final bool isProtected;

  const _LibraryGroup({
    required this.source,
    required this.label,
    required this.exercises,
    this.isProtected = false,
  });

  /// Only a `plan:<name>`/`author:<name>` group has a name worth changing -
  /// "Not in library" is the *absence* of one, not a name to rewrite.
  bool get isRenamable =>
      source != null &&
      (source!.startsWith('plan:') || source!.startsWith('author:'));
}

class LibraryManagementScreen extends ConsumerStatefulWidget {
  const LibraryManagementScreen({super.key});

  @override
  ConsumerState<LibraryManagementScreen> createState() =>
      _LibraryManagementScreenState();
}

class _LibraryManagementScreenState
    extends ConsumerState<LibraryManagementScreen> {
  _ManagementView _view = _ManagementView.libraries;
  Future<List<_LibraryGroup>>? _groupsFuture;
  Future<List<Block>>? _blocksFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final db = ref.read(appDatabaseProvider);
    _groupsFuture = _loadGroups(db);
    _blocksFuture = db.blockDao.getAllBlocks();
  }

  Future<List<_LibraryGroup>> _loadGroups(AppDatabase db) async {
    final all = await db.exerciseDao.getAllExercises();
    final creatorOptions = await db.exerciseDao.getCreatorFilterOptions();

    List<Exercise> forSource(String? source) =>
        all.where((e) => matchesSource(e, source)).toList();

    final groups = <_LibraryGroup>[
      _LibraryGroup(
        source: seedLibraryFilter,
        label: 'Standard library',
        exercises: forSource(seedLibraryFilter),
        isProtected: true,
      ),
      for (final option in creatorOptions)
        _LibraryGroup(
          source: option,
          label: option.startsWith('plan:')
              ? 'Plan: ${option.substring(5)}'
              : 'By: ${option.substring(7)}',
          exercises: forSource(option),
        ),
      _LibraryGroup(
        source: ownExercisesFilter,
        label: 'Not in library',
        exercises: forSource(ownExercisesFilter),
      ),
    ];
    return groups.where((g) => g.exercises.isNotEmpty).toList();
  }

  void _refresh() {
    setState(_load);
    _invalidateLibraryProviders();
  }

  void _invalidateLibraryProviders() {
    invalidateExerciseListProviders(ref);
  }

  Future<void> _rename(_LibraryGroup group) async {
    final oldName = group.source!.contains(':')
        ? group.source!.substring(group.source!.indexOf(':') + 1)
        : group.label;
    final controller = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename "${group.label}"'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == oldName) return;

    final db = ref.read(appDatabaseProvider);
    if (group.source!.startsWith('plan:')) {
      await db.exerciseDao.renameSourcePlanName(
        oldName: oldName,
        newName: newName,
      );
    } else if (group.source!.startsWith('author:')) {
      await db.exerciseDao.renameAuthor(oldName: oldName, newName: newName);
    }
    if (!mounted) return;
    _refresh();
  }

  Future<void> _delete(_LibraryGroup group) async {
    final isStandardLibrary = group.source == seedLibraryFilter;
    final db = ref.read(appDatabaseProvider);
    var planReferences = 0;
    var loggedSets = 0;
    final planNames = <String>{};
    for (final exercise in group.exercises) {
      final usage = await db.exerciseDao.getExerciseUsage(exercise.id);
      planReferences += usage.planReferences;
      loggedSets += usage.loggedSets;
      planNames.addAll(usage.planNames);
    }
    if (!mounted) return;

    final lines = <String>[
      '${group.exercises.length} exercise${group.exercises.length == 1 ? '' : 's'} '
          'in "${group.label}" will be deleted.',
      if (isStandardLibrary)
        'This is the app\'s built-in example library, normally restored '
            'automatically every time the app starts - deleting it turns '
            'that off, so it stays gone. You can bring the same exercises '
            'back anytime as an ordinary import: Settings > Backup & data > '
            '"Plan / library templates" > Exercise library.',
      if (planReferences > 0)
        'Together they appear $planReferences time${planReferences == 1 ? '' : 's'} '
            'in: ${planNames.join(', ')}. They will be removed from '
            '${planNames.length == 1 ? 'it' : 'them'}.',
      if (loggedSets > 0)
        'You have logged $loggedSets set${loggedSets == 1 ? '' : 's'} across '
            'these exercises. That history is kept.',
    ];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${group.label}"?'),
        content: Text(lines.join('\n\n')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    for (final exercise in group.exercises) {
      for (final path in parseImagePaths(exercise.imagePaths)) {
        await deleteAttachment(path);
      }
    }
    await db.exerciseDao.deleteExercisesKeepingHistory(
      group.exercises.map((e) => e.id).toList(),
    );
    if (isStandardLibrary) {
      await ref
          .read(appPreferencesProvider.notifier)
          .setStandardLibraryDismissed(true);
    }
    // A deleted group can remove the last exercise(s) with a given
    // category/area, leaving that value selected in the filter chips with
    // no way to see it's still applied - its own chip disappears from the
    // row along with the category, but the filter itself isn't cleared
    // automatically. Reset both rather than risk a stuck, invisible
    // empty-results filter.
    ref.read(exerciseCategoryFilterProvider.notifier).state = {};
    ref.read(exerciseAreaFilterProvider.notifier).state = {};
    if (!mounted) return;
    _refresh();
  }

  Future<void> _export(_LibraryGroup group) async {
    final db = ref.read(appDatabaseProvider);
    final json = await buildLibraryJson(db, exercisesOverride: group.exercises);
    if (!mounted) return;
    final contents = jsonEncode(json);
    final fileName =
        '${group.label.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}.json';

    final choice = await showDialog<bool>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Export "${group.label}"'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Share'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Save to file'),
          ),
        ],
      ),
    );
    if (choice == null || !mounted) return;

    if (choice) {
      final tempDir = await getTemporaryDirectory();
      final file = File(p.join(tempDir.path, fileName));
      await file.writeAsString(contents);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: group.label),
      );
    } else {
      await FilePicker.saveFile(
        fileName: fileName,
        bytes: Uint8List.fromList(utf8.encode(contents)),
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
    }
  }

  /// Creates an empty block shell, then opens it directly in
  /// `BlockEditScreen` to add its first exercises - the only way to author
  /// a block from scratch. (The other way, "Save as block" from an already-
  /// built session's selected exercises, lives in `edit_session_screen.dart`
  /// since it needs real exercises to select in the first place.)
  Future<void> _createBlock() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _BlockNameDialog(
        title: 'New block',
        confirmLabel: 'Create',
      ),
    );
    if (name == null || name.isEmpty || !mounted) return;

    final db = ref.read(appDatabaseProvider);
    final blockId = await db.blockDao.createBlock(name: name, exercises: const []);
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => BlockEditScreen(blockId: blockId)),
    );
    if (!mounted) return;
    _refresh();
  }

  Future<void> _renameBlock(Block block) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _BlockNameDialog(
        title: 'Rename block',
        confirmLabel: 'Rename',
        initialValue: block.name,
      ),
    );
    if (name == null || name.isEmpty || name == block.name || !mounted) return;

    final db = ref.read(appDatabaseProvider);
    await db.blockDao.renameBlock(block.id, name);
    if (!mounted) return;
    _refresh();
  }

  Future<void> _deleteBlock(Block block) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${block.name}"?'),
        content: const Text(
          'Any session that already used this block keeps its own copy of '
          'its exercises exactly as they were - deleting the block only '
          'removes it as a future shortcut.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final db = ref.read(appDatabaseProvider);
    await db.blockDao.deleteBlock(block.id);
    if (!mounted) return;
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage libraries & blocks'),
        actions: [
          if (_view == _ManagementView.blocks)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'New block',
              onPressed: _createBlock,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SegmentedButton<_ManagementView>(
              segments: const [
                ButtonSegment(
                  value: _ManagementView.libraries,
                  label: Text('Libraries'),
                ),
                ButtonSegment(
                  value: _ManagementView.blocks,
                  label: Text('Blocks'),
                ),
              ],
              selected: {_view},
              onSelectionChanged: (selection) =>
                  setState(() => _view = selection.first),
            ),
          ),
          Expanded(
            child: _view == _ManagementView.libraries
                ? _buildLibrariesList()
                : _buildBlocksList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBlocksList() {
    return FutureBuilder<List<Block>>(
      future: _blocksFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final blocks = snapshot.data!;
        if (blocks.isEmpty) {
          return const Center(
            child: Text(
              'No blocks yet.\nCreate one here, or select exercises in a '
              'session and "Save as block".',
              textAlign: TextAlign.center,
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            for (final block in blocks)
              Card(
                child: ListTile(
                  title: Text(block.name),
                  onTap: () => Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (context) =>
                              BlockEditScreen(blockId: block.id),
                        ),
                      )
                      .then((_) => _refresh()),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Rename',
                        onPressed: () => _renameBlock(block),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        tooltip: 'Delete',
                        onPressed: () => _deleteBlock(block),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLibrariesList() {
    return FutureBuilder<List<_LibraryGroup>>(
      future: _groupsFuture,
      builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final groups = snapshot.data!;
          if (groups.isEmpty) {
            return const Center(child: Text('No exercises yet.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final group in groups)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${group.exercises.length} exercise'
                          '${group.exercises.length == 1 ? '' : 's'}'
                          '${group.isProtected ? ' • built-in' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        OverflowBar(
                          alignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _export(group),
                              child: const Text('Export'),
                            ),
                            if (group.isRenamable)
                              TextButton(
                                onPressed: () => _rename(group),
                                child: const Text('Rename'),
                              ),
                            TextButton(
                              onPressed: () => _delete(group),
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.error,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      );
  }
}

/// Owns its own controller (disposed in its own `State.dispose()`, once the
/// route is actually removed) rather than one created inline by the caller
/// and disposed right after `showDialog`'s Future resolves - that races the
/// dialog's own exit transition, which keeps rebuilding the same `TextField`
/// for a few frames while it animates out. Same bug/fix
/// `plate_calculator_screen.dart`'s `_AddPlateDialog` already documents.
class _BlockNameDialog extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final String initialValue;

  const _BlockNameDialog({
    required this.title,
    required this.confirmLabel,
    this.initialValue = '',
  });

  @override
  State<_BlockNameDialog> createState() => _BlockNameDialogState();
}

class _BlockNameDialogState extends State<_BlockNameDialog> {
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
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Block name',
          hintText: 'e.g. Warm-up',
          border: OutlineInputBorder(),
        ),
      ),
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
