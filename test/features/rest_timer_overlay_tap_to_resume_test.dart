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
import 'package:training_app/main.dart' show navigatorKey;

import 'fake_notification_service.dart';

// Reported live (2026-09-10): tapping the floating rest-timer chip or the
// "Session in progress" resume banner did nothing at all - no navigation, no
// visible error on the device. The cause: RestTimerOverlay lives inside
// MaterialApp.builder's own Stack as a *sibling* of the app's actual routed
// content, not a descendant of it (see main.dart) - so Navigator.of(context)
// from either widget's own context had no Navigator ancestor to find,
// crashing with "Null check operator used on a null value" (only visible in
// a full `flutter run` log; a release APK's on-device logcat just showed a
// terse, unhelpful "Another exception was thrown"). Fixed by routing through
// main.dart's global navigatorKey instead. This test mirrors the real
// MaterialApp.builder structure *with* that same navigatorKey attached -
// unlike rest_timer_overlay_visibility_test.dart's own harness, which never
// actually taps the overlay to navigate (only checks its visibility), so it
// couldn't have caught this.
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
    navigatorKey: navigatorKey,
    builder: (context, child) =>
        Stack(children: [?child, const RestTimerOverlay()]),
    home: home,
  );

  Widget settingsLikeScreen(int sessionId) => Navigator(
    onGenerateRoute: (settings) => MaterialPageRoute(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ExecutionScreen(planSessionId: sessionId),
              ),
            ),
            child: const Text('start'),
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'tapping the floating rest-timer chip actually navigates back into the '
    'session',
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
          child: appLike(settingsLikeScreen(sessionId)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();

      // Leave without finishing - rest timer keeps running, back on the
      // "settings-like" screen underneath where only the overlay chip shows.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();

      expect(find.text('Log session'), findsNothing);
      expect(find.textContaining('Rest:'), findsOneWidget);

      await tester.tap(find.textContaining('Rest:'));
      await tester.pumpAndSettle();

      expect(
        find.text('Log session'),
        findsOneWidget,
        reason: 'tapping the chip should have navigated back into '
            'ExecutionScreen',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
