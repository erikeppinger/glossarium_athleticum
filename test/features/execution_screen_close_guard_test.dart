import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/features/execution/execution_screen.dart';
import 'package:training_app/features/execution/rest_timer_controller.dart';
import 'package:training_app/features/notifications/reminder_coordinator.dart';

import 'fake_notification_service.dart';

// Regression coverage for a real bug (2026-09-11): Windows' own window-close
// button (and Alt+F4) bypassed PopScope's "Leave without finishing?" guard
// entirely, silently discarding unsaved sets - a WM_CLOSE isn't a Navigator
// pop, so it never reached ExecutionScreen's own PopScope at all. Fixed by
// having ExecutionScreen register a guard closure on
// executionScreenCloseGuardProvider that main.dart's AppLifecycleListener
// (see its own doc comment - only Windows actually needs this; nothing
// native sends the request on Android) calls before agreeing to let the
// native side actually close the window.
//
// Only the registration/short-circuit half is covered here (the guard exists
// while mounted, and resolves immediately with nothing unsaved) - actually
// invoking the guard when something *is* unsaved (which shows the dialog and
// waits on a button tap) hangs indefinitely in `flutter test` on this
// machine when called directly rather than through a real widget gesture,
// matching an already-documented category of hang in this project
// (`add_exercise_to_plan_screen.dart`'s full flow, `plan_list_screen.dart` -
// see CLAUDE.md's Conventions) rather than anything specific to this
// feature. That dialog/choice-handling path itself is already covered by
// `_confirmDiscard`'s own tests via a real back-navigation gesture. The full
// end-to-end path - an actual native WM_CLOSE reaching this guard and the
// dialog correctly appearing and resolving - was verified live on Windows
// (2026-09-11): typed an unsaved value, clicked the window's own X button,
// confirmed "Keep training" kept the window open with the value intact, and
// a second attempt choosing "Leave" actually closed the app.
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

  testWidgets(
    'the guard is null until a session is mounted, then resolves true with nothing unsaved',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(
            FakeNotificationService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(executionScreenCloseGuardProvider),
        isNull,
        reason: 'no ExecutionScreen mounted yet - nothing to guard',
      );

      final sessionId = await seedSession(db);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: ExecutionScreen(planSessionId: sessionId)),
        ),
      );
      await tester.pumpAndSettle();

      final guard = container.read(executionScreenCloseGuardProvider);
      expect(
        guard,
        isNotNull,
        reason: 'ExecutionScreen should have registered its own guard',
      );
      expect(
        await guard!(),
        isTrue,
        reason: 'nothing logged or typed - safe to close immediately, no '
            'dialog needed',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
