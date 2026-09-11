import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/features/plans/random_workout_screen.dart';

// Reported feature request: a way to get a quick random workout by asking
// for N exercises per bucket (warm-up/legs/upper body/core) rather than
// hand-picking every exercise via the plan builder.
void main() {
  Future<AppDatabase> seedDb() async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: 'warmup1',
        name: 'Arm Circles',
        category: 'Warm-up',
        movementPattern: '',
        muscleGroups: '',
        equipment: 'None (Bodyweight)',
        difficulty: 'Beginner',
        measurementType: 'Time',
      ),
    );
    await db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: 'leg1',
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

  Widget wrap(AppDatabase db) => ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
    child: const MaterialApp(home: RandomWorkoutScreen()),
  );

  testWidgets('Generate is disabled until at least one bucket has a count', (
    tester,
  ) async {
    final db = await seedDb();
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(db));
    await tester.pumpAndSettle();

    Widget generateButton() =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Generate'));
    expect(
      (generateButton() as FilledButton).onPressed,
      isNull,
      reason: 'every bucket starts at 0',
    );

    await tester.tap(find.byTooltip('More Warm-up'));
    await tester.pump();

    expect((generateButton() as FilledButton).onPressed, isNotNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });

  testWidgets(
    'generating fills the requested bucket and saving creates a real plan',
    (tester) async {
      final db = await seedDb();
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap(db));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('More Warm-up'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Generate'));
      await tester.pumpAndSettle();

      expect(find.text('• Arm Circles'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Use this workout'));
      await tester.pumpAndSettle();

      final plans = await db.planDao.getAllPlans();
      expect(plans, hasLength(1));
      expect(plans.single.name, startsWith('Random Workout'));
      final details = await db.planDao.getPlanDetails(plans.single.id);
      expect(details!.sessions.single.exercises.single.exerciseName, 'Arm Circles');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
