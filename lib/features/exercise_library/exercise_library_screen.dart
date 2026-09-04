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
import '../../export/library_export.dart';
import '../../home_screen.dart' show settingsAppBarAction;
import '../../import/library_import.dart';
import '../../logic/muscle_group_colors.dart';
import '../../security/backup_encryption.dart';
import '../history/history_screen.dart';
import '../settings/app_preferences.dart';
import '../settings/backup_dialogs.dart';
import '../shared/muscle_area_stripe.dart';
import '../plans/add_exercise_to_plan_screen.dart';
import '../plans/plan_providers.dart';
import 'create_exercise_screen.dart';
import 'exercise_detail_screen.dart';
import 'exercise_library_providers.dart';

class ExerciseLibraryScreen extends ConsumerWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(filteredExercisesProvider);
    final categoriesAsync = ref.watch(exerciseCategoriesProvider);
    final selectedCategory = ref.watch(exerciseCategoryFilterProvider);
    final creatorOptionsAsync = ref.watch(creatorFilterOptionsProvider);
    final selectedCreator = ref.watch(exerciseCreatorFilterProvider);
    final selectedArea = ref.watch(exerciseAreaFilterProvider);
    final availableEquipment = ref.watch(
      appPreferencesProvider.select((p) => p.availableEquipment),
    );
    final equipmentFilterEnabled = ref.watch(
      exerciseEquipmentFilterEnabledProvider,
    );
    final palette = ref.watch(appPreferencesProvider).colorPalette;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create exercise',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CreateExerciseScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Import library',
            onPressed: () => _importLibrary(context, ref),
          ),
          PopupMenuButton<_LibraryExportAction>(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Export library',
            onSelected: (action) => _handleExportAction(context, ref, action),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _LibraryExportAction.shareJson,
                child: Text('Share library (.json)'),
              ),
              PopupMenuItem(
                value: _LibraryExportAction.shareEncrypted,
                child: Text('Share encrypted library (.tlibrary)'),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: _LibraryExportAction.saveJson,
                child: Text('Save library (.json)'),
              ),
              PopupMenuItem(
                value: _LibraryExportAction.saveEncrypted,
                child: Text('Save encrypted library (.tlibrary)'),
              ),
            ],
          ),
          settingsAppBarAction(context),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              key: const Key('exerciseSearchField'),
              decoration: const InputDecoration(
                labelText: 'Search exercises',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  ref.read(exerciseSearchQueryProvider.notifier).state = value,
            ),
          ),
          categoriesAsync.when(
            data: (categories) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CategoryChip(
                      label: 'All',
                      selected: selectedCategory == null,
                      onSelected: () => ref
                          .read(exerciseCategoryFilterProvider.notifier)
                          .state = null,
                    ),
                    for (final category in categories)
                      _CategoryChip(
                        label: category,
                        selected: selectedCategory == category,
                        onSelected: () => ref
                            .read(exerciseCategoryFilterProvider.notifier)
                            .state = category,
                      ),
                  ],
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CategoryChip(
                      label: 'All areas',
                      selected: selectedArea == null,
                      onSelected: () =>
                          ref.read(exerciseAreaFilterProvider.notifier).state =
                              null,
                    ),
                    for (final area in MuscleArea.values)
                      _CategoryChip(
                        label: area.label,
                        selected: selectedArea == area,
                        swatch: colorForArea(area, palette),
                        onSelected: () =>
                            ref
                                    .read(exerciseAreaFilterProvider.notifier)
                                    .state =
                                area,
                      ),
                  ],
                ),
              ),
            ),
          ),
          creatorOptionsAsync.when(
            data: (options) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _CategoryChip(
                        label: 'All creators',
                        selected: selectedCreator == null,
                        onSelected: () => ref
                            .read(exerciseCreatorFilterProvider.notifier)
                            .state = null,
                      ),
                      _CategoryChip(
                        label: 'Own',
                        selected: selectedCreator == ownExercisesFilter,
                        swatch: colorForProvenance(ExerciseProvenance.own),
                        onSelected: () => ref
                            .read(exerciseCreatorFilterProvider.notifier)
                            .state = ownExercisesFilter,
                      ),
                      for (final option in options)
                        _CategoryChip(
                          label: option.startsWith('plan:')
                              ? 'Plan: ${option.substring(5)}'
                              : 'By: ${option.substring(7)}',
                          selected: selectedCreator == option,
                          // Per-value, not colorForProvenance's fixed
                          // per-category colour - every "Plan: ..." chip
                          // would otherwise share the same green regardless
                          // of which plan it is, defeating the point of
                          // colour-coding a row meant to distinguish them.
                          swatch: colorForCreatorValue(option),
                          onSelected: () => ref
                              .read(exerciseCreatorFilterProvider.notifier)
                              .state = option,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          // Hidden entirely until equipment has actually been configured
          // (Settings or onboarding) - same "opt-in feature invisible until
          // there's data for it" shape as the body-tracking card, since an
          // empty owned-equipment set isn't itself a meaningful filter.
          if (availableEquipment.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FilterChip(
                  label: const Text('My equipment'),
                  selected: equipmentFilterEnabled,
                  onSelected: (selected) => ref
                      .read(exerciseEquipmentFilterEnabledProvider.notifier)
                      .state = selected,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                if (exercises.isEmpty) {
                  return const Center(child: Text('No exercises match.'));
                }
                return ListView.builder(
                  itemCount: exercises.length,
                  itemBuilder: (context, index) => _ExerciseTile(
                    exercise: exercises[index],
                    palette: palette,
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  void _invalidateLibraryProviders(WidgetRef ref) {
    // One-shot FutureProviders - won't notice a direct DB write on their own.
    ref.invalidate(filteredExercisesProvider);
    ref.invalidate(exerciseCategoriesProvider);
    ref.invalidate(creatorFilterOptionsProvider);
    ref.invalidate(allExercisesForMatchingProvider);
  }

  Future<void> _importLibrary(BuildContext context, WidgetRef ref) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json', encryptedLibraryFileExtension],
    );
    if (file == null || !context.mounted) return;

    final isEncrypted = file.name.endsWith('.$encryptedLibraryFileExtension');
    final content = utf8.decode(await file.readAsBytes());
    if (!context.mounted) return;

    Map<String, dynamic> json;
    try {
      if (isEncrypted) {
        final passphrase = await promptPassphrase(
          context,
          title: 'Enter the library file\'s passphrase',
        );
        if (passphrase == null || passphrase.isEmpty) return;
        final decrypted = await decryptBackup(content, passphrase);
        json = jsonDecode(decrypted) as Map<String, dynamic>;
      } else {
        json = jsonDecode(content) as Map<String, dynamic>;
      }
    } on BackupDecryptionException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    } on FormatException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not a valid library file.')),
      );
      return;
    }
    if (!context.mounted) return;

    final db = ref.read(appDatabaseProvider);
    try {
      final count = await importLibraryJson(json, db);
      _invalidateLibraryProviders(ref);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $count exercise${count == 1 ? '' : 's'}.')),
      );
    } on LibraryJsonFormatException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _handleExportAction(
    BuildContext context,
    WidgetRef ref,
    _LibraryExportAction action,
  ) async {
    final db = ref.read(appDatabaseProvider);
    final json = await buildLibraryJson(db);
    if (!context.mounted) return;
    final plainJson = jsonEncode(json);

    final String contents;
    final String fileName;
    final String extension;
    if (action == _LibraryExportAction.shareEncrypted ||
        action == _LibraryExportAction.saveEncrypted) {
      final passphrase = await promptPassphrase(
        context,
        title: 'Choose a passphrase',
        helperText:
            "You'll need this exact passphrase to import this library "
            'elsewhere.',
      );
      if (passphrase == null || passphrase.isEmpty) return;
      contents = await encryptBackup(plainJson, passphrase);
      fileName = 'exercise_library.$encryptedLibraryFileExtension';
      extension = encryptedLibraryFileExtension;
    } else {
      contents = plainJson;
      fileName = 'exercise_library.json';
      extension = 'json';
    }
    if (!context.mounted) return;

    if (action == _LibraryExportAction.saveJson ||
        action == _LibraryExportAction.saveEncrypted) {
      final uri = await FilePicker.saveFile(
        fileName: fileName,
        bytes: Uint8List.fromList(utf8.encode(contents)),
        type: FileType.custom,
        allowedExtensions: [extension],
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(uri == null ? 'Export cancelled.' : 'Saved.')),
      );
    } else {
      final tempDir = await getTemporaryDirectory();
      final file = File(p.join(tempDir.path, fileName));
      await file.writeAsString(contents);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Exercise library'),
      );
    }
  }
}

enum _LibraryExportAction { shareJson, shareEncrypted, saveJson, saveEncrypted }

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  // Mirrors the library list's own colour coding onto the filter that picks
  // it out - null for the category row, which doesn't map onto a single
  // muscle area or provenance and so has nothing meaningful to swatch.
  final Color? swatch;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.swatch,
  });

  @override
  Widget build(BuildContext context) {
    if (swatch == null) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onSelected(),
        ),
      );
    }

    // Filled with the area/provenance's own colour rather than a small
    // leading dot - reads at a glance without a separate swatch+label pair
    // taking up width, so the chip itself can be narrower. Selected vs.
    // unselected is shown as full-strength vs. faded fill (with a matching
    // border either way) rather than a checkmark, which would eat back the
    // width just saved by dropping the dot.
    final fg = ThemeData.estimateBrightnessForColor(swatch!) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        showCheckmark: false,
        backgroundColor: swatch!.withValues(alpha: 0.35),
        selectedColor: swatch,
        side: BorderSide(color: swatch!, width: selected ? 1.5 : 1),
        labelStyle: TextStyle(
          color: selected ? fg : null,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  final AppColorPalette palette;

  const _ExerciseTile({required this.exercise, required this.palette});

  @override
  Widget build(BuildContext context) {
    final area = areaForExercise(
      muscleGroups: exercise.muscleGroups,
      category: exercise.category,
      movementPattern: exercise.movementPattern,
    );

    final provenance = provenanceForExercise(exercise);

    return ListTile(
      // Two independent colour stripes rather than a filled row: one for
      // what the exercise trains, one for who made it - they read at a
      // glance when scanning, without tinting the text behind them or
      // forcing one bar to encode two different kinds of information.
      leading: SizedBox(
        width: 16,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MuscleAreaStripe(area: area, palette: palette),
            const SizedBox(width: 4),
            ProvenanceStripe(provenance: provenance),
          ],
        ),
      ),
      title: Text(exercise.name),
      subtitle: Text(
        // Equipment/difficulty are optional on a custom exercise - filter
        // out blanks rather than rendering "Legs •  • Beginner" with a
        // visible empty gap for one left unfilled.
        [
          area.label,
          exercise.equipment,
          exercise.difficulty,
        ].where((part) => part.isNotEmpty).join(' • '),
      ),
      trailing: Text(exercise.measurementType),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ExerciseDetailScreen(exercise: exercise),
        ),
      ),
      onLongPress: () => _showQuickActions(context),
    );
  }

  Future<void> _showQuickActions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('View details'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ExerciseDetailScreen(exercise: exercise),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.show_chart),
              title: const Text('View history'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => HistoryScreen(
                      exerciseId: exercise.id,
                      exerciseName: exercise.name,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add to plan'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddExerciseToPlanScreen(
                      exerciseId: exercise.id,
                      exerciseName: exercise.name,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
