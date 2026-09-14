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

// Reported live: reaching the plate calculator mid-session meant leaving
// ExecutionScreen entirely for the Exercise Library's own toolbar icon,
// abandoning the in-progress session screen for something this quick.
// Confirms the app bar's new calculator icon opens the same calculator as a
// modal sheet, with the session screen still mounted underneath.
void main() {
  testWidgets(
    'the plate calculator icon opens the calculator as a bottom sheet',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());

      await db.exerciseDao.upsertExercise(
        ExercisesCompanion.insert(
          id: 'EX_BP',
          name: 'Bench Press',
          category: 'Main Lift',
          movementPattern: 'Push',
          muscleGroups: 'Chest',
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
            sessionName: 'Push Day',
            exercises: [
              PlanExerciseInput(
                order: 1,
                exerciseId: 'EX_BP',
                exerciseName: 'Bench Press',
                sets: 1,
                reps: '8',
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

      expect(find.text('Plate calculator'), findsNothing);

      await tester.tap(find.byIcon(Icons.calculate_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Plate calculator'), findsOneWidget);
      expect(find.text('Target weight (kg)'), findsOneWidget);
      // The session screen underneath is still mounted, not replaced.
      expect(find.text('Log session'), findsOneWidget);
      expect(find.text('Bench Press'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
