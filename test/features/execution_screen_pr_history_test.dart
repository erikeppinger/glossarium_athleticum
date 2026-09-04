import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/data/daos/session_log_dao.dart';
import 'package:training_app/features/execution/execution_screen.dart';
import 'package:training_app/features/notifications/reminder_coordinator.dart';

import 'fake_notification_service.dart';

// Regression test for a real crash found on-device: `_logSet` reads prior
// weights via `SessionLogDao.getPriorWeights` (a real `List<double>` from
// the DB, not a `List<num>` literal like the pure-logic test in
// progression_test.dart uses) and passes it to `isPersonalRecord`. When that
// list has 2+ entries, `isPersonalRecord`'s old `.reduce()` call threw
// "type '(num, num) => num' is not a subtype of type '(double, double) =>
// double'" - and since the throw happened before `form.logged = true` was
// ever set, the tapped set got stuck on its pending spinner forever with no
// error shown anywhere in the UI. A fresh in-memory DB never reproduces this
// (there's nothing in `priorFromDb` to combine with), so this seeds two real
// prior logged weights before opening execution mode, matching what
// actually happened on-device after a couple of real workouts.
void main() {
  testWidgets(
    'logging a set against 2+ real prior weights does not get stuck pending',
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

      // Two prior real workouts, each logged at a different weight - this
      // is what makes getPriorWeights() return a 2+ element List<double>.
      await db.sessionLogDao.createSessionLog(
        id: 'log-1',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 1, 1),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 55),
        ],
      );
      await db.sessionLogDao.createSessionLog(
        id: 'log-2',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 1, 8),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            notificationServiceProvider.overrideWithValue(
              FakeNotificationService(),
            ),
          ],
          child: MaterialApp(
            home: ExecutionScreen(planSessionId: sessionId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final weightField = find.byType(TextField).at(1);
      await tester.enterText(weightField, '65');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();
      // The old bug threw before `form.logged` was set, so the check
      // button's replacement (a progress spinner) never resolved to the PR
      // trophy no matter how long you waited - pumpAndSettle would hang
      // forever on a spinning CircularProgressIndicator, so give the
      // pending async gap a moment on its own instead.
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byIcon(Icons.emoji_events),
        findsOneWidget,
        reason:
            '65kg against prior [55, 60] is a new PR - the trophy should '
            'show, not a stuck pending spinner',
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
