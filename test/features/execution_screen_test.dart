import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/features/execution/execution_screen.dart';

void main() {
  testWidgets(
    'full log-a-session flow writes correct rows and flags a PR',
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
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: ExecutionScreen(planSessionId: sessionId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bench Press'), findsOneWidget);

      // The reps/weight fields are pre-filled from the plan's target
      // ("8" reps, "60kg" -> "60"); overwrite weight with a new PR value.
      final weightField = find.byType(TextField).at(1);
      await tester.enterText(weightField, '65');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();

      // Logging a set starts the rest timer banner.
      expect(find.textContaining('Rest:'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget); // PR badge

      await tester.tap(find.text('Finish session'));
      await tester.pumpAndSettle();

      final logs = await db.sessionLogDao.getLogsForPlanSession(sessionId);
      expect(logs, hasLength(1));

      final sets = await db.sessionLogDao.getLoggedSetsForSessionLog(
        logs.single.id,
      );
      expect(sets, hasLength(1));
      expect(sets.single.weight, 65.0);
      expect(sets.single.reps, 8);
      expect(sets.single.isPr, isTrue);

      final history = await db.sessionLogDao.getProgressionHistory('EX_BP');
      expect(history, hasLength(1));
      expect(history.single.weight, 65.0);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
