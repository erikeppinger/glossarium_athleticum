import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../data/daos/plan_dao.dart';
import '../../import/plan_spreadsheet_parser.dart';
import '../exercise_library/exercise_library_providers.dart';
import 'plan_providers.dart';

/// Preview/resolve screen for a plan spreadsheet import. Never silently
/// drops or guesses a row: unparseable rows are listed with their reason,
/// and unmatched exercise names must be explicitly resolved (matched to an
/// existing library exercise, or added as a custom one) before importing.
///
/// Takes exactly one of [csvContent] (CSV text) or [xlsxBytes] (a decoded
/// .xlsx workbook) - not both - so the caller only has to read the picked
/// file, not also decide how to parse it.
class PlanImportScreen extends ConsumerStatefulWidget {
  final String? csvContent;
  final Uint8List? xlsxBytes;
  final String suggestedPlanName;

  const PlanImportScreen({
    super.key,
    this.csvContent,
    this.xlsxBytes,
    required this.suggestedPlanName,
  }) : assert(
         (csvContent == null) != (xlsxBytes == null),
         'pass exactly one of csvContent or xlsxBytes',
       );

  @override
  ConsumerState<PlanImportScreen> createState() => _PlanImportScreenState();
}

class _PlanImportScreenState extends ConsumerState<PlanImportScreen> {
  late final TextEditingController _nameController;
  PlanImportResult? _result;
  String? _formatError;
  final Map<int, String> _resolvedByRowNumber = {};
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.suggestedPlanName);
    try {
      final csvContent = widget.csvContent;
      _result = csvContent != null
          ? parsePlanCsv(csvContent)
          : parsePlanXlsx(widget.xlsxBytes!);
    } on PlanImportFormatException catch (e) {
      _formatError = e.message;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Resolving unmatched exercises row-by-row (or renaming the plan) is real
  // work with nowhere else to go if the screen is backed out of - without
  // this, a single accidental back press silently threw all of it away.
  bool get _hasUnsavedChanges =>
      _resolvedByRowNumber.isNotEmpty ||
      _nameController.text.trim() != widget.suggestedPlanName.trim();

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard import?'),
        content: const Text(
          'This plan has not been imported yet, and any exercises you '
          "matched or added won't be applied to it.",
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

  @override
  Widget build(BuildContext context) {
    if (_formatError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Import plan')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not read this file:\n\n$_formatError',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final libraryAsync = ref.watch(allExercisesForMatchingProvider);

    // canPop is read fresh on every pop attempt from whatever's last built,
    // but the plain Plan-name TextField doesn't rebuild this widget on each
    // keystroke - so without this listener, typing a new name wouldn't ever
    // flip canPop to false.
    return ListenableBuilder(
      listenable: _nameController,
      builder: (context, _) => PopScope(
        canPop: _importing || !_hasUnsavedChanges,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _confirmDiscard();
        },
        child: _buildScaffold(context, libraryAsync),
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    AsyncValue<List<Exercise>> libraryAsync,
  ) {
    final result = _result!;
    return Scaffold(
      appBar: AppBar(title: const Text('Import plan')),
      body: libraryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (library) {
          final matched = matchExercisesAgainstLibrary(result.rows, library)
              .map(
                (r) => r.withMatchedExerciseId(
                  _resolvedByRowNumber[r.rowNumber] ?? r.matchedExerciseId,
                ),
              )
              .toList();
          final unmatched =
              matched.where((r) => r.matchedExerciseId == null).toList();
          final distinctUnmatched = _distinctByName(unmatched);

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Plan name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (result.errors.isNotEmpty) ...[
                      Card(
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: ExpansionTile(
                          title: Text(
                            '${result.errors.length} row(s) skipped due to errors',
                          ),
                          children: [
                            for (final e in result.errors)
                              ListTile(
                                dense: true,
                                title: Text('Row ${e.rowNumber}: ${e.message}'),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (distinctUnmatched.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Unmatched exercises (${distinctUnmatched.length})',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          // A large plan can reference dozens of exercises
                          // that don't exist in the library yet (a 71-row
                          // import surfaced this) - resolving each one by
                          // hand via "Match existing"/"Add as custom" isn't
                          // reasonable at that scale, so this adds every
                          // still-unresolved one as a plain custom exercise
                          // in a single action. Anyone who wants to match a
                          // few to existing library entries first still can -
                          // this only ever touches what's still unmatched.
                          TextButton(
                            onPressed: () =>
                                _resolveAllAsCustom(distinctUnmatched),
                            child: const Text('Add all as custom'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (final row in distinctUnmatched)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  row.exerciseName,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const Text('Not found in your library'),
                                const SizedBox(height: 8),
                                OverflowBar(
                                  alignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          _pickExisting(context, row, library),
                                      child: const Text('Match existing'),
                                    ),
                                    FilledButton(
                                      onPressed: () => _createCustom(row),
                                      child: const Text('Add as custom'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Sessions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    for (final session in groupIntoSessions(matched))
                      Card(
                        child: ListTile(
                          title: Text(
                            'Week ${session.weekNumber} • ${session.day} • ${session.sessionName}',
                          ),
                          subtitle: Text(
                            session.rows.map((r) => r.exerciseName).join(', '),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Pinned outside the scrollable list - with a long unmatched
              // list (the 71-row import that surfaced this) this button was
              // the only way to see the plan was blocked or ready, and it
              // was easy to miss entirely at the very bottom of a long
              // scroll.
              SafeArea(
                minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton(
                  onPressed: unmatched.isEmpty && !_importing
                      ? () => _import(matched)
                      : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(
                    unmatched.isEmpty
                        ? 'Import plan'
                        : 'Resolve ${unmatched.length} exercise(s) to continue',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<PlanImportRow> _distinctByName(List<PlanImportRow> rows) {
    final seen = <String>{};
    return rows.where((r) => seen.add(r.exerciseName.toLowerCase())).toList();
  }

  Future<void> _pickExisting(
    BuildContext context,
    PlanImportRow row,
    List<Exercise> library,
  ) async {
    final selected = await showDialog<Exercise>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Match "${row.exerciseName}" to'),
        children: [
          for (final exercise in library)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(exercise),
              child: Text(exercise.name),
            ),
        ],
      ),
    );
    if (selected != null) {
      _resolveAllWithName(row.exerciseName, selected.id);
    }
  }

  Future<void> _createCustom(PlanImportRow row) async {
    final db = ref.read(appDatabaseProvider);
    final id = const Uuid().v4();
    await db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: id,
        name: row.exerciseName,
        category: 'Custom',
        movementPattern: '',
        muscleGroups: '',
        equipment: '',
        difficulty: 'Beginner',
        measurementType: 'Weight x Reps',
        isCustom: const Value(true),
        sourcePlanName: Value(_nameController.text.trim()),
      ),
    );
    ref.invalidate(allExercisesForMatchingProvider);
    // Exercise Library's providers are separate one-shot Futures that don't
    // notice a custom exercise created from this screen on their own.
    ref.invalidate(filteredExercisesProvider);
    ref.invalidate(exerciseCategoriesProvider);
    ref.invalidate(creatorFilterOptionsProvider);
    _resolveAllWithName(row.exerciseName, id);
  }

  /// Same as [_createCustom], but for every still-unmatched name in one
  /// action - one DB write per exercise, then a single invalidate/setState
  /// pass at the end rather than one of each per row, so this stays
  /// reasonable at the scale that motivated it (dozens of rows).
  Future<void> _resolveAllAsCustom(List<PlanImportRow> rows) async {
    final db = ref.read(appDatabaseProvider);
    final planName = _nameController.text.trim();
    final idsByName = <String, String>{};

    for (final row in rows) {
      final id = const Uuid().v4();
      await db.exerciseDao.upsertExercise(
        ExercisesCompanion.insert(
          id: id,
          name: row.exerciseName,
          category: 'Custom',
          movementPattern: '',
          muscleGroups: '',
          equipment: '',
          difficulty: 'Beginner',
          measurementType: 'Weight x Reps',
          isCustom: const Value(true),
          sourcePlanName: Value(planName),
        ),
      );
      idsByName[row.exerciseName.toLowerCase()] = id;
    }

    ref.invalidate(allExercisesForMatchingProvider);
    ref.invalidate(filteredExercisesProvider);
    ref.invalidate(exerciseCategoriesProvider);
    ref.invalidate(creatorFilterOptionsProvider);

    setState(() {
      final result = _result!;
      for (final r in result.rows) {
        final id = idsByName[r.exerciseName.toLowerCase()];
        if (id != null) _resolvedByRowNumber[r.rowNumber] = id;
      }
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${rows.length} exercise${rows.length == 1 ? '' : 's'} added to your library.',
        ),
      ),
    );
  }

  void _resolveAllWithName(String exerciseName, String exerciseId) {
    setState(() {
      final result = _result!;
      for (final r in result.rows) {
        if (r.exerciseName.toLowerCase() == exerciseName.toLowerCase()) {
          _resolvedByRowNumber[r.rowNumber] = exerciseId;
        }
      }
    });
  }

  Future<void> _import(List<PlanImportRow> matched) async {
    setState(() => _importing = true);
    final db = ref.read(appDatabaseProvider);
    final sessions = groupIntoSessions(matched)
        .map(
          (s) => PlanSessionInput(
            weekNumber: s.weekNumber,
            day: s.day,
            sessionName: s.sessionName,
            exercises: s.rows
                .map(
                  (r) => PlanExerciseInput(
                    order: r.order,
                    exerciseId: r.matchedExerciseId,
                    exerciseName: r.exerciseName,
                    sets: r.sets,
                    reps: r.reps,
                    weightIntensity: r.weightIntensity,
                    restSec: r.restSec,
                    notes: r.notes,
                    videoUrl: r.videoUrl,
                  ),
                )
                .toList(),
          ),
        )
        .toList();

    await db.planDao.createPlan(
      id: const Uuid().v4(),
      name: _nameController.text.trim().isEmpty
          ? 'Imported plan'
          : _nameController.text.trim(),
      sessions: sessions,
    );

    if (mounted) Navigator.of(context).pop();
  }
}
