import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/features/exercise_library/library_management_screen.dart';

void main() {
  Future<AppDatabase> seedDb() async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: 'seed1',
        name: 'Back Squat',
        category: 'Main Lift',
        movementPattern: '',
        muscleGroups: '',
        equipment: 'Barbell',
        difficulty: 'Intermediate',
        measurementType: 'Weight x Reps',
      ),
    );
    await db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: 'plan1',
        name: 'Custom Row',
        category: 'Accessory',
        movementPattern: '',
        muscleGroups: '',
        equipment: 'Cable',
        difficulty: 'Beginner',
        measurementType: 'Weight x Reps',
        isCustom: const Value(true),
        sourcePlanName: const Value('Imported Plan'),
      ),
    );
    return db;
  }

  Widget wrap(AppDatabase db) => ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
    child: const MaterialApp(home: LibraryManagementScreen()),
  );

  testWidgets(
    'lists each library group with the right actions, and renames a group',
    (tester) async {
      final db = await seedDb();
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(db));
      await tester.pumpAndSettle();

      expect(find.text('Standard library'), findsOneWidget);
      expect(find.text('Plan: Imported Plan'), findsOneWidget);
      expect(
        find.text('1 exercise • built-in, not editable'),
        findsOneWidget,
      );

      // The seed group is protected - no Rename/Delete for it, only Export.
      final seedCard = find
          .ancestor(
            of: find.text('Standard library'),
            matching: find.byType(Card),
          )
          .first;
      expect(
        find.descendant(of: seedCard, matching: find.text('Rename')),
        findsNothing,
      );
      expect(
        find.descendant(of: seedCard, matching: find.text('Delete')),
        findsNothing,
      );

      // Rename the plan-sourced group.
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Renamed Plan');
      await tester.tap(find.widgetWithText(FilledButton, 'Rename'));
      await tester.pumpAndSettle();

      expect(find.text('Plan: Renamed Plan'), findsOneWidget);
      final renamed = await db.exerciseDao.getExerciseById('plan1');
      expect(renamed!.sourcePlanName, 'Renamed Plan');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );

  testWidgets('deleting a group removes its exercises, keeping history', (
    tester,
  ) async {
    final db = await seedDb();
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(db));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Plan: Imported Plan'), findsNothing);
    final all = await db.exerciseDao.getAllExercises();
    expect(all.map((e) => e.id), ['seed1']);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });
}
