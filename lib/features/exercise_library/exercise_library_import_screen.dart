import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../import/exercise_spreadsheet_parser.dart';
import '../plans/plan_providers.dart';
import 'exercise_library_providers.dart';

/// Preview/import screen for an exercise-library spreadsheet - the missing
/// half of TemplatesScreen's "Exercise library" template (a downloadable
/// copy of seed-data/strongman_exercise_database.csv), which previously had
/// nowhere to be imported back into: the Exercise Library screen's import
/// button only ever accepted this app's own .json/.tlibrary export.
///
/// Deliberately does not try to match rows against the existing library and
/// update in place - every row always becomes a new custom exercise. A
/// spreadsheet whose row happens to share a name with a seeded/official
/// exercise (or someone else's custom one) must never silently overwrite
/// it just because the names coincide; [countNameCollisions] only powers an
/// informational heads-up here, never a merge decision.
class ExerciseLibraryImportScreen extends ConsumerStatefulWidget {
  final String csvContent;

  const ExerciseLibraryImportScreen({super.key, required this.csvContent});

  @override
  ConsumerState<ExerciseLibraryImportScreen> createState() =>
      _ExerciseLibraryImportScreenState();
}

class _ExerciseLibraryImportScreenState
    extends ConsumerState<ExerciseLibraryImportScreen> {
  ExerciseImportResult? _result;
  String? _formatError;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    try {
      _result = parseExerciseCsv(widget.csvContent);
    } on ExerciseImportFormatException catch (e) {
      _formatError = e.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_formatError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Import exercise library')),
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

    final result = _result!;
    final libraryAsync = ref.watch(allExercisesForMatchingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Import exercise library')),
      body: libraryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (library) {
          final collisions = countNameCollisions(result.rows, library);
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Every row below will be added to your library as a '
                      'new custom exercise, even if its name matches one you '
                      'already have.',
                      style: Theme.of(context).textTheme.bodyMedium,
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
                    if (collisions > 0) ...[
                      Card(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            '$collisions of these share a name with an '
                            "exercise you already have - they'll be added as "
                            'separate entries, not merged into it.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Exercises to import (${result.rows.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final row in result.rows)
                      Card(
                        child: ListTile(
                          title: Text(row.name),
                          subtitle: Text(
                            '${row.category} • ${row.difficulty} • ${row.measurementType}',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SafeArea(
                minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton(
                  onPressed: result.rows.isEmpty || _importing
                      ? null
                      : () => _import(result.rows),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text('Import ${result.rows.length} exercise(s)'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _import(List<ExerciseImportRow> rows) async {
    setState(() => _importing = true);
    final db = ref.read(appDatabaseProvider);

    for (final row in rows) {
      await db.exerciseDao.upsertExercise(
        ExercisesCompanion.insert(
          id: const Uuid().v4(),
          name: row.name,
          category: row.category,
          movementPattern: row.movementPattern,
          muscleGroups: row.muscleGroups,
          equipment: row.equipment,
          difficulty: row.difficulty,
          measurementType: row.measurementType,
          description: Value(row.description),
          safetyNotes: Value(row.safetyNotes),
          videoReference: Value(row.videoReference),
          isCustom: const Value(true),
        ),
      );
    }

    // These are one-shot FutureProviders that don't notice a write made
    // from this screen on their own - see CLAUDE.md's note on this gotcha,
    // also worked around the same way in plan_import_screen.dart.
    ref.invalidate(allExercisesForMatchingProvider);
    ref.invalidate(filteredExercisesProvider);
    ref.invalidate(exerciseCategoriesProvider);
    ref.invalidate(creatorFilterOptionsProvider);

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Imported ${rows.length} exercise${rows.length == 1 ? '' : 's'}.',
        ),
      ),
    );
  }
}
