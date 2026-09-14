import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/features/exercise_library/exercise_detail_screen.dart';

// Reported live: sharing a single exercise meant leaving the detail screen
// for the library's export menu, then re-finding and checking that same
// exercise in "Select exercises to export" - several steps for the common
// "just send my buddy this one exercise" case. Confirms the detail screen's
// own share/export action opens the same four-option sheet directly, with
// no selection step in between.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<Exercise> seedExercise() async {
    await db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: 'EX_TEST',
        name: 'Test Exercise',
        category: 'Main Lift',
        movementPattern: 'Push',
        muscleGroups: 'Chest',
        equipment: 'Barbell',
        difficulty: 'Intermediate',
        measurementType: 'Weight x Reps',
      ),
    );
    return (await db.exerciseDao.getExerciseById('EX_TEST'))!;
  }

  testWidgets('the export/share action opens the export sheet directly', (
    tester,
  ) async {
    final exercise = await seedExercise();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: ExerciseDetailScreen(exercise: exercise)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Share (.json)'), findsNothing);

    await tester.tap(find.byIcon(Icons.ios_share));
    await tester.pumpAndSettle();

    expect(find.text('Share (.json)'), findsOneWidget);
    expect(find.text('Share encrypted (.tlibrary)'), findsOneWidget);
    expect(find.text('Save (.json)'), findsOneWidget);
    expect(find.text('Save encrypted (.tlibrary)'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
