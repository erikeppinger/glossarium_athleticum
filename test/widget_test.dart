import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/data/seed/exercise_seed_loader.dart';
import 'package:training_app/features/exercise_library/exercise_library_screen.dart';

void main() {
  testWidgets('seeded exercises show up in the exercise library screen', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await seedExerciseLibrary(db);

    // Test only the Exercise Library tab directly, rather than the full
    // HomeScreen (whose IndexedStack keeps the Plans/Calendar tabs - and
    // their Drift stream subscriptions - alive even while hidden). That
    // adds disposal-ordering complexity this smoke test doesn't need to
    // exercise; the DAO tests already cover the Plans/Calendar data layer.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ExerciseLibraryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Exercise Library'), findsOneWidget);
    // A row from the bundled seed CSV should be visible - proves the
    // asset -> Drift -> UI pipeline actually ran, not just that the screen
    // scaffolding rendered.
    expect(find.text('Band Pull-Apart'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });
}
