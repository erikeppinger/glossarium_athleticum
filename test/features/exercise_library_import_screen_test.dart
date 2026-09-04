import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/features/exercise_library/exercise_library_import_screen.dart';

const _header =
    'Exercise Name,Category,Movement Pattern,Muscle Group(s),Equipment,'
    'Difficulty,Measurement Type,Description / Cues,Safety Notes,'
    'Video Reference';

void main() {
  Widget wrap(AppDatabase db, String csvContent) => ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
    child: MaterialApp(
      home: ExerciseLibraryImportScreen(csvContent: csvContent),
    ),
  );

  testWidgets(
    'importing a well-formed spreadsheet adds every row as a new custom exercise',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      const csv = '''
$_header
Bench Press,Main Lift,Push,Chest,Barbell,Intermediate,Weight x Reps,Pause at chest,,
Goblet Squat,Accessory,Squat,Legs,Kettlebell,Beginner,Weight x Reps,,Keep torso upright,
''';

      await tester.pumpWidget(wrap(db, csv));
      await tester.pumpAndSettle();

      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Goblet Squat'), findsOneWidget);
      expect(find.text('Import 2 exercise(s)'), findsOneWidget);

      await tester.tap(find.text('Import 2 exercise(s)'));
      await tester.pumpAndSettle();

      final saved = await db.exerciseDao.getCustomExercises();
      expect(saved, hasLength(2));
      expect(saved.every((e) => e.isCustom), isTrue);
      final benchPress = saved.firstWhere((e) => e.name == 'Bench Press');
      expect(benchPress.category, 'Main Lift');
      expect(benchPress.difficulty, 'Intermediate');
      expect(benchPress.description, 'Pause at chest');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );

  testWidgets(
    'a row sharing a name with an existing exercise is added as a separate entry, not merged',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.exerciseDao.upsertExercise(
        ExercisesCompanion.insert(
          id: 'EX_BP',
          name: 'Bench Press',
          category: 'Main Lift',
          movementPattern: 'Push',
          muscleGroups: 'Chest',
          equipment: 'Barbell',
          difficulty: 'Intermediate',
          measurementType: 'Weight x Reps',
        ),
      );
      const csv = '''
$_header
Bench Press,Main Lift,Push,Chest,Barbell,Advanced,Weight x Reps,,,
''';

      await tester.pumpWidget(wrap(db, csv));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('share a name with an exercise you already have'),
        findsOneWidget,
      );

      await tester.tap(find.text('Import 1 exercise(s)'));
      await tester.pumpAndSettle();

      final all = await db.exerciseDao.getAllExercises();
      expect(
        all.where((e) => e.name == 'Bench Press'),
        hasLength(2),
        reason: 'the original seed exercise must survive untouched, and the '
            'imported row must land as its own separate row',
      );
      expect(
        all.firstWhere((e) => e.name == 'Bench Press' && !e.isCustom).difficulty,
        'Intermediate',
        reason: 'the original must not be overwritten by the imported row',
      );
      expect(
        all.firstWhere((e) => e.name == 'Bench Press' && e.isCustom).difficulty,
        'Advanced',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
