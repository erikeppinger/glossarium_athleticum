import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/data/daos/session_log_dao.dart';
import 'package:training_app/features/progress/progress_screen.dart';

// Regression/feature coverage: the Progress tab's streak card should stay
// hidden with no logged history, then appear once there's a real streak -
// proving the UI is actually wired to computeCurrentStreak/getAllLoggedDays,
// not just that those are separately unit-tested.
void main() {
  testWidgets(
    'the streak card is hidden with no history, then shows once today is logged',
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

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: ProgressScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('streak'), findsNothing);

      final sessionId = await db.planDao.addSession(
        planId: await db.planDao.createEmptyPlan(name: 'Plan A'),
        weekNumber: 1,
        day: 'Mon',
        sessionName: 'Push Day',
      );
      await db.sessionLogDao.createSessionLog(
        id: 'log-1',
        planSessionId: sessionId,
        loggedAt: DateTime.now(),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
        ],
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: ProgressScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 day streak'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
