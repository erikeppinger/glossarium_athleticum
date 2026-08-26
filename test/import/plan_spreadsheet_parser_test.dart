import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/import/plan_spreadsheet_parser.dart';

const _header =
    'Week,Day,Session Name,Order,Exercise Name,Sets,Reps,Weight/Intensity,Rest (sec),Notes,Video URL';

void main() {
  group('parsePlanCsv', () {
    test('parses a well-formed file into rows with no errors', () {
      const csv = '''
$_header
1,Mon,Push Day,1,Bench Press,4,8-10,60kg,90,Pause at chest,
1,Mon,Push Day,2,Overhead Press,3,8-10,35kg,90,,https://example.com/v
''';
      final result = parsePlanCsv(csv);
      expect(result.hasErrors, isFalse);
      expect(result.rows, hasLength(2));
      expect(result.rows[0].exerciseName, 'Bench Press');
      expect(result.rows[0].sets, 4);
      expect(result.rows[0].restSec, 90);
      expect(result.rows[1].videoUrl, 'https://example.com/v');
    });

    test('skips fully empty rows without reporting them as errors', () {
      const csv = '''
$_header
1,Mon,Push Day,1,Bench Press,4,8-10,60kg,90,,
,,,,,,,,,,
''';
      final result = parsePlanCsv(csv);
      expect(result.hasErrors, isFalse);
      expect(result.rows, hasLength(1));
    });

    test('reordered columns parse identically by header name', () {
      const reordered = 'Exercise Name,Sets,Reps,Week,Day,Session Name,Order,Notes,Video URL,Weight/Intensity,Rest (sec)';
      const csv = '''
$reordered
Bench Press,4,8-10,1,Mon,Push Day,1,Pause at chest,,60kg,90
''';
      final result = parsePlanCsv(csv);
      expect(result.hasErrors, isFalse);
      expect(result.rows, hasLength(1));
      final row = result.rows.single;
      expect(row.exerciseName, 'Bench Press');
      expect(row.week, 1);
      expect(row.day, 'Mon');
      expect(row.sessionName, 'Push Day');
      expect(row.restSec, 90);
    });

    test('throws when a required column is missing entirely', () {
      const csv = '''
Week,Day,Session Name,Order,Sets,Reps
1,Mon,Push Day,1,4,8-10
''';
      expect(
        () => parsePlanCsv(csv),
        throwsA(
          isA<PlanImportFormatException>().having(
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
1,Mon,Push Day,1,,4,8-10,60kg,90,,
''';
      final result = parsePlanCsv(csv);
      expect(result.rows, isEmpty);
      expect(result.errors, hasLength(1));
      expect(result.errors.single.message, contains('Exercise Name'));
      expect(result.errors.single.rowNumber, 2);
    });

    test('reports malformed numeric fields as row errors', () {
      const csv = '''
$_header
one,Mon,Push Day,1,Bench Press,four,8-10,60kg,ninety,,
''';
      final result = parsePlanCsv(csv);
      expect(result.rows, isEmpty);
      expect(result.errors, hasLength(1));
      final message = result.errors.single.message;
      expect(message, contains('Week'));
      expect(message, contains('Sets'));
      expect(message, contains('Rest (sec)'));
    });

    test('empty Rest (sec) is not treated as malformed - it is optional', () {
      const csv = '''
$_header
1,Mon,Push Day,1,Bench Press,4,8-10,60kg,,,
''';
      final result = parsePlanCsv(csv);
      expect(result.hasErrors, isFalse);
      expect(result.rows.single.restSec, isNull);
    });

    test('throws for a file over the row limit', () {
      final rows = List.generate(
        maxImportRows + 1,
        (i) => '1,Mon,Push Day,$i,Bench Press,4,8-10,60kg,90,,',
      ).join('\n');
      final csv = '$_header\n$rows\n';
      expect(() => parsePlanCsv(csv), throwsA(isA<PlanImportFormatException>()));
    });

    test('throws for a completely empty file', () {
      expect(() => parsePlanCsv(''), throwsA(isA<PlanImportFormatException>()));
    });
  });

  group('matchExercisesAgainstLibrary', () {
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

    test('matches exact names case-insensitively', () {
      final rows = parsePlanCsv('''
$_header
1,Mon,Push Day,1,bench press,4,8-10,60kg,90,,
''').rows;
      final matched = matchExercisesAgainstLibrary(
        rows,
        [exercise('EX010', 'Bench Press')],
      );
      expect(matched.single.matchedExerciseId, 'EX010');
    });

    test('matches names differing only in punctuation/whitespace', () {
      final rows = parsePlanCsv('''
$_header
1,Mon,Push Day,1,Farmers Carry,4,8-10,60kg,90,,
''').rows;
      final matched = matchExercisesAgainstLibrary(
        rows,
        [exercise('EX020', "Farmer's  Carry")],
      );
      expect(matched.single.matchedExerciseId, 'EX020');
    });

    test('leaves unmatched rows with a null matchedExerciseId rather than guessing', () {
      final rows = parsePlanCsv('''
$_header
1,Mon,Push Day,1,Some Made Up Exercise,4,8-10,60kg,90,,
''').rows;
      final matched = matchExercisesAgainstLibrary(
        rows,
        [exercise('EX010', 'Bench Press')],
      );
      expect(matched.single.matchedExerciseId, isNull);
      expect(matched.single.exerciseName, 'Some Made Up Exercise');
    });
  });

  group('groupIntoSessions', () {
    test('groups rows by Week+Day+Session Name and sorts by order', () {
      final rows = parsePlanCsv('''
$_header
1,Mon,Push Day,2,Overhead Press,3,8-10,,,,
1,Mon,Push Day,1,Bench Press,4,8-10,,,,
1,Wed,Pull Day,1,Deadlift,3,5,,,,
''').rows;

      final groups = groupIntoSessions(rows);
      expect(groups, hasLength(2));
      expect(groups[0].sessionName, 'Push Day');
      expect(groups[0].rows.map((r) => r.exerciseName), ['Bench Press', 'Overhead Press']);
      expect(groups[1].sessionName, 'Pull Day');
    });
  });
}
