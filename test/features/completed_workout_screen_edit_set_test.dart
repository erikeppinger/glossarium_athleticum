import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/data/daos/session_log_dao.dart';
import 'package:training_app/features/history/workout_history_screen.dart';

// Reported live (2026-09-16): once a session was finished, the only way to
// correct a mistyped value (e.g. the wrong rep count) was deleting the whole
// workout and redoing it. Tapping a set now opens an edit dialog in place.
void main() {
  testWidgets(
    'tapping a set edits it in place and the new value is shown',
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
      await db.sessionLogDao.createSessionLog(
        id: 'log-1',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 9, 16),
        entries: const [
          LoggedSetInput(
            exerciseId: 'EX_BP',
            setNumber: 1,
            reps: 8,
            weight: 60,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const MaterialApp(
            home: CompletedWorkoutScreen(logId: 'log-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('8 reps'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      final repsField = find.widgetWithText(TextField, 'Reps');
      await tester.enterText(repsField, '10');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.textContaining('10 reps'), findsOneWidget);
      expect(find.textContaining('8 reps'), findsNothing);

      // Persisted for real, not just reflected in the still-open screen's
      // own in-memory state.
      final sets = await db.sessionLogDao.getLoggedSetsForSessionLog('log-1');
      expect(sets.single.reps, 10);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
