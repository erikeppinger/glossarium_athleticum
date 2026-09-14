import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/features/exercise_library/exercise_detail_screen.dart';
import 'package:training_app/features/execution/execution_screen.dart';
import 'package:training_app/features/notifications/reminder_coordinator.dart';

import 'fake_notification_service.dart';

// Reported live: wanting to do a couple of sets of one exercise right now
// (e.g. pull-ups on a break) meant first building a whole plan, then a
// session, before ever reaching the logging screen. Confirms "Start now"
// skips all of that - one tap from the exercise's own page straight into a
// loggable session for just that exercise.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<Exercise> seedExercise() async {
    await db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: 'EX_PU',
        name: 'Pull-Up',
        category: 'Accessory',
        movementPattern: 'Pull',
        muscleGroups: 'Back',
        equipment: 'None (Bodyweight)',
        difficulty: 'Intermediate',
        measurementType: 'Weight x Reps',
      ),
    );
    return (await db.exerciseDao.getExerciseById('EX_PU'))!;
  }

  testWidgets('Start now jumps straight into a loggable session', (
    tester,
  ) async {
    final exercise = await seedExercise();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(
            FakeNotificationService(),
          ),
        ],
        child: MaterialApp(home: ExerciseDetailScreen(exercise: exercise)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start now'));
    await tester.pumpAndSettle();

    expect(find.byType(ExecutionScreen), findsOneWidget);
    expect(find.text('Log session'), findsOneWidget);
    expect(find.text('Pull-Up'), findsOneWidget);

    // A real (if throwaway) plan backs the session - never a dangling
    // planSessionId with nothing behind it.
    final plans = await db.planDao.getAllPlans();
    expect(plans, hasLength(1));
    expect(plans.single.name, contains('Pull-Up'));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
