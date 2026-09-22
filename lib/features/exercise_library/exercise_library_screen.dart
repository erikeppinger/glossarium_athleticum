import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
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
import '../../import/plan_zip_bundle.dart';
import '../../logic/equipment_matching.dart' show bodyweightEquipmentTag;
import '../../logic/muscle_group_colors.dart';
import '../../security/backup_encryption.dart';
import '../history/history_screen.dart';
import '../settings/app_preferences.dart';
import '../settings/backup_dialogs.dart';
import '../shared/exercise_export_flow.dart';
import '../shared/muscle_area_stripe.dart';
import '../tools/plate_calculator_screen.dart';
import '../plans/add_exercise_to_plan_screen.dart';
import '../plans/plan_providers.dart';
import '../plans/random_workout_screen.dart';
import 'create_exercise_screen.dart';
import 'exercise_detail_screen.dart';
import 'exercise_library_import_screen.dart';
import 'exercise_library_providers.dart';
import 'library_management_screen.dart';

/// Flips [value]'s membership in [provider]'s set - in on an unselected
/// chip, out on an already-selected one (a second tap on "Back" deselects
/// it, rather than needing a separate tap on "All" to get back to no
/// filter). Always builds a *new* Set rather than mutating in place, so
/// Riverpod's StateProvider actually notices the change.
void _toggle<T>(WidgetRef ref, StateProvider<Set<T>> provider, T value) {
  final current = ref.read(provider);
  final next = Set<T>.of(current);
  if (!next.remove(value)) next.add(value);
  ref.read(provider.notifier).state = next;
}

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  // Up to four filter rows (category, muscle area, creator, equipment) ate a
  // lot of vertical space above the list, and stayed pinned there while
  // scrolling - collapsing them once the user actually starts scrolling (and
  // bringing them back once they scroll back up to the top) trades that
  // space back to the list without removing the filters outright.
  bool _filtersExpanded = true;

  // Reported live: exporting was all-or-nothing (the whole library, or a
  // whole named group in library_management_screen.dart) - no way to hand a
  // buddy just the one or two exercises they actually want without also
  // sending everything else. Entered via a menu item on the existing export
  // button rather than a new toolbar icon (already a crowded five-icon row -
  // see its own comment) or hijacking long-press (already opens each tile's
  // own quick-actions sheet).
  bool _selectingForExport = false;
  final Set<String> _selectedExerciseIds = {};

  void _cancelSelection() => setState(() {
    _selectingForExport = false;
    _selectedExerciseIds.clear();
  });

  bool _handleScrollNotification(UserScrollNotification notification) {
    if (notification.metrics.pixels <= 0) {
      if (!_filtersExpanded) setState(() => _filtersExpanded = true);
    } else if (notification.direction == ScrollDirection.reverse &&
        _filtersExpanded) {
      setState(() => _filtersExpanded = false);
    } else if (notification.direction == ScrollDirection.forward &&
        !_filtersExpanded) {
      setState(() => _filtersExpanded = true);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(filteredExercisesProvider);
    final categoriesAsync = ref.watch(exerciseCategoriesProvider);
    final selectedCategories = ref.watch(exerciseCategoryFilterProvider);
    final creatorOptionsAsync = ref.watch(creatorFilterOptionsProvider);
    final selectedCreator = ref.watch(exerciseCreatorFilterProvider);
    final selectedAreas = ref.watch(exerciseAreaFilterProvider);
    final availableEquipment = ref.watch(
      appPreferencesProvider.select((p) => p.availableEquipment),
    );
    final libraryEquipmentTags = ref.watch(libraryEquipmentTagsProvider);
    final equipmentFilterEnabled = ref.watch(
      exerciseEquipmentFilterEnabledProvider,
    );
    final favoritesOnly = ref.watch(exerciseFavoritesOnlyFilterProvider);
    final palette = ref.watch(appPreferencesProvider).colorPalette;

    return Scaffold(
      appBar: _selectingForExport
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cancel selection',
                onPressed: _cancelSelection,
              ),
              title: Text(
                _selectedExerciseIds.isEmpty
                    ? 'Select exercises to export'
                    : '${_selectedExerciseIds.length} selected',
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.file_upload_outlined),
                  tooltip: 'Export selected',
                  onPressed: _selectedExerciseIds.isEmpty
                      ? null
                      : () => _showSelectedExportMenu(context, ref),
                ),
              ],
            )
          : AppBar(
              title: const Text('Exercise Library'),
              actions: [settingsAppBarAction(context)],
              // Previously all five of these (the four below, plus Settings) sat
              // in `actions`, crowding the title down to "Exercise Libr..." and
              // packing the icons tightly enough that the row looked broken -
              // reported live (2026-09-09). Settings alone stays in `actions`
              // (matching every other tab's app bar); the library-management
              // actions move to their own row directly underneath instead of
              // fighting the title for space.
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
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
                      onPressed: () => _showImportOptions(context, ref),
                    ),
                    PopupMenuButton<_LibraryExportAction>(
                      icon: const Icon(Icons.file_upload_outlined),
                      tooltip: 'Export library',
                      onSelected: (action) {
                        if (action == _LibraryExportAction.selectExercises) {
                          setState(() => _selectingForExport = true);
                          return;
                        }
                        _handleExportAction(context, ref, action);
                      },
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
                        PopupMenuDivider(),
                        // Reported live: exporting was all-or-nothing (this whole
                        // library, or a whole named group in "Manage libraries") -
                        // this is the "just these one or two exercises" path.
                        PopupMenuItem(
                          value: _LibraryExportAction.selectExercises,
                          child: Text('Select exercises to export...'),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.auto_stories_outlined),
                      tooltip: 'Manage libraries & blocks',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LibraryManagementScreen(),
                        ),
                      ),
                    ),
                    // Previously buried in the Plans tab's "New plan" bottom
                    // sheet, grouped with ways to author a *plan* - reported live
                    // (2026-09-10) as a confusing, easy-to-miss home for it: a
                    // random workout is built from the exercise library, not
                    // authored as a plan (even though it happens to save as one
                    // under the hood via PlanDao.createPlan - see
                    // random_workout_screen.dart). Belongs here instead.
                    IconButton(
                      icon: const Icon(Icons.shuffle),
                      tooltip: 'Random workout',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RandomWorkoutScreen(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calculate),
                      tooltip: 'Plate calculator',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PlateCalculatorScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      // A plain Column here (search + filters + Expanded(ListView)) would
      // overflow at a small enough window height - the search field and
      // three filter rows are fixed-size siblings ahead of the Expanded
      // list, and Expanded can't reclaim space its non-flexible siblings
      // have already claimed. Confirmed live (2026-09-15) on a narrow
      // Linux desktop window: a genuine "BOTTOM OVERFLOWED BY 58 PIXELS"
      // error, not just a cosmetic clipping issue. CustomScrollView with
      // SliverFillRemaining(hasScrollBody: true) for the list behaves
      // identically to Expanded(ListView) whenever there's enough room
      // (the common case), but degrades to "scroll to see the rest"
      // instead of erroring when there isn't.
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                key: const Key('exerciseSearchField'),
                decoration: InputDecoration(
                  labelText: 'Search exercises',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  // Previously its own "Favorites only" chip in the filter
                  // row below - reported live as sitting oddly on its own
                  // whenever "My equipment" wasn't also showing (the common
                  // case, since equipment is opt-in). A star here saves that
                  // whole row instead.
                  suffixIcon: IconButton(
                    icon: Icon(favoritesOnly ? Icons.star : Icons.star_border),
                    color: favoritesOnly
                        ? Colors.amber.shade700
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    tooltip: favoritesOnly
                        ? 'Show all exercises'
                        : 'Show favorites only',
                    onPressed: () =>
                        ref
                                .read(
                                  exerciseFavoritesOnlyFilterProvider.notifier,
                                )
                                .state =
                            !favoritesOnly,
                  ),
                ),
                onChanged: (value) =>
                    ref.read(exerciseSearchQueryProvider.notifier).state =
                        value,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: !_filtersExpanded
                  ? const SizedBox(width: double.infinity)
                  : Column(
                      // The category/area/creator rows above are horizontally
                      // scrolling ListViews, which fill the available width
                      // regardless of alignment - but the "My equipment"/
                      // "Favorites only" row below is a plain Wrap, which
                      // shrink-wraps to its content. With no explicit
                      // alignment here, Column's own default (center) left
                      // that Wrap floating in the horizontal middle of the
                      // screen instead of lining up with everything else,
                      // most noticeably when only one of the two chips shows
                      // (e.g. equipment not configured, so just "Favorites
                      // only" appears alone) - reported live (2026-09-10).
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                    selected: selectedCategories.isEmpty,
                                    onSelected: () =>
                                        ref
                                                .read(
                                                  exerciseCategoryFilterProvider
                                                      .notifier,
                                                )
                                                .state =
                                            {},
                                  ),
                                  for (final category in categories)
                                    _CategoryChip(
                                      label: category,
                                      selected: selectedCategories.contains(
                                        category,
                                      ),
                                      swatch: colorForCategoryValue(
                                        category,
                                        palette,
                                      ),
                                      onSelected: () => _toggle(
                                        ref,
                                        exerciseCategoryFilterProvider,
                                        category,
                                      ),
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
                                    selected: selectedAreas.isEmpty,
                                    onSelected: () =>
                                        ref
                                                .read(
                                                  exerciseAreaFilterProvider
                                                      .notifier,
                                                )
                                                .state =
                                            {},
                                  ),
                                  for (final area in MuscleArea.values)
                                    _CategoryChip(
                                      label: area.label,
                                      selected: selectedAreas.contains(area),
                                      swatch: colorForArea(area, palette),
                                      onSelected: () => _toggle(
                                        ref,
                                        exerciseAreaFilterProvider,
                                        area,
                                      ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: SizedBox(
                                height: 40,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    _CategoryChip(
                                      label: 'All creators',
                                      selected: selectedCreator == null,
                                      compact: true,
                                      onSelected: () =>
                                          ref
                                                  .read(
                                                    exerciseCreatorFilterProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              null,
                                    ),
                                    _CategoryChip(
                                      // Not "Own" - this bucket is "isCustom
                                      // with no author/plan attached", which
                                      // includes bulk spreadsheet imports as
                                      // often as anything hand-typed in the
                                      // app.
                                      label: 'Not in library',
                                      selected:
                                          selectedCreator == ownExercisesFilter,
                                      compact: true,
                                      onSelected: () =>
                                          ref
                                                  .read(
                                                    exerciseCreatorFilterProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              ownExercisesFilter,
                                    ),
                                    for (final option in options)
                                      _CategoryChip(
                                        label: option.startsWith('plan:')
                                            ? 'Plan: ${option.substring(5)}'
                                            : 'By: ${option.substring(7)}',
                                        selected: selectedCreator == option,
                                        compact: true,
                                        onSelected: () =>
                                            ref
                                                    .read(
                                                      exerciseCreatorFilterProvider
                                                          .notifier,
                                                    )
                                                    .state =
                                                option,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                        // Hidden until equipment has actually been configured
                        // (Settings or onboarding) *and* the library still has
                        // exercises tagged with real equipment info right now -
                        // same "opt-in feature invisible until there's data for
                        // it" shape as the body-tracking card. The second half
                        // guards against a stale "my equipment" preference
                        // lingering as a dead filter after the library's own
                        // equipment data changes (e.g. every tagged exercise
                        // gets deleted) - without it the chip would still show
                        // but could never actually filter anything. Favorites
                        // used to live here too as its own "Favorites only"
                        // chip, but with equipment usually unconfigured it was
                        // the only chip in this row and ended up looking
                        // stray - moved to a star toggle on the search field
                        // instead (see below), which also saves a whole row
                        // for the common case where equipment isn't set up at
                        // all, since this row now hides completely in that
                        // case rather than sitting empty. The `any(tag !=
                        // bodyweightEquipmentTag)` check (rather than a plain
                        // isNotEmpty) is deliberate: libraryEquipmentTagsProvider
                        // always includes that one synthetic tag regardless of
                        // real library data, so a plain isNotEmpty check would
                        // never be false and this whole guard would stop doing
                        // anything.
                        if (availableEquipment.isNotEmpty &&
                            (libraryEquipmentTags.valueOrNull?.any(
                                  (tag) => tag != bodyweightEquipmentTag,
                                ) ??
                                false))
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                            child: Wrap(
                              spacing: 8,
                              children: [
                                FilterChip(
                                  label: const Text('My equipment'),
                                  labelStyle: Theme.of(context)
                                      .textTheme
                                      .labelSmall,
                                  selected: equipmentFilterEnabled,
                                  onSelected: (selected) =>
                                      ref
                                              .read(
                                                exerciseEquipmentFilterEnabledProvider
                                                    .notifier,
                                              )
                                              .state =
                                          selected,
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                      ],
                    ),
            ),
          ),
          exercisesAsync.when(
            data: (exercises) {
              if (exercises.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('No exercises match.')),
                );
              }
              // NotificationListener (not a ScrollController) so this
              // only ever reacts to the exercise list's own scrolling,
              // never a horizontal filter-chip row's.
              return SliverFillRemaining(
                hasScrollBody: true,
                child: NotificationListener<UserScrollNotification>(
                  onNotification: _handleScrollNotification,
                  child: ListView.builder(
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final tileExercise = exercises[index];
                      return _ExerciseTile(
                        exercise: tileExercise,
                        palette: palette,
                        selecting: _selectingForExport,
                        selected: _selectedExerciseIds.contains(
                          tileExercise.id,
                        ),
                        onSelectedChanged: (value) => setState(() {
                          if (value) {
                            _selectedExerciseIds.add(tileExercise.id);
                          } else {
                            _selectedExerciseIds.remove(tileExercise.id);
                          }
                        }),
                      );
                    },
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $error')),
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

  Future<void> _showImportOptions(BuildContext context, WidgetRef ref) async {
    final choice = await showModalBottomSheet<_LibraryImportSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('From spreadsheet (.csv or .xlsx)'),
              subtitle: const Text(
                'Excel/Sheets export, or the library template',
              ),
              onTap: () =>
                  Navigator.of(context).pop(_LibraryImportSource.spreadsheet),
            ),
            ListTile(
              leading: const Icon(Icons.perm_media_outlined),
              title: const Text('From spreadsheet + pictures (.zip)'),
              subtitle: const Text(
                "A .csv/.xlsx with a \"Picture\" column, zipped up with the "
                'image files it names',
              ),
              onTap: () => Navigator.of(
                context,
              ).pop(_LibraryImportSource.spreadsheetWithPictures),
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('From library file (.json)'),
              subtitle: const Text("Exported from this app's Exercise Library"),
              onTap: () => Navigator.of(context).pop(_LibraryImportSource.json),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('From encrypted library file (.tlibrary)'),
              subtitle: const Text('A library shared with its own passphrase'),
              onTap: () =>
                  Navigator.of(context).pop(_LibraryImportSource.encryptedJson),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || choice == null) return;
    switch (choice) {
      case _LibraryImportSource.spreadsheet:
        await _importFromSpreadsheet(context);
      case _LibraryImportSource.spreadsheetWithPictures:
        await _importFromZipBundle(context);
      case _LibraryImportSource.json:
      case _LibraryImportSource.encryptedJson:
        await _importLibrary(context, ref);
    }
  }

  Future<void> _importFromSpreadsheet(BuildContext context) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
    );
    if (file == null || !context.mounted) return;

    final bytes = await file.readAsBytes();
    final isXlsx = file.name.toLowerCase().endsWith('.xlsx');

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => isXlsx
            ? ExerciseLibraryImportScreen(xlsxBytes: bytes)
            : ExerciseLibraryImportScreen(csvContent: utf8.decode(bytes)),
      ),
    );
  }

  /// Mirrors `plan_list_screen.dart`'s own "From spreadsheet + pictures
  /// (.zip)" import exactly, down to reusing `readPlanZipBundle` as-is - it
  /// was already generic (a spreadsheet plus an images-by-filename map),
  /// never plan-specific, so there's nothing to duplicate here.
  Future<void> _importFromZipBundle(BuildContext context) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (file == null) return;

    final PlanZipBundle bundle;
    try {
      bundle = readPlanZipBundle(await file.readAsBytes());
    } on PlanZipBundleException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => bundle.xlsxBytes != null
            ? ExerciseLibraryImportScreen(
                xlsxBytes: bundle.xlsxBytes,
                imagesByFileName: bundle.imagesByFileName,
              )
            : ExerciseLibraryImportScreen(
                csvContent: bundle.csvContent,
                imagesByFileName: bundle.imagesByFileName,
              ),
      ),
    );
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
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
        SnackBar(
          content: Text('Imported $count exercise${count == 1 ? '' : 's'}.'),
        ),
      );
    } on LibraryJsonFormatException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Hands whatever the user has checked so far in selection mode to the
  /// same export sheet the exercise detail screen's own share action uses
  /// (see exercise_export_flow.dart) - unlike the whole-library export
  /// below, a selected exercise is included exactly as picked regardless
  /// of `isCustom`: a built-in exercise the *recipient's* install might be
  /// missing (an older seed database) is still worth sending, and there's
  /// no technical reason to special-case it out the way the default
  /// "export everything" already deliberately does.
  Future<void> _showSelectedExportMenu(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final allExercises =
        ref.read(filteredExercisesProvider).valueOrNull ?? const <Exercise>[];
    final selected = allExercises
        .where((e) => _selectedExerciseIds.contains(e.id))
        .toList();
    if (selected.isEmpty) return;

    final actionTaken = await showExerciseExportSheet(context, ref, selected);
    if (!mounted || !actionTaken) return;
    _cancelSelection();
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

    const fileNameBase = 'exercise_library';
    const shareText = 'Exercise library';

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
      fileName = '$fileNameBase.$encryptedLibraryFileExtension';
      extension = encryptedLibraryFileExtension;
    } else {
      contents = plainJson;
      fileName = '$fileNameBase.json';
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
        ShareParams(files: [XFile(file.path)], text: shareText),
      );
    }
  }
}

enum _LibraryExportAction {
  shareJson,
  shareEncrypted,
  saveJson,
  saveEncrypted,
  selectExercises,
}

enum _LibraryImportSource {
  spreadsheet,
  spreadsheetWithPictures,
  json,
  encryptedJson,
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  // Mirrors the library list's own colour coding onto the filter that picks
  // it out - null for a row with nothing meaningful to swatch.
  final Color? swatch;
  // The creator and equipment rows are complementary information (who made
  // it, what you can do it with) next to the category/area rows the list's
  // own colour stripes are now tied to - a smaller label keeps them visually
  // secondary rather than competing for the same weight.
  final bool compact;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.swatch,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = compact ? Theme.of(context).textTheme.labelSmall : null;

    if (swatch == null) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          labelStyle: labelStyle,
          onSelected: (_) => onSelected(),
        ),
      );
    }

    // Filled with the category/area/provenance's own colour rather than a
    // small leading dot - reads at a glance without a separate swatch+label
    // pair taking up width, so the chip itself can be narrower. Selected vs.
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
        labelStyle: (labelStyle ?? const TextStyle()).copyWith(
          color: selected ? fg : null,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _ExerciseTile extends ConsumerWidget {
  final Exercise exercise;
  final AppColorPalette palette;

  // "Select exercises to export" mode - see _ExerciseLibraryScreenState's
  // own doc comment on _selectingForExport. All default to the pre-existing
  // behaviour so every other caller of this tile (there are none today, but
  // the shape matters) is unaffected.
  final bool selecting;
  final bool selected;
  final ValueChanged<bool>? onSelectedChanged;

  const _ExerciseTile({
    required this.exercise,
    required this.palette,
    this.selecting = false,
    this.selected = false,
    this.onSelectedChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final area = areaForExercise(
      muscleGroups: exercise.muscleGroups,
      category: exercise.category,
      movementPattern: exercise.movementPattern,
    );

    return ListTile(
      // While selecting, a checkbox takes over the leading slot from the
      // two colour stripes - both are informational/interactive
      // placeholders sized the same way a normal tile's leading area is,
      // so the list doesn't visibly reflow just from entering selection
      // mode.
      leading: selecting
          ? Checkbox(
              value: selected,
              onChanged: (value) => onSelectedChanged?.call(value ?? false),
            )
          : SizedBox(
              width: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CategoryStripe(category: exercise.category, palette: palette),
                  const SizedBox(width: 4),
                  MuscleAreaStripe(area: area, palette: palette),
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
      // The favorite star's own tap target would be ambiguous alongside a
      // row-selection tap while selecting - hidden rather than left active
      // and easy to hit by mistake.
      trailing: selecting
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(exercise.measurementType),
                IconButton(
                  icon: Icon(
                    exercise.isFavorite ? Icons.star : Icons.star_border,
                  ),
                  color: exercise.isFavorite ? Colors.amber.shade700 : null,
                  tooltip: exercise.isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  onPressed: () async {
                    await ref
                        .read(appDatabaseProvider)
                        .exerciseDao
                        .setFavorite(exercise.id, !exercise.isFavorite);
                    // One-shot FutureProvider - won't notice this write on
                    // its own.
                    ref.invalidate(filteredExercisesProvider);
                  },
                ),
              ],
            ),
      onTap: selecting
          ? () => onSelectedChanged?.call(!selected)
          : () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ExerciseDetailScreen(exercise: exercise),
              ),
            ),
      onLongPress: selecting ? null : () => _showQuickActions(context),
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
                    builder: (context) =>
                        ExerciseDetailScreen(exercise: exercise),
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
