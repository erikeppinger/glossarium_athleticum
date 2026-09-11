import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/features/exercise_library/create_exercise_screen.dart';

// The full picker-driven flow (category/difficulty/measurement-type dialogs)
// is deliberately not driven interactively here - add_exercise_to_plan_screen's
// equivalent flow proved unreliably testable via testWidgets (see CLAUDE.md).
// This covers what's cheaply and reliably verifiable: the Preview button's
// enabled state genuinely depends on the required fields, not just the name.
void main() {
  testWidgets(
    'Preview stays disabled until category/difficulty/measurement type are set',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: CreateExerciseScreen()),
        ),
      );
      await tester.pumpAndSettle();

      Widget findPreviewButton() =>
          tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Preview'));

      expect(findPreviewButton(), isA<FilledButton>());
      expect(
        (findPreviewButton() as FilledButton).onPressed,
        isNull,
        reason: 'no fields filled in yet',
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Name'),
        'Face Pull',
      );
      await tester.pump();

      expect(
        (findPreviewButton() as FilledButton).onPressed,
        isNull,
        reason: 'name alone is not enough - category/difficulty/measurement type are still unset',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );

  testWidgets(
    'tapping the "None (Bodyweight)" equipment quick pick fills the field',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: CreateExerciseScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ActionChip, 'None (Bodyweight)'));
      await tester.pump();

      final equipmentField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Equipment'),
      );
      expect(equipmentField.controller!.text, 'None (Bodyweight)');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );

  // Regression: editing a seed-library exercise used to mutate it in place -
  // harmless-looking, but the seed library is reseeded on every launch, so
  // the edit would silently be undone next time the app started. Editing a
  // non-custom exercise now forks a brand-new custom exercise instead,
  // pre-filling the name with "(edited)" (the "moniker" asked for directly)
  // so it's clear at a glance this is a derived copy, not the original.
  group('editing a built-in (non-custom) exercise', () {
    Future<Exercise> seedBuiltIn(AppDatabase db) async {
      final exercise = ExercisesCompanion.insert(
        id: 'SEED_1',
        name: 'Back Squat',
        category: 'Legs',
        movementPattern: 'Squat',
        muscleGroups: 'Quads, Glutes',
        equipment: 'Barbell',
        difficulty: 'Intermediate',
        measurementType: 'Weight x Reps',
        isCustom: Value(false),
      );
      await db.exerciseDao.upsertExercise(exercise);
      return (await db.exerciseDao.getExerciseById('SEED_1'))!;
    }

    testWidgets(
      'pre-fills the name with "(edited)" and shows a fork notice',
      (tester) async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        tester.view.physicalSize = const Size(1080, 3000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final seed = await seedBuiltIn(db);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [appDatabaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              home: CreateExerciseScreen(existing: seed),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Edit exercise (saves as a copy)'), findsOneWidget);
        expect(
          find.text('Back Squat (edited)'),
          findsOneWidget,
          reason: 'the name field should come pre-filled, not blank',
        );
        expect(
          find.textContaining('save as a new custom exercise'),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await db.close();
      },
    );

    testWidgets(
      'saving creates a new custom exercise and leaves the original untouched',
      (tester) async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        tester.view.physicalSize = const Size(1080, 3000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final seed = await seedBuiltIn(db);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [appDatabaseProvider.overrideWithValue(db)],
            child: MaterialApp(
              home: CreateExerciseScreen(existing: seed),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Every required field (name/category/difficulty/measurement type)
        // is already pre-filled from the existing exercise, so Preview ->
        // Save doesn't need to touch any of the picker dialogs at all.
        await tester.tap(find.widgetWithText(FilledButton, 'Preview'));
        await tester.pumpAndSettle();
        // "Save changes", not "Save exercise" - the button's label only
        // checks _isEditing (true here, same as any edit), not _willFork.
        await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
        await tester.pumpAndSettle();

        final all = await db.exerciseDao.getAllExercises();
        expect(
          all.length,
          2,
          reason: 'the fork should be a new row, not a rename of the seed',
        );

        final original = all.firstWhere((e) => e.id == 'SEED_1');
        expect(
          original.name,
          'Back Squat',
          reason: 'the original seed exercise must be unchanged',
        );
        expect(original.isCustom, false);

        final fork = all.firstWhere((e) => e.id != 'SEED_1');
        expect(fork.name, 'Back Squat (edited)');
        expect(fork.isCustom, true);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await db.close();
      },
    );
  });

  // Editing an *already*-custom exercise is unaffected by the forking
  // behaviour above - still a true in-place update, same id, no "(edited)"
  // suffix sprung on the name and no fork notice.
  testWidgets(
    'editing an already-custom exercise updates it in place, no fork',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final exercise = ExercisesCompanion.insert(
        id: 'CUSTOM_1',
        name: 'Garage Pull-Up Bar',
        category: 'Custom',
        movementPattern: '',
        muscleGroups: '',
        equipment: '',
        difficulty: 'Beginner',
        measurementType: 'Weight x Reps',
        isCustom: Value(true),
      );
      await db.exerciseDao.upsertExercise(exercise);
      final seed = (await db.exerciseDao.getExerciseById('CUSTOM_1'))!;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(home: CreateExerciseScreen(existing: seed)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit exercise'), findsOneWidget);
      expect(find.text('Edit exercise (saves as a copy)'), findsNothing);
      expect(
        find.text('Garage Pull-Up Bar'),
        findsOneWidget,
        reason: 'no "(edited)" suffix for an already-custom exercise',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Preview'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
      await tester.pumpAndSettle();

      final all = await db.exerciseDao.getAllExercises();
      expect(all.length, 1, reason: 'in-place edit - no new row');
      expect(all.single.id, 'CUSTOM_1');
      expect(all.single.name, 'Garage Pull-Up Bar');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
