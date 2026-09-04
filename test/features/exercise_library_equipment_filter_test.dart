import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/features/exercise_library/exercise_library_screen.dart';
import 'package:training_app/features/settings/app_preferences.dart';

// Regression/feature coverage for the "My equipment" filter: it should stay
// invisible until equipment is actually configured, and once toggled on it
// should hide an exercise the user can't do while keeping one they can.
void main() {
  Future<AppDatabase> seedDb() async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: 'EX_BARBELL',
        name: 'Barbell Row',
        category: 'Main Lift',
        movementPattern: 'Pull',
        muscleGroups: 'Back',
        equipment: 'Barbell',
        difficulty: 'Intermediate',
        measurementType: 'Weight x Reps',
      ),
    );
    await db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: 'EX_KETTLEBELL',
        name: 'Kettlebell Swing',
        category: 'Conditioning',
        movementPattern: 'Hinge',
        muscleGroups: 'Hips',
        equipment: 'Kettlebell',
        difficulty: 'Intermediate',
        measurementType: 'Weight x Reps',
      ),
    );
    return db;
  }

  testWidgets(
    'the filter is hidden until equipment is configured, then hides what '
    'cannot be done with it',
    (tester) async {
      final db = await seedDb();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: ExerciseLibraryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Barbell Row'), findsOneWidget);
      expect(find.text('Kettlebell Swing'), findsOneWidget);
      expect(
        find.text('My equipment'),
        findsNothing,
        reason: 'nothing configured yet - the filter chip should not appear',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            appPreferencesProvider.overrideWith(
              (ref) => AppPreferencesNotifier()
                ..state = const AppPreferences(availableEquipment: {'Barbell'}),
            ),
          ],
          child: const MaterialApp(home: ExerciseLibraryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My equipment'), findsOneWidget);
      await tester.tap(find.text('My equipment'));
      await tester.pumpAndSettle();

      expect(find.text('Barbell Row'), findsOneWidget);
      expect(
        find.text('Kettlebell Swing'),
        findsNothing,
        reason: 'not doable with only a Barbell owned',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
