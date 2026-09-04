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
}
