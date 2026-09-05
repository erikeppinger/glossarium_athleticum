import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/import/plan_spreadsheet_parser.dart';
import 'package:training_app/import/exercise_spreadsheet_parser.dart';
import 'package:training_app/import/xlsx_reader.dart';

void main() {
  group('readXlsxSheets against the real template files', () {
    test('training_plan_template.xlsx: Plan sheet parses with real rows', () {
      final bytes = File('templates/training_plan_template.xlsx').readAsBytesSync();
      final sheets = readXlsxSheets(bytes);
      expect(sheets.length, 2, reason: 'Plan + Instructions');
      expect(sheets[0].first, contains('Exercise Name'));
      expect(
        sheets[0].skip(1).map((r) => r[4]),
        contains('Bench Press'),
        reason: 'Exercise Name is column E (index 4)',
      );
    });

    test('parsePlanXlsx finds the Plan sheet, skipping Instructions', () {
      final bytes = File('templates/training_plan_template.xlsx').readAsBytesSync();
      final result = parsePlanXlsx(bytes);
      expect(result.hasErrors, isFalse);
      expect(result.rows, isNotEmpty);
      expect(result.rows.map((r) => r.exerciseName), contains('Bench Press'));
    });

    test('strongman_exercise_database.xlsx: Exercises sheet parses', () {
      final bytes = File('seed-data/strongman_exercise_database.xlsx').readAsBytesSync();
      final sheets = readXlsxSheets(bytes);
      expect(sheets.length, 2, reason: 'Exercises + Legend');
      expect(sheets[0].first, contains('Exercise Name'));
    });

    test('parseExerciseXlsx finds the Exercises sheet, skipping Legend', () {
      final bytes = File('seed-data/strongman_exercise_database.xlsx').readAsBytesSync();
      final result = parseExerciseXlsx(bytes);
      expect(result.hasErrors, isFalse);
      expect(result.rows, isNotEmpty);
      expect(
        result.rows.map((r) => r.name),
        contains('Band Pull-Apart'),
      );
    });
  });
}
