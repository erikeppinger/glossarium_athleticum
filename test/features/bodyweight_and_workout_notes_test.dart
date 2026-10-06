import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/data/daos/session_log_dao.dart';
import 'package:training_app/features/execution/execution_screen.dart';
import 'package:training_app/features/history/workout_history_screen.dart';
import 'package:training_app/features/notifications/reminder_coordinator.dart';

import 'fake_notification_service.dart';

void main() {
  Future<void> addExercise(
    AppDatabase db,
    String id,
    String name, {
    required String category,
    required String equipment,
  }) {
    return db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: id,
        name: name,
        category: category,
        movementPattern: '',
        muscleGroups: 'Legs',
        equipment: equipment,
        difficulty: 'Beginner',
        measurementType: 'Weight x Reps',
      ),
    );
  }

  /// Leg Swings (bodyweight warm-up), Push-Ups (bodyweight strength) and
  /// Bench Press (barbell), one set each.
  Future<int> seedSession(AppDatabase db) async {
    await addExercise(db, 'EX_LS', 'Leg Swings',
        category: 'Warm-up', equipment: 'None (Bodyweight)');
    await addExercise(db, 'EX_PU', 'Push-Ups',
        category: 'Bodyweight', equipment: 'None (Bodyweight)');
    await addExercise(db, 'EX_BP', 'Bench Press',
        category: 'Main Lift', equipment: 'Barbell');
    await db.planDao.createPlan(
      id: 'plan-1',
      name: 'Plan A',
      sessions: [
        const PlanSessionInput(
          weekNumber: 1,
          day: 'Mon',
          sessionName: 'Mixed',
          exercises: [
            PlanExerciseInput(
              order: 1,
              exerciseId: 'EX_LS',
              exerciseName: 'Leg Swings',
              sets: 1,
              reps: '15',
            ),
            PlanExerciseInput(
              order: 2,
              exerciseId: 'EX_PU',
              exerciseName: 'Push-Ups',
              sets: 1,
              reps: '20',
            ),
            PlanExerciseInput(
              order: 3,
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
    'a bodyweight warm-up has no weight field; other bodyweight work gets an optional added-weight field',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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
          child: MaterialApp(home: ExecutionScreen(planSessionId: sessionId)),
        ),
      );
      await tester.pumpAndSettle();

      Finder inCard(String exercise, Finder finder) => find.descendant(
        of: find.ancestor(
          of: find.text(exercise),
          matching: find.byType(Card),
        ),
        matching: finder,
      );

      expect(inCard('Leg Swings', find.text('Weight (kg)')), findsNothing);
      expect(inCard('Leg Swings', find.text('Added (kg)')), findsNothing);
      expect(inCard('Leg Swings', find.text('RPE')), findsOneWidget);

      expect(inCard('Push-Ups', find.text('Added (kg)')), findsOneWidget);
      expect(inCard('Push-Ups', find.text('BW')), findsOneWidget);

      expect(inCard('Bench Press', find.text('Weight (kg)')), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );

  testWidgets('notes can be added and edited after a workout is finished', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final sessionId = await seedSession(db);
    await db.sessionLogDao.createSessionLog(
      id: 'log-1',
      planSessionId: sessionId,
      loggedAt: DateTime(2026, 10, 6),
      entries: const [
        LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
      ],
      skipped: const [
        SkippedExerciseInput(
          exerciseId: 'EX_LS',
          exerciseName: 'Leg Swings',
          prescribedSets: 1,
          prescribedReps: '15',
          reason: 'other',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: CompletedWorkoutScreen(logId: 'log-1')),
      ),
    );
    await tester.pumpAndSettle();

    // Session note.
    await tester.tap(find.text('Add a note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Gym was packed');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Gym was packed'), findsOneWidget);
    expect((await db.sessionLogDao.getCompletedWorkout('log-1'))!.log.notes,
        'Gym was packed');

    // Exercise note for the trainer.
    await tester.tap(find.byTooltip('Add a note for your trainer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Shoulder felt off');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Your note: Shoulder felt off'), findsOneWidget);
    final sets = await db.sessionLogDao.getLoggedSetsForSessionLog('log-1');
    expect(sets.single.notes, 'Shoulder felt off');

    // The skipped list uses a passive marker, not the skip button's icon.
    expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
    expect(find.byIcon(Icons.skip_next), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });
}
