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

// Reported live: the floating rest-timer chip never appeared on Settings -
// or any other screen reached by pushing a route on top of HomeScreen - only
// on the four bottom-nav tabs. RestTimerOverlay used to live inside
// HomeScreen's own build, one Navigator layer below wherever a pushed screen
// sits, so anything pushed covered it along with everything else. It now
// floats above the whole MaterialApp (see main.dart's `builder`), with
// executionScreenVisibleProvider taking over the one thing z-order used to
// handle for free: staying hidden specifically while ExecutionScreen itself
// is on top.
void main() {
  Future<int> seedSession(AppDatabase db) async {
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
    return details!.sessions.single.session.id;
  }

  Widget appLike(Widget home) => MaterialApp(
    builder: (context, child) =>
        Stack(children: [?child, const RestTimerOverlay()]),
    home: home,
  );

  testWidgets(
    'the overlay shows on a screen pushed on top of the tabs - not just the '
    'tabs themselves',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sessionId = await seedSession(db);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            notificationServiceProvider.overrideWithValue(
              FakeNotificationService(),
            ),
          ],
          child: appLike(
            Navigator(
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ExecutionScreen(planSessionId: sessionId),
                        ),
                      ),
                      child: const Text('start'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();

      // On ExecutionScreen itself: only its own inline banner, not a
      // duplicate from the overlay.
      expect(find.textContaining('Rest:'), findsOneWidget);

      // Leave without finishing (rest timer keeps running) - back to the
      // "settings-like" pushed-on-top-of-tabs screen underneath.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();

      // This is the actual bug: previously the overlay never appeared here
      // at all, on any screen other than the four tabs.
      expect(
        find.textContaining('Rest:'),
        findsOneWidget,
        reason: 'the floating overlay should be visible here now',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
