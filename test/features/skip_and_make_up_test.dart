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
import 'package:training_app/features/today/missed_exercises_card.dart';

import 'fake_notification_service.dart';

void main() {
  Future<void> addExercise(AppDatabase db, String id, String name) {
    return db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: id,
        name: name,
        category: 'Main Lift',
        movementPattern: 'Push',
        muscleGroups: 'Chest',
        equipment: 'Barbell',
        difficulty: 'Intermediate',
        measurementType: 'Weight x Reps',
      ),
    );
  }

  /// A one-exercise "Push Day" (Bench Press 2×8 @ 60kg) plus a few other
  /// library exercises to replace it with or make up.
  Future<int> seedSession(AppDatabase db) async {
    await addExercise(db, 'EX_BP', 'Bench Press');
    await addExercise(db, 'EX_ROW', 'Cable Row');
    await addExercise(db, 'EX_SQ', 'Back Squat');
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
              sets: 2,
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

  /// An earlier finished session that skipped Back Squat (3×5 @ 100kg).
  Future<void> seedSkippedSquat(
    AppDatabase db,
    int sessionId, {
    bool queued = false,
  }) {
    return db.sessionLogDao.createSessionLog(
      id: 'earlier',
      planSessionId: sessionId,
      loggedAt: DateTime(2026, 9, 1),
      entries: const [
        LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
      ],
      skipped: [
        SkippedExerciseInput(
          exerciseId: 'EX_SQ',
          exerciseName: 'Back Squat',
          prescribedSets: 3,
          prescribedReps: '5',
          prescribedWeightIntensity: '100kg',
          reason: 'machine_busy',
          queuedForNextSession: queued,
        ),
      ],
    );
  }

  Widget app(AppDatabase db, Widget home) => ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      notificationServiceProvider.overrideWithValue(FakeNotificationService()),
    ],
    child: MaterialApp(home: home),
  );

  void useTallViewport(WidgetTester tester) {
    // Several cards don't fit the default 800x600 surface, and a ListView
    // only mounts what's on screen (see CLAUDE.md).
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('skip with a reason and a substitute, then finish records both', (
    tester,
  ) async {
    useTallViewport(tester);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final sessionId = await seedSession(db);

    await tester.pumpWidget(app(db, ExecutionScreen(planSessionId: sessionId)));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Machine busy'));
    await tester.pump();
    await tester.tap(find.text('Skip & replace'));
    await tester.pumpAndSettle();

    expect(find.text('Replace Bench Press with'), findsOneWidget);
    await tester.tap(find.text('Cable Row'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Skipped for this session (Machine busy). Replaced by Cable Row below.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Replacing Bench Press for this session only - not saved to the plan.',
      ),
      findsOneWidget,
    );

    // The substitute carries over Bench Press's 2 sets; only its check
    // buttons are visible, since the skipped card hides its rows.
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byIcon(Icons.check).first);
      await tester.pump();
    }
    await tester.tap(find.text('Finish session'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm & finish'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('Skip')),
    );
    await tester.pumpAndSettle();

    final log = (await db.sessionLogDao.getLogsForPlanSession(sessionId)).single;
    final workout = await db.sessionLogDao.getCompletedWorkout(log.id);
    final skip = workout!.skipped.single;
    expect(skip.exerciseName, 'Bench Press');
    expect(skip.prescribedWeightIntensity, '60kg');
    expect(skip.reason, 'machine_busy');
    expect(skip.replacedByExerciseId, 'EX_ROW');
    expect(workout.exercises.single.substituteFor, 'Bench Press');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });

  testWidgets('a queued make-up is offered and added with its prescription', (
    tester,
  ) async {
    useTallViewport(tester);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final sessionId = await seedSession(db);
    await seedSkippedSquat(db, sessionId, queued: true);

    await tester.pumpWidget(app(db, ExecutionScreen(planSessionId: sessionId)));
    await tester.pumpAndSettle();

    expect(find.text('Make up from earlier'), findsOneWidget);
    await tester.tap(find.text('Add to this session'));
    await tester.pumpAndSettle();

    expect(find.text('Make up from earlier'), findsNothing);
    expect(find.textContaining('Make-up for '), findsOneWidget);
    expect(find.text('Target: 3 x 5 @ 100kg'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });

  testWidgets('a make-up that is not queued is not offered in a session', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final sessionId = await seedSession(db);
    await seedSkippedSquat(db, sessionId);

    await tester.pumpWidget(app(db, ExecutionScreen(planSessionId: sessionId)));
    await tester.pumpAndSettle();

    expect(find.text('Make up from earlier'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });

  testWidgets('the Today card queues, dismisses and undoes a make-up', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final sessionId = await seedSession(db);
    await seedSkippedSquat(db, sessionId);

    await tester.pumpWidget(
      app(db, const Scaffold(body: SingleChildScrollView(child: MissedExercisesCard()))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Missed recently'), findsOneWidget);
    expect(find.text('Back Squat'), findsOneWidget);
    expect(find.textContaining('Machine busy'), findsOneWidget);

    await tester.tap(find.text('Add to next session'));
    await tester.pumpAndSettle();
    expect(find.text('Will be offered in your next session'), findsOneWidget);
    final queued = await db.sessionLogDao.getPendingMakeUps();
    expect(queued.single.skip.queuedForNextSession, isTrue);

    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.text('Missed recently'), findsNothing);
    expect(await db.sessionLogDao.getPendingMakeUps(), isEmpty);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Back Squat'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });
}
