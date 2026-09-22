import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/app_database.dart';
import '../../data/app_database_provider.dart';
import '../../data/local_storage.dart';
import '../../import/exercise_spreadsheet_parser.dart';
import '../../logic/exercise_images.dart';
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
  final String? csvContent;
  final Uint8List? xlsxBytes;

  /// From a "spreadsheet + pictures (.zip)" import (see `plan_zip_bundle.dart`,
  /// reused as-is - it was already generic, not plan-specific) - a row's
  /// "Picture" column value is looked up here and attached to the exercise
  /// just created for that row. Null for a plain CSV/xlsx import, which has
  /// no image bytes to attach at all.
  final Map<String, Uint8List>? imagesByFileName;

  /// Injectable for testing, same as every attachments-touching function in
  /// `local_storage.dart` - real callers omit it and get the actual
  /// platform attachments directory.
  final Directory? attachmentsDirectory;

  /// Exactly one of [csvContent] (CSV text) or [xlsxBytes] (a decoded
  /// .xlsx workbook) must be provided, not both.
  const ExerciseLibraryImportScreen({
    super.key,
    this.csvContent,
    this.xlsxBytes,
    this.imagesByFileName,
    this.attachmentsDirectory,
  }) : assert(
         (csvContent == null) != (xlsxBytes == null),
         'pass exactly one of csvContent or xlsxBytes',
       );

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
      final csvContent = widget.csvContent;
      _result = csvContent != null
          ? parseExerciseCsv(csvContent)
          : parseExerciseXlsx(widget.xlsxBytes!);
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

    // Wrapped in one transaction rather than a bare loop of awaited writes -
    // a large third-party library import (e.g. wger's ~900-row starter
    // library, see docs/THIRD_PARTY_LICENSES.md) is a real new scale for
    // this screen, previously only ever exercised on dozens of rows.
    await db.transaction(() async {
      for (final row in rows) {
        final id = const Uuid().v4();
        await db.exerciseDao.upsertExercise(
          ExercisesCompanion.insert(
            id: id,
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
            embeddingAllowed: Value(row.embeddingAllowed),
            isCustom: const Value(true),
            author: Value(row.author.trim().isEmpty ? null : row.author.trim()),
          ),
        );
        await _attachPictureIfAny(id, row.picture);
      }
    });

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

  /// Copies a row's "Picture" column value out of the zip bundle's image
  /// map and attaches it to the exercise just created for that row - a
  /// no-op whenever there's no bundle, no picture named for this row, or
  /// that name isn't actually in the bundle (a typo in the spreadsheet,
  /// most likely). Mirrors `PlanImportScreen._attachPictureIfAny` exactly;
  /// not driven by a widget test for the same documented reason that
  /// screen's own copy isn't - covered instead at the level below this:
  /// `readPlanZipBundle` (`plan_zip_bundle_test.dart`) and the "Picture"
  /// column parsing (`exercise_spreadsheet_parser_test.dart`) are both
  /// tested directly; this method is the thin, reviewed-by-eye glue
  /// between them.
  Future<void> _attachPictureIfAny(String exerciseId, String picture) async {
    if (picture.isEmpty) return;
    final images = widget.imagesByFileName;
    if (images == null) return;
    var bytes = images[picture];
    if (bytes == null) {
      // Fall back to a case-insensitive match - a spreadsheet's "Picture"
      // cell and the zip's actual filename don't always agree on case.
      for (final entry in images.entries) {
        if (entry.key.toLowerCase() == picture.toLowerCase()) {
          bytes = entry.value;
          break;
        }
      }
    }
    if (bytes == null) return;

    final dot = picture.lastIndexOf('.');
    final extension = dot == -1 ? '' : picture.substring(dot);
    final savedName = await saveAttachmentFromBytes(
      bytes,
      extension: extension,
      directory: widget.attachmentsDirectory,
    );
    final db = ref.read(appDatabaseProvider);
    await db.exerciseDao.attachImages(
      exerciseId,
      imagePath: savedName,
      imagePaths: joinImagePaths([savedName]),
    );
  }
}
