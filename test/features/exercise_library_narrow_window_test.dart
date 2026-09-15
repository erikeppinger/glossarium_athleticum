import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/data/seed/exercise_seed_loader.dart';
import 'package:training_app/features/exercise_library/exercise_library_screen.dart';

void main() {
  testWidgets(
    'exercise library does not overflow at a small window height',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await seedExerciseLibrary(db);

      // Reproduces a real "BOTTOM OVERFLOWED BY 58 PIXELS" bug found live
      // on a narrow Linux desktop window (~420x380) - the search field
      // plus three filter rows were fixed-size siblings ahead of an
      // Expanded(ListView), which errors instead of shrinking once their
      // combined height exceeds what's available. Fixed by moving the
      // whole body onto one CustomScrollView. The live report's own
      // ~420x380 doesn't reproduce here - Linux's real fallback-font
      // metrics render the filter chip rows taller than flutter_test's
      // fixed test font does, so this needs a shorter height (250, not
      // 380) to trigger the same overflow deterministically regardless of
      // host font metrics. Confirmed this genuinely fails against the
      // pre-fix code (a real ~34px RenderFlex overflow, not a fluke) and
      // passes after it, at this exact height - the standard proving a
      // regression test would have caught it.
      tester.view.physicalSize = const Size(420, 250);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: ExerciseLibraryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
