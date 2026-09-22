import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/features/exercise_library/library_management_screen.dart';
import 'package:training_app/features/settings/app_preferences.dart';

void main() {
  Future<AppDatabase> seedDb() async {
    SharedPreferences.setMockInitialValues({});
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
      expect(find.text('1 exercise • built-in'), findsOneWidget);

      // The seed group can't be renamed (there's no name to change), but it
      // can be deleted - see the group-scoped delete test below.
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
        findsOneWidget,
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

    final planCard = find
        .ancestor(
          of: find.text('Plan: Imported Plan'),
          matching: find.byType(Card),
        )
        .first;
    await tester.tap(find.descendant(of: planCard, matching: find.text('Delete')));
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

  testWidgets(
    'deleting the Standard library removes it and turns off reseeding',
    (tester) async {
      final db = await seedDb();
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: LibraryManagementScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final seedCard = find
          .ancestor(
            of: find.text('Standard library'),
            matching: find.byType(Card),
          )
          .first;
      await tester.tap(
        find.descendant(of: seedCard, matching: find.text('Delete')),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('turns that off, so it stays gone'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Standard library'), findsNothing);
      final all = await db.exerciseDao.getAllExercises();
      expect(all.map((e) => e.id), ['plan1']);
      expect(
        container.read(appPreferencesProvider).standardLibraryDismissed,
        isTrue,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );

  // Blocks share this same screen (a segmented toggle, not a separate icon -
  // requested directly so managing them doesn't add another corner to the
  // UI) despite being an unrelated kind of "named group" from the
  // source-string library groupings above.
  group('Blocks view', () {
    testWidgets(
      'creating a block from scratch opens it for editing, then lists it',
      (tester) async {
        final db = await seedDb();
        tester.view.physicalSize = const Size(1080, 3000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(wrap(db));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Blocks'));
        await tester.pumpAndSettle();
        expect(find.textContaining('No blocks yet.'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Warm-up');
        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        // Landed directly in BlockEditScreen for the new (empty) block.
        expect(find.text('This block has no exercises yet.'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        expect(find.text('Warm-up'), findsOneWidget);
        final blocks = await db.blockDao.getAllBlocks();
        expect(blocks.single.name, 'Warm-up');

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await db.close();
      },
    );

    testWidgets('deleting a block removes it from the list', (tester) async {
      final db = await seedDb();
      await db.blockDao.createBlock(name: 'Warm-up', exercises: const []);
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(db));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Blocks'));
      await tester.pumpAndSettle();
      expect(find.text('Warm-up'), findsOneWidget);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Warm-up'), findsNothing);
      expect(await db.blockDao.getAllBlocks(), isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    });
  });
}
