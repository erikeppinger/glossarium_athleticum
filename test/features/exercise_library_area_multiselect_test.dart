import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/features/exercise_library/exercise_library_screen.dart';

// Reported live: narrowing to one area (e.g. "Back"), then wanting to also
// see "Legs" exercises at the same time, meant either accepting one filter
// or re-tapping "All" to see everything again. Both the category and area
// filter rows are multi-select now - this covers the area row directly, and
// the toggle-to-deselect behaviour that came with it (tapping an already-
// selected chip again turns it off, no separate "All" tap needed).
void main() {
  Future<AppDatabase> seedDb() async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: 'EX_LEGS',
        name: 'Back Squat',
        category: 'Main Lift',
        movementPattern: 'Squat',
        muscleGroups: 'Quads',
        equipment: 'Barbell',
        difficulty: 'Intermediate',
        measurementType: 'Weight x Reps',
      ),
    );
    await db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: 'EX_BACK',
        name: 'Barbell Row',
        category: 'Main Lift',
        movementPattern: 'Pull',
        muscleGroups: 'Lats',
        equipment: 'Barbell',
        difficulty: 'Intermediate',
        measurementType: 'Weight x Reps',
      ),
    );
    await db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: 'EX_CHEST',
        name: 'Bench Press',
        category: 'Main Lift',
        movementPattern: 'Push',
        muscleGroups: 'Chest',
        equipment: 'Barbell',
        difficulty: 'Intermediate',
        measurementType: 'Weight x Reps',
      ),
    );
    return db;
  }

  testWidgets(
    'selecting a second area shows both, and re-tapping a selected chip '
    'deselects it',
    (tester) async {
      final db = await seedDb();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: ExerciseLibraryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Back Squat'), findsOneWidget);
      expect(find.text('Barbell Row'), findsOneWidget);
      expect(find.text('Bench Press'), findsOneWidget);

      // Select "Back" alone.
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Barbell Row'), findsOneWidget);
      expect(find.text('Back Squat'), findsNothing);
      expect(find.text('Bench Press'), findsNothing);

      // Also select "Legs" - both areas' exercises should show now.
      await tester.tap(find.text('Legs'));
      await tester.pumpAndSettle();
      expect(find.text('Barbell Row'), findsOneWidget);
      expect(find.text('Back Squat'), findsOneWidget);
      expect(find.text('Bench Press'), findsNothing);

      // Tapping "Back" again deselects just that one.
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Back Squat'), findsOneWidget);
      expect(find.text('Barbell Row'), findsNothing);
      expect(find.text('Bench Press'), findsNothing);

      // Tapping "Legs" again returns to no filter - everything shows.
      await tester.tap(find.text('Legs'));
      await tester.pumpAndSettle();
      expect(find.text('Back Squat'), findsOneWidget);
      expect(find.text('Barbell Row'), findsOneWidget);
      expect(find.text('Bench Press'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
