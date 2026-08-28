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
class PlanImportScreen extends ConsumerStatefulWidget {
  final String csvContent;
  final String suggestedPlanName;

  const PlanImportScreen({
    super.key,
    required this.csvContent,
    required this.suggestedPlanName,
  });

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
      _result = parsePlanCsv(widget.csvContent);
    } on PlanImportFormatException catch (e) {
      _formatError = e.message;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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

    final result = _result!;
    final libraryAsync = ref.watch(allExercisesForMatchingProvider);

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

          return ListView(
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
              if (unmatched.isNotEmpty) ...[
                Text(
                  'Unmatched exercises',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final row in _distinctByName(unmatched))
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
              const SizedBox(height: 24),
              FilledButton(
                onPressed: unmatched.isEmpty && !_importing
                    ? () => _import(matched)
                    : null,
                child: Text(
                  unmatched.isEmpty
                      ? 'Import plan'
                      : 'Resolve ${unmatched.length} exercise(s) to continue',
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
