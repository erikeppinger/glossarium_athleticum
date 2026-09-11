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

      // Mirrors main.dart's real structure - RestTimerOverlay floats above
      // the whole MaterialApp via `builder`, always mounted regardless of
      // whatever route is on top - since the bug this guards against is
      // specifically about the overlay outliving the session that started
      // its timer.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            notificationServiceProvider.overrideWithValue(
              FakeNotificationService(),
            ),
          ],
          child: MaterialApp(
            builder: (context, child) =>
                Stack(children: [?child, const RestTimerOverlay()]),
            home: Navigator(
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) =>
                    ExecutionScreen(planSessionId: sessionId),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();

      // The rest timer started - showing in the execution screen's own
      // inline banner. RestTimerOverlay is *not* also showing it a second
      // time even though it's always mounted here too, same as in the real
      // app - see executionScreenVisibleProvider, which the overlay checks
      // specifically to avoid duplicating ExecutionScreen's own banner now
      // that it floats above every screen instead of being hidden by
      // z-order the way it used to be.
      expect(find.textContaining('Rest:'), findsOneWidget);

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
