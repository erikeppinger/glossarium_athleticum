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
import '../plans/plan_providers.dart' show allExercisesForMatchingProvider;
import 'exercise_library_providers.dart';

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
  Future<List<_LibraryGroup>>? _groupsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final db = ref.read(appDatabaseProvider);
    _groupsFuture = _loadGroups(db);
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
    ref.invalidate(filteredExercisesProvider);
    ref.invalidate(exerciseCategoriesProvider);
    ref.invalidate(creatorFilterOptionsProvider);
    ref.invalidate(allExercisesForMatchingProvider);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage libraries')),
      body: FutureBuilder<List<_LibraryGroup>>(
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
                          '${group.isProtected ? ' • built-in, not editable' : ''}',
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
                            if (!group.isProtected) ...[
                              TextButton(
                                onPressed: () => _delete(group),
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.error,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
