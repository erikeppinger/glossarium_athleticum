import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/features/execution/execution_screen.dart';
import 'package:training_app/features/notifications/reminder_coordinator.dart';
import 'package:training_app/features/today/today_screen.dart';

import 'fake_notification_service.dart';

// Requested directly (2026-09-16): the Today tab (the app's own default
// landing screen) had no direct way to start a session - only a random
// workout generator or switching to the Plans tab. "Start a session" reuses
// the same "skip straight to logging" trick as exercise_detail_screen.dart's
// own "Start now", just reached via the exercise picker first.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  testWidgets(
    '"Start a session" picks an exercise and jumps straight into a loggable session',
    (tester) async {
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

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            notificationServiceProvider.overrideWithValue(
              FakeNotificationService(),
            ),
          ],
          child: const MaterialApp(home: TodayScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start a session'));
      await tester.pumpAndSettle();

      expect(find.text('Choose an exercise'), findsOneWidget);
      await tester.tap(find.text('Pull-Up'));
      await tester.pumpAndSettle();

      expect(find.byType(ExecutionScreen), findsOneWidget);
      expect(find.text('Log session'), findsOneWidget);

      final plans = await db.planDao.getAllPlans();
      expect(plans, hasLength(1));
      expect(plans.single.name, contains('Pull-Up'));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
