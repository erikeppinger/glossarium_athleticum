import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/features/exercise_library/exercise_library_screen.dart';

void main() {
  testWidgets(
    'tapping the star toggles a favorite and the search field\'s star '
    'filters to favorites only',
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
      await db.exerciseDao.upsertExercise(
        ExercisesCompanion.insert(
          id: 'EX_SQ',
          name: 'Back Squat',
          category: 'Main Lift',
          movementPattern: 'Squat',
          muscleGroups: 'Legs',
          equipment: 'Barbell',
          difficulty: 'Intermediate',
          measurementType: 'Weight x Reps',
        ),
      );

      // Test the Exercise Library tab directly, matching test/widget_test.dart's
      // own precedent - no StreamProvider involved, safe with pumpAndSettle.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: ExerciseLibraryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // 2 exercise rows + the search field's own star toggle.
      expect(find.byIcon(Icons.star_border), findsNWidgets(3));
      expect(find.byIcon(Icons.star), findsNothing);

      await tester.tap(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Bench Press'),
          matching: find.byIcon(Icons.star_border),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star), findsOneWidget);
      // 1 remaining exercise row + the search field's toggle (unaffected by
      // favoriting a specific exercise).
      expect(find.byIcon(Icons.star_border), findsNWidgets(2));
      expect(
        (await db.exerciseDao.getExerciseById('EX_BP'))!.isFavorite,
        isTrue,
      );

      await tester.tap(find.byTooltip('Show favorites only'));
      await tester.pumpAndSettle();

      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Back Squat'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
