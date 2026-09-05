import 'dart:typed_data';

import 'package:csv/csv.dart';

import '../data/app_database.dart';
import '../features/exercise_library/create_exercise_screen.dart'
    show difficulties;
import '../logic/exercise_name_matching.dart';
import 'xlsx_reader.dart';

/// Column names the template defines, in the order documented in
/// seed-data/strongman_exercise_database.csv - order in the actual file may
/// differ, columns are matched by name, not position. No "Exercise ID"
/// column: every imported row always becomes a brand-new custom exercise
/// (see ExerciseLibraryImportScreen's doc comment for why), so there's
/// nothing for a user-supplied id to do.
const _requiredColumns = ['Exercise Name', 'Category', 'Difficulty', 'Measurement Type'];

/// Guards against a pathologically large upload, matching plan_spreadsheet_parser.dart's
/// reasoning - a hand-authored exercise library is small by design.
const maxExerciseImportRows = 5000;

/// Thrown for structural failures that make the whole file unusable - as
/// opposed to a per-row problem, which is reported via
/// [ExerciseImportResult.errors] instead so the rest of the file still
/// imports.
class ExerciseImportFormatException implements Exception {
  final String message;
  ExerciseImportFormatException(this.message);
  @override
  String toString() => message;
}

/// One exercise row, successfully parsed and validated. Always becomes a
/// new custom exercise on import - see ExerciseLibraryImportScreen.
class ExerciseImportRow {
  final int rowNumber;
  final String name;
  final String category;
  final String movementPattern;
  final String muscleGroups;
  final String equipment;
  final String difficulty;
  final String measurementType;
  final String description;
  final String safetyNotes;
  final String videoReference;

  const ExerciseImportRow({
    required this.rowNumber,
    required this.name,
    required this.category,
    this.movementPattern = '',
    this.muscleGroups = '',
    this.equipment = '',
    required this.difficulty,
    required this.measurementType,
    this.description = '',
    this.safetyNotes = '',
    this.videoReference = '',
  });
}

/// A row that couldn't be parsed - missing a required field or an
/// unrecognized Difficulty/Measurement Type value. Reported, never silently
/// dropped or coerced.
class ExerciseImportRowError {
  final int rowNumber;
  final List<String> rawRow;
  final String message;

  const ExerciseImportRowError({
    required this.rowNumber,
    required this.rawRow,
    required this.message,
  });
}

class ExerciseImportResult {
  final List<ExerciseImportRow> rows;
  final List<ExerciseImportRowError> errors;

  const ExerciseImportResult({required this.rows, required this.errors});

  bool get hasErrors => errors.isNotEmpty;
}

/// Parses an exercise-library spreadsheet (CSV text, as exported from
/// Excel/Sheets, or the seed-data template) into [ExerciseImportResult].
/// Columns are matched by header name, so a reordered template parses the
/// same as the canonical one. Malformed rows are collected in
/// [ExerciseImportResult.errors] rather than thrown, so one bad row doesn't
/// block importing the rest of the file; structural problems (a required
/// column missing entirely, an empty file, or exceeding
/// [maxExerciseImportRows]) throw [ExerciseImportFormatException] since
/// there's nothing to preview.
ExerciseImportResult parseExerciseCsv(String csvContent) {
  final rawRows = Csv(
    lineDelimiter: '\n',
  ).decode(csvContent.replaceAll('\r\n', '\n'));
  return _parseExerciseRows(rawRows);
}

/// Same as [parseExerciseCsv], reading an .xlsx workbook instead of CSV
/// text - see `xlsx_reader.dart` for why this app has its own minimal
/// reader rather than a library. Tries each sheet in the workbook's own
/// order and uses the first one whose header row has every required
/// column, so a template's Legend tab ahead of the real data sheet is
/// skipped automatically.
ExerciseImportResult parseExerciseXlsx(Uint8List bytes) {
  final sheets = readXlsxSheets(bytes);
  for (final rows in sheets) {
    if (rows.isEmpty) continue;
    final header = rows.first.map((c) => c.trim()).toSet();
    if (_requiredColumns.every(header.contains)) {
      return _parseExerciseRows(rows);
    }
  }
  throw ExerciseImportFormatException(
    'None of the ${sheets.length} sheet(s) in this file have the required '
    'columns: ${_requiredColumns.join(', ')}.',
  );
}

ExerciseImportResult _parseExerciseRows(List<List<dynamic>> rawRows) {
  if (rawRows.isEmpty) {
    throw ExerciseImportFormatException('The file is empty.');
  }

  final header = rawRows.first.map((c) => c.toString().trim()).toList();
  final columnIndex = <String, int>{};
  for (var i = 0; i < header.length; i++) {
    columnIndex[header[i]] = i;
  }

  final missing = _requiredColumns.where((c) => !columnIndex.containsKey(c));
  if (missing.isNotEmpty) {
    throw ExerciseImportFormatException(
      'Missing required column(s): ${missing.join(', ')}',
    );
  }

  final dataRows = rawRows.skip(1).toList();
  if (dataRows.length > maxExerciseImportRows) {
    throw ExerciseImportFormatException(
      'This file has ${dataRows.length} rows, which is more than the '
      '$maxExerciseImportRows-row limit for a single library import.',
    );
  }

  final rows = <ExerciseImportRow>[];
  final errors = <ExerciseImportRowError>[];

  for (var i = 0; i < dataRows.length; i++) {
    final rowNumber = i + 2; // +1 for header, +1 for 1-based
    final raw = dataRows[i].map((c) => c.toString()).toList();

    String cell(String column) {
      final idx = columnIndex[column];
      if (idx == null || idx >= raw.length) return '';
      return raw[idx].trim();
    }

    final allBlank = raw.every((c) => c.trim().isEmpty);
    if (allBlank) continue; // empty rows are skipped, not errors

    final missingFields = _requiredColumns.where((c) => cell(c).isEmpty);
    if (missingFields.isNotEmpty) {
      errors.add(
        ExerciseImportRowError(
          rowNumber: rowNumber,
          rawRow: raw,
          message: 'Missing required value(s): ${missingFields.join(', ')}',
        ),
      );
      continue;
    }

    final difficulty = cell('Difficulty');
    final measurementType = cell('Measurement Type');
    // Difficulty really is a closed set everywhere (the seed library never
    // uses anything but these three) - but Measurement Type isn't: the
    // column is free text at the database level, and the seed library's
    // own real data uses compound values like "Weight x Reps or Max Load"
    // that create_exercise_screen.dart's single-exercise picker (a closed
    // 5-value list, meant for one exercise at a time) never offers. Only
    // required-non-empty (checked above) applies to it here.
    final invalidValues = <String>[
      if (!difficulties.contains(difficulty)) 'Difficulty',
    ];
    if (invalidValues.isNotEmpty) {
      errors.add(
        ExerciseImportRowError(
          rowNumber: rowNumber,
          rawRow: raw,
          message: 'Invalid value in column(s): ${invalidValues.join(', ')}',
        ),
      );
      continue;
    }

    rows.add(
      ExerciseImportRow(
        rowNumber: rowNumber,
        name: cell('Exercise Name'),
        category: cell('Category'),
        movementPattern: cell('Movement Pattern'),
        muscleGroups: cell('Muscle Group(s)'),
        equipment: cell('Equipment'),
        difficulty: difficulty,
        measurementType: measurementType,
        description: cell('Description / Cues'),
        safetyNotes: cell('Safety Notes'),
        videoReference: cell('Video Reference'),
      ),
    );
  }

  return ExerciseImportResult(rows: rows, errors: errors);
}

/// Counts rows whose name matches (case/punctuation-insensitive) an
/// exercise already in the library - purely informational. Every row is
/// imported as a new custom exercise regardless (see
/// ExerciseLibraryImportScreen's doc comment for why matching never merges),
/// so this only powers a heads-up in the preview screen, never a decision.
int countNameCollisions(List<ExerciseImportRow> rows, List<Exercise> library) {
  final existingNames = library.map((e) => normalizeExerciseName(e.name)).toSet();
  return rows
      .where((r) => existingNames.contains(normalizeExerciseName(r.name)))
      .length;
}
