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

void main() {
  testWidgets(
    'finishing with typed-but-unlogged sets warns and, once confirmed, '
    'saves them instead of silently dropping them',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());

      await db.exerciseDao.upsertExercise(
        ExercisesCompanion.insert(
          id: 'EX_SQ',
          name: 'Back Squat',
          category: 'Main Lift',
          movementPattern: 'Squat',
          muscleGroups: 'Legs',
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
            sessionName: 'Lower Body',
            exercises: [
              PlanExerciseInput(
                order: 1,
                exerciseId: 'EX_SQ',
                exerciseName: 'Back Squat',
                sets: 1,
                reps: '8',
                weightIntensity: '100kg',
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
          child: MaterialApp(
            home: ExecutionScreen(planSessionId: sessionId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Overwrite the pre-filled weight, same as a real user typing their
      // actual number - but never tap the set's own "Log set" check button,
      // the part that used to be required before "Finish session" would
      // keep anything at all.
      final weightField = find.byType(TextField).at(1);
      await tester.enterText(weightField, '105');
      await tester.pump();

      expect(find.byIcon(Icons.check), findsOneWidget); // still unlogged

      await tester.tap(find.text('Finish session'));
      await tester.pumpAndSettle();

      // The unlogged-set warning, not a silent no-op pop back to the caller.
      expect(find.text('Unlogged sets'), findsOneWidget);

      await tester.tap(find.text('Log as done'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm & finish'));
      await tester.pumpAndSettle();

      // Finishing now prompts for an optional note before writing the log.
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Skip'),
        ),
      );
      await tester.pumpAndSettle();

      final logs = await db.sessionLogDao.getLogsForPlanSession(sessionId);
      expect(logs, hasLength(1));

      final sets = await db.sessionLogDao.getLoggedSetsForSessionLog(
        logs.single.id,
      );
      expect(sets, hasLength(1));
      expect(sets.single.weight, 105.0);
      expect(sets.single.reps, 8);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
