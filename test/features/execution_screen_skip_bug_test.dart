import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/features/execution/execution_screen.dart';
import 'package:training_app/features/notifications/reminder_coordinator.dart';

import 'fake_notification_service.dart';

// Reproduces a user-reported bug: after logging a set (starting the rest
// timer) and tapping "Skip", checking a set on a *different* exercise in
// the same session doesn't register.
void main() {
  testWidgets(
    'logging a set on exercise B works after skipping the rest timer from exercise A',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.exerciseDao.upsertExercise(
        ExercisesCompanion.insert(
          id: 'EX_A',
          name: 'Exercise A',
          category: 'Main Lift',
          movementPattern: 'Push',
          muscleGroups: 'Chest',
          equipment: 'Barbell',
          difficulty: 'Intermediate',
          measurementType: 'Weight x Reps',
        ),
      );
      await db.exerciseDao.upsertExercise(
        ExercisesCompanion.insert(
          id: 'EX_B',
          name: 'Exercise B',
          category: 'Main Lift',
          movementPattern: 'Pull',
          muscleGroups: 'Back',
          equipment: 'Barbell',
          difficulty: 'Intermediate',
          measurementType: 'Weight x Reps',
        ),
      );
      await db.planDao.createPlan(
        id: 'plan-1',
        name: 'Plan A',
        sessions: [
          const PlanSessionInput(
            weekNumber: 1,
            day: 'Mon',
            sessionName: 'Session',
            exercises: [
              PlanExerciseInput(
                order: 1,
                exerciseId: 'EX_A',
                exerciseName: 'Exercise A',
                sets: 1,
                reps: '8',
                weightIntensity: '60kg',
                restSec: 90,
              ),
              PlanExerciseInput(
                order: 2,
                exerciseId: 'EX_B',
                exerciseName: 'Exercise B',
                sets: 1,
                reps: '8',
                weightIntensity: '50kg',
                restSec: 90,
              ),
            ],
          ),
        ],
      );
      final details = await db.planDao.getPlanDetails('plan-1');
      final sessionId = details!.sessions.single.session.id;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            notificationServiceProvider.overrideWithValue(
              FakeNotificationService(),
            ),
          ],
          child: MaterialApp(home: ExecutionScreen(planSessionId: sessionId)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Exercise A'), findsOneWidget);
      expect(find.text('Exercise B'), findsOneWidget);

      // Log exercise A's only set - this starts the rest timer.
      await tester.tap(find.byIcon(Icons.check).first);
      await tester.pump();
      expect(find.textContaining('Rest:'), findsOneWidget);
      expect(
        find.byIcon(Icons.check),
        findsOneWidget,
        reason: 'only exercise B\'s check icon should remain',
      );

      // Skip the rest timer.
      await tester.tap(find.text('Skip'));
      await tester.pump();
      expect(
        find.textContaining('Rest:'),
        findsNothing,
        reason: 'the banner should disappear once skipped',
      );

      // Now try to log exercise B's set.
      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();

      expect(
        find.byIcon(Icons.check),
        findsNothing,
        reason: 'exercise B\'s set should now be logged too (no unchecked icons left)',
      );
      final loggedIconCount =
          find.byIcon(Icons.check_circle).evaluate().length +
          find.byIcon(Icons.emoji_events).evaluate().length;
      expect(
        loggedIconCount,
        2,
        reason: 'both sets should show a logged icon (check_circle or PR trophy)',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
