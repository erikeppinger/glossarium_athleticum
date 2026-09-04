import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/features/execution/execution_screen.dart';
import 'package:training_app/features/execution/rest_timer_overlay.dart';
import 'package:training_app/features/notifications/reminder_coordinator.dart';

import 'fake_notification_service.dart';

void main() {
  testWidgets(
    'finishing a session stops its own still-running rest timer, rather than '
    'leaving it floating in the overlay until it times out on its own',
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
                weightIntensity: '60kg',
              ),
            ],
          ),
        ],
      );
      final details = await db.planDao.getPlanDetails('plan-1');
      final sessionId = details!.sessions.single.session.id;

      // Mirrors home_screen.dart's real structure - a Navigator stacked with
      // RestTimerOverlay as an always-mounted sibling - since the bug this
      // guards against is specifically about the overlay outliving the
      // session that started its timer.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            notificationServiceProvider.overrideWithValue(
              FakeNotificationService(),
            ),
          ],
          child: MaterialApp(
            home: Stack(
              children: [
                Navigator(
                  onGenerateRoute: (settings) => MaterialPageRoute(
                    builder: (context) =>
                        ExecutionScreen(planSessionId: sessionId),
                  ),
                ),
                const RestTimerOverlay(),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();

      // The rest timer started - showing in both the execution screen's own
      // inline banner and (since it's an always-mounted sibling here, unlike
      // execution_screen_test.dart) the RestTimerOverlay at the same time -
      // confirming the setup actually exercises the timer before finishing.
      expect(find.textContaining('Rest:'), findsNWidgets(2));

      await tester.tap(find.text('Finish session'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Skip'),
        ),
      );
      await tester.pumpAndSettle();

      // The execution screen is gone (session finished), but the overlay -
      // an always-mounted sibling - would still be showing a running timer
      // if finishing hadn't stopped it.
      expect(find.textContaining('Rest:'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
