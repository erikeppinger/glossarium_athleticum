import 'package:csv/csv.dart';

import '../data/app_database.dart';
import '../logic/exercise_name_matching.dart';

/// Column names the template defines, in the order documented in
/// templates/training_plan_template.csv - order in the actual file may
/// differ, columns are matched by name, not position.
const _requiredColumns = [
  'Week',
  'Day',
  'Session Name',
  'Order',
  'Exercise Name',
  'Sets',
  'Reps',
];
/// Guards against a pathologically large upload rather than trying to
/// stream/paginate a spreadsheet import - flat plan templates are small by
/// design (one row per exercise-in-session).
const maxImportRows = 5000;

/// Thrown for structural failures that make the whole file unusable -
/// as opposed to a per-row problem, which is reported via [PlanImportResult.errors]
/// instead so the rest of the file can still be imported.
class PlanImportFormatException implements Exception {
  final String message;
  PlanImportFormatException(this.message);
  @override
  String toString() => message;
}

/// One exercise-in-session row, successfully parsed and type-coerced.
/// [matchedExerciseId] starts null and is filled in by
/// [matchExercisesAgainstLibrary] - null after matching means the row needs
/// manual resolution in the import-preview screen.
class PlanImportRow {
  final int rowNumber;
  final int week;
  final String day;
  final String sessionName;
  final int order;
  final String exerciseName;
  final int sets;
  final String reps;
  final String weightIntensity;
  final int? restSec;
  final String notes;
  final String videoUrl;
  final String? matchedExerciseId;

  const PlanImportRow({
    required this.rowNumber,
    required this.week,
    required this.day,
    required this.sessionName,
    required this.order,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    this.weightIntensity = '',
    this.restSec,
    this.notes = '',
    this.videoUrl = '',
    this.matchedExerciseId,
  });

  PlanImportRow withMatchedExerciseId(String? id) => PlanImportRow(
        rowNumber: rowNumber,
        week: week,
        day: day,
        sessionName: sessionName,
        order: order,
        exerciseName: exerciseName,
        sets: sets,
        reps: reps,
        weightIntensity: weightIntensity,
        restSec: restSec,
        notes: notes,
        videoUrl: videoUrl,
        matchedExerciseId: id,
      );
}

/// A row that couldn't be parsed - missing a required field or a numeric
/// field that isn't a valid number. Reported, never silently dropped.
class PlanImportRowError {
  final int rowNumber;
  final List<String> rawRow;
  final String message;

  const PlanImportRowError({
    required this.rowNumber,
    required this.rawRow,
    required this.message,
  });
}

class PlanImportResult {
  final List<PlanImportRow> rows;
  final List<PlanImportRowError> errors;

  const PlanImportResult({required this.rows, required this.errors});

  bool get hasErrors => errors.isNotEmpty;
}

/// Parses a plan spreadsheet (CSV text, as exported from Excel/Sheets) into
/// [PlanImportResult]. Columns are matched by header name (case-insensitive),
/// so reordered columns parse the same as the canonical template. Malformed
/// rows are collected in [PlanImportResult.errors] rather than thrown, so one
/// bad row doesn't block importing the rest of the file. Structural problems
/// (a required column missing entirely, or the file exceeding [maxImportRows])
/// throw [PlanImportFormatException] since there's nothing to preview.
PlanImportResult parsePlanCsv(String csvContent) {
  final rawRows = Csv(lineDelimiter: '\n')
      .decode(csvContent.replaceAll('\r\n', '\n'));

  if (rawRows.isEmpty) {
    throw PlanImportFormatException('The file is empty.');
  }

  final header = rawRows.first.map((c) => c.toString().trim()).toList();
  final columnIndex = <String, int>{};
  for (var i = 0; i < header.length; i++) {
    columnIndex[header[i]] = i;
  }

  final missing = _requiredColumns.where((c) => !columnIndex.containsKey(c));
  if (missing.isNotEmpty) {
    throw PlanImportFormatException(
      'Missing required column(s): ${missing.join(', ')}',
    );
  }

  final dataRows = rawRows.skip(1).toList();
  if (dataRows.length > maxImportRows) {
    throw PlanImportFormatException(
      'This file has ${dataRows.length} rows, which is more than the '
      '$maxImportRows-row limit for a single plan import.',
    );
  }

  final rows = <PlanImportRow>[];
  final errors = <PlanImportRowError>[];

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
        PlanImportRowError(
          rowNumber: rowNumber,
          rawRow: raw,
          message: 'Missing required value(s): ${missingFields.join(', ')}',
        ),
      );
      continue;
    }

    final week = int.tryParse(cell('Week'));
    final order = int.tryParse(cell('Order'));
    final sets = int.tryParse(cell('Sets'));
    final restRaw = cell('Rest (sec)');
    final restSec = restRaw.isEmpty ? null : int.tryParse(restRaw);

    final numericErrors = <String>[
      if (week == null) 'Week',
      if (order == null) 'Order',
      if (sets == null) 'Sets',
      if (restRaw.isNotEmpty && restSec == null) 'Rest (sec)',
    ];
    if (numericErrors.isNotEmpty) {
      errors.add(
        PlanImportRowError(
          rowNumber: rowNumber,
          rawRow: raw,
          message: 'Invalid number in column(s): ${numericErrors.join(', ')}',
        ),
      );
      continue;
    }

    rows.add(
      PlanImportRow(
        rowNumber: rowNumber,
        week: week!,
        day: cell('Day'),
        sessionName: cell('Session Name'),
        order: order!,
        exerciseName: cell('Exercise Name'),
        sets: sets!,
        reps: cell('Reps'),
        weightIntensity: cell('Weight/Intensity'),
        restSec: restSec,
        notes: cell('Notes'),
        videoUrl: cell('Video URL'),
      ),
    );
  }

  return PlanImportResult(rows: rows, errors: errors);
}

/// Matches each row's [PlanImportRow.exerciseName] against the exercise
/// library by exact (case/punctuation-insensitive) match, filling in
/// [PlanImportRow.matchedExerciseId]. Rows with no match keep it null -
/// the import-preview screen lets the user pick a library match or create
/// the name as a custom exercise; this function never guesses.
List<PlanImportRow> matchExercisesAgainstLibrary(
  List<PlanImportRow> rows,
  List<Exercise> library,
) {
  final byNormalizedName = <String, String>{
    for (final e in library) normalizeExerciseName(e.name): e.id,
  };
  return rows
      .map(
        (r) => r.withMatchedExerciseId(
          byNormalizedName[normalizeExerciseName(r.exerciseName)],
        ),
      )
      .toList();
}

/// Groups flat [PlanImportRow]s (as parsed from the spreadsheet) into the
/// Week -> Session -> exercises nesting schema/plan.schema.json describes,
/// ready to hand to PlanDao.createPlan. Only call this once every row has
/// been resolved (matched or turned into a custom exercise) - it doesn't
/// itself flag unmatched rows.
List<({int weekNumber, String day, String sessionName, List<PlanImportRow> rows})>
    groupIntoSessions(List<PlanImportRow> rows) {
  final order = <String>[];
  final groups = <String, List<PlanImportRow>>{};
  for (final row in rows) {
    final key = '${row.week}|${row.day}|${row.sessionName}';
    if (!groups.containsKey(key)) order.add(key);
    groups.putIfAbsent(key, () => []).add(row);
  }
  return order.map((key) {
    final parts = key.split('|');
    final rowsForKey = groups[key]!..sort((a, b) => a.order.compareTo(b.order));
    return (
      weekNumber: int.parse(parts[0]),
      day: parts[1],
      sessionName: parts[2],
      rows: rowsForKey,
    );
  }).toList();
}
