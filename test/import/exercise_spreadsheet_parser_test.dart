import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/import/exercise_spreadsheet_parser.dart';

const _header =
    'Exercise Name,Category,Movement Pattern,Muscle Group(s),Equipment,'
    'Difficulty,Measurement Type,Description / Cues,Safety Notes,'
    'Video Reference';

void main() {
  group('parseExerciseCsv', () {
    test('parses a well-formed file into rows with no errors', () {
      const csv = '''
$_header
Bench Press,Main Lift,Push,Chest,Barbell,Intermediate,Weight x Reps,Pause at chest,Keep shoulders back,https://example.com/v
''';
      final result = parseExerciseCsv(csv);
      expect(result.hasErrors, isFalse);
      expect(result.rows, hasLength(1));
      final row = result.rows.single;
      expect(row.name, 'Bench Press');
      expect(row.category, 'Main Lift');
      expect(row.movementPattern, 'Push');
      expect(row.muscleGroups, 'Chest');
      expect(row.equipment, 'Barbell');
      expect(row.difficulty, 'Intermediate');
      expect(row.measurementType, 'Weight x Reps');
      expect(row.description, 'Pause at chest');
      expect(row.safetyNotes, 'Keep shoulders back');
      expect(row.videoReference, 'https://example.com/v');
    });

    test('optional columns default to empty when absent from the header', () {
      const csv = '''
Exercise Name,Category,Difficulty,Measurement Type
Hip Circles,Warm-up,Beginner,Time
''';
      final result = parseExerciseCsv(csv);
      expect(result.hasErrors, isFalse);
      final row = result.rows.single;
      expect(row.movementPattern, isEmpty);
      expect(row.muscleGroups, isEmpty);
      expect(row.equipment, isEmpty);
      expect(row.description, isEmpty);
      expect(row.safetyNotes, isEmpty);
      expect(row.videoReference, isEmpty);
    });

    test('skips fully empty rows without reporting them as errors', () {
      const csv = '''
$_header
Bench Press,Main Lift,Push,Chest,Barbell,Intermediate,Weight x Reps,,,
,,,,,,,,,
''';
      final result = parseExerciseCsv(csv);
      expect(result.hasErrors, isFalse);
      expect(result.rows, hasLength(1));
    });

    test('reordered columns parse identically by header name', () {
      const reordered =
          'Difficulty,Exercise Name,Measurement Type,Category';
      const csv = '''
$reordered
Intermediate,Bench Press,Weight x Reps,Main Lift
''';
      final result = parseExerciseCsv(csv);
      expect(result.hasErrors, isFalse);
      final row = result.rows.single;
      expect(row.name, 'Bench Press');
      expect(row.category, 'Main Lift');
      expect(row.difficulty, 'Intermediate');
      expect(row.measurementType, 'Weight x Reps');
    });

    test('throws when a required column is missing entirely', () {
      const csv = '''
Category,Difficulty,Measurement Type
Main Lift,Intermediate,Weight x Reps
''';
      expect(
        () => parseExerciseCsv(csv),
        throwsA(
          isA<ExerciseImportFormatException>().having(
            (e) => e.message,
            'message',
            contains('Exercise Name'),
          ),
        ),
      );
    });

    test('reports a row missing a required value as an error, not a crash', () {
      const csv = '''
$_header
,Main Lift,Push,Chest,Barbell,Intermediate,Weight x Reps,,,
''';
      final result = parseExerciseCsv(csv);
      expect(result.rows, isEmpty);
      expect(result.errors, hasLength(1));
      expect(result.errors.single.message, contains('Exercise Name'));
      expect(result.errors.single.rowNumber, 2);
    });

    test('reports an unrecognized Difficulty or Measurement Type as a row error', () {
      const csv = '''
$_header
Bench Press,Main Lift,Push,Chest,Barbell,Expert,Kilograms,,,
''';
      final result = parseExerciseCsv(csv);
      expect(result.rows, isEmpty);
      expect(result.errors, hasLength(1));
      final message = result.errors.single.message;
      expect(message, contains('Difficulty'));
      expect(message, contains('Measurement Type'));
    });

    test('throws for a file over the row limit', () {
      final rows = List.generate(
        maxExerciseImportRows + 1,
        (i) => 'Exercise $i,Main Lift,Push,Chest,Barbell,Intermediate,Weight x Reps,,,',
      ).join('\n');
      final csv = '$_header\n$rows\n';
      expect(
        () => parseExerciseCsv(csv),
        throwsA(isA<ExerciseImportFormatException>()),
      );
    });

    test('throws for a completely empty file', () {
      expect(() => parseExerciseCsv(''), throwsA(isA<ExerciseImportFormatException>()));
    });
  });

  group('countNameCollisions', () {
    Exercise exercise(String id, String name) => Exercise(
      id: id,
      name: name,
      category: 'Main Lift',
      movementPattern: 'Push',
      muscleGroups: 'Chest',
      equipment: 'Barbell',
      difficulty: 'Intermediate',
      measurementType: 'Weight x Reps',
      description: '',
      safetyNotes: '',
      videoReference: '',
      isCustom: false,
    );

    test('counts rows matching an existing name case/punctuation-insensitively', () {
      final rows = parseExerciseCsv('''
$_header
bench press,Main Lift,Push,Chest,Barbell,Intermediate,Weight x Reps,,,
Overhead Press,Main Lift,Push,Shoulders,Barbell,Intermediate,Weight x Reps,,,
''').rows;
      final count = countNameCollisions(rows, [exercise('EX010', 'Bench Press')]);
      expect(count, 1);
    });

    test('is zero when nothing in the library shares a name', () {
      final rows = parseExerciseCsv('''
$_header
Some New Exercise,Main Lift,Push,Chest,Barbell,Intermediate,Weight x Reps,,,
''').rows;
      final count = countNameCollisions(rows, [exercise('EX010', 'Bench Press')]);
      expect(count, 0);
    });
  });
}
