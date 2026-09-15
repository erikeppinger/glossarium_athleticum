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

// Covers un-checking a mis-tapped/mis-typed set before "Finish session" -
// a real usability gap (no correction path) found in a post-ship review.
void main() {
  testWidgets(
    'tapping a logged set\'s icon reverts it to editable, and the corrected value is what gets saved',
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

      // Log a mistaken weight.
      final weightField = find.byType(TextField).at(1);
      await tester.enterText(weightField, '999');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();

      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      expect(
        tester.widget<TextField>(weightField).enabled,
        isFalse,
        reason: 'the field should be locked while logged',
      );

      // Undo it via the trophy/check icon.
      await tester.tap(find.byIcon(Icons.emoji_events));
      await tester.pump();

      expect(
        find.byIcon(Icons.emoji_events),
        findsNothing,
        reason: 'no logged icon should remain once undone',
      );
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(
        tester.widget<TextField>(weightField).enabled,
        isTrue,
        reason: 'the field should be editable again after undo',
      );

      // Correct it and re-log.
      await tester.enterText(weightField, '65');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();

      await tester.tap(find.text('Finish session'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm & finish'));
      await tester.pumpAndSettle();
      // Finishing now prompts for an optional note before writing the log -
      // scoped to the dialog since the rest-timer banner's own "Skip" button
      // is still on screen underneath it.
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Skip'),
        ),
      );
      await tester.pumpAndSettle();

      final logs = await db.sessionLogDao.getLogsForPlanSession(sessionId);
      final sets = await db.sessionLogDao.getLoggedSetsForSessionLog(
        logs.single.id,
      );
      expect(sets, hasLength(1));
      expect(
        sets.single.weight,
        65.0,
        reason: 'only the corrected value should have been saved, not 999',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
