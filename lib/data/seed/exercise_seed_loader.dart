import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../logic/video_embedding.dart';
import '../app_database.dart';

const seedExerciseCsvAsset = 'assets/seed-data/strongman_exercise_database.csv';

/// Parses the seed exercise CSV (columns: Exercise ID, Exercise Name,
/// Category, Movement Pattern, Muscle Group(s), Equipment, Difficulty,
/// Measurement Type, Description / Cues, Safety Notes, Video Reference,
/// Embedding) into rows ready to upsert into the Exercises table.
List<ExercisesCompanion> parseExerciseSeedCsv(String csvContent) {
  final rows = Csv(
    lineDelimiter: '\n',
  ).decode(csvContent.replaceAll('\r\n', '\n'));
  if (rows.isEmpty) return const [];

  final dataRows = rows.skip(1); // drop header
  return dataRows
      .where((row) => row.isNotEmpty && row.any((cell) => cell.toString().trim().isNotEmpty))
      .map((row) {
        String cell(int i) => i < row.length ? row[i].toString().trim() : '';
        return ExercisesCompanion.insert(
          id: cell(0),
          name: cell(1),
          category: cell(2),
          movementPattern: cell(3),
          muscleGroups: _normalizeMuscleGroups(cell(4)),
          equipment: cell(5),
          difficulty: cell(6),
          measurementType: cell(7),
          description: Value(cell(8)),
          safetyNotes: Value(cell(9)),
          videoReference: Value(cell(10)),
          embeddingAllowed: Value(parseEmbeddingFlag(cell(11))),
          isCustom: const Value(false),
        );
      })
      .toList();
}

/// "Shoulders & Upper Back" -> "Shoulders, Upper Back" so downstream code
/// can split on ", " consistently regardless of the source formatting.
String _normalizeMuscleGroups(String raw) {
  final parts = raw
      .split(RegExp(r'\s*&\s*|\s*,\s*'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty);
  return parts.join(', ');
}

/// Loads and upserts the bundled seed exercise library into [db].
/// Safe to call every app start - upserts by id, so re-seeding doesn't
/// duplicate rows or clobber custom exercises (which use generated ids
/// outside the seed file's EX### range).
Future<void> seedExerciseLibrary(AppDatabase db) async {
  final csvContent = await rootBundle.loadString(seedExerciseCsvAsset);
  final entries = parseExerciseSeedCsv(csvContent);
  await db.exerciseDao.upsertExercises(entries);
}
