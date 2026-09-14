import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/features/exercise_library/exercise_library_screen.dart';

// Reported live: exporting an exercise was all-or-nothing (the whole
// library, or a whole named group in "Manage libraries") - no way to hand a
// buddy just the one exercise they actually want. This covers the new
// "Select exercises to export" flow: entering selection mode, toggling a
// checkbox, the app bar reflecting the count, cancelling clearing it, and
// the export sheet only offering to export once something's selected.
void main() {
  Future<AppDatabase> seedDb() async {
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
        muscleGroups: 'Quads',
        equipment: 'Barbell',
        difficulty: 'Intermediate',
        measurementType: 'Weight x Reps',
      ),
    );
    return db;
  }

  testWidgets(
    'selecting an exercise enables export; cancelling clears the selection',
    (tester) async {
      final db = await seedDb();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: ExerciseLibraryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Enter selection mode via the export menu.
      await tester.tap(find.byIcon(Icons.file_upload_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select exercises to export...'));
      await tester.pumpAndSettle();

      expect(find.text('Select exercises to export'), findsOneWidget);

      final exportButton = find.widgetWithIcon(
        IconButton,
        Icons.file_upload_outlined,
      );
      expect(tester.widget<IconButton>(exportButton).onPressed, isNull);

      // Tapping a tile toggles its checkbox while selecting, rather than
      // opening the exercise's detail screen.
      await tester.tap(find.text('Bench Press'));
      await tester.pumpAndSettle();

      expect(find.text('1 selected'), findsOneWidget);
      expect(tester.widget<IconButton>(exportButton).onPressed, isNotNull);
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).first).value,
        isTrue,
      );

      // The export sheet offers all four format/action combinations.
      await tester.tap(exportButton);
      await tester.pumpAndSettle();
      expect(find.text('Share (.json)'), findsOneWidget);
      expect(find.text('Share encrypted (.tlibrary)'), findsOneWidget);
      expect(find.text('Save (.json)'), findsOneWidget);
      expect(find.text('Save encrypted (.tlibrary)'), findsOneWidget);

      // Dismiss the sheet, then cancel selection mode entirely.
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Exercise Library'), findsOneWidget);
      expect(find.text('Select exercises to export'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
