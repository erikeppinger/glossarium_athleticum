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

// Edge cases around skipping/replacing, the hold timer and the weight field
// that the main feature tests don't walk through.
void main() {
  Future<int> seedSession(AppDatabase db) async {
    for (final (id, name, category, equipment, type) in [
      ('EX_PL', 'Plank', 'Core', 'None (Bodyweight)', 'Time'),
      ('EX_BP', 'Bench Press', 'Main Lift', 'Barbell', 'Weight x Reps'),
      ('EX_SQ', 'Bodyweight Squat', 'Warm-up', 'None (Bodyweight)',
          'Weight x Reps'),
      ('EX_ROW', 'Cable Row', 'Accessory', 'Cable Machine', 'Weight x Reps'),
    ]) {
      await db.exerciseDao.upsertExercise(
        ExercisesCompanion.insert(
          id: id,
          name: name,
          category: category,
          movementPattern: '',
          muscleGroups: 'Core',
          equipment: equipment,
          difficulty: 'Beginner',
          measurementType: type,
        ),
      );
    }
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
              exerciseId: 'EX_PL',
              exerciseName: 'Plank',
              sets: 1,
              reps: '1',
              weightIntensity: '45 sec',
            ),
            PlanExerciseInput(
              order: 2,
              exerciseId: 'EX_BP',
              exerciseName: 'Bench Press',
              sets: 1,
              reps: '8',
              weightIntensity: '60kg',
            ),
            PlanExerciseInput(
              order: 3,
              exerciseId: 'EX_SQ',
              exerciseName: 'Bodyweight Squat',
              sets: 1,
              reps: '10',
              weightIntensity: '10kg',
            ),
          ],
        ),
      ],
    );
    return (await db.planDao.getPlanDetails('plan-1'))!
        .sessions
        .single
        .session
        .id;
  }

  /// A home screen with a button that opens the session, so a test can
  /// leave and come back.
  Widget app(AppDatabase db, int sessionId) => ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      notificationServiceProvider.overrideWithValue(FakeNotificationService()),
    ],
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ExecutionScreen(planSessionId: sessionId),
              ),
            ),
            child: const Text('Open session'),
          ),
        ),
      ),
    ),
  );

  Future<AppDatabase> openSession(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final sessionId = await seedSession(db);
    await tester.pumpWidget(app(db, sessionId));
    await tester.tap(find.text('Open session'));
    await tester.pumpAndSettle();
    return db;
  }

  Future<void> close(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  }

  Finder inCard(String exercise, Finder finder) => find.descendant(
    of: find.ancestor(of: find.text(exercise), matching: find.byType(Card)),
    matching: finder,
  );

  Future<void> skipAndReplaceBench(WidgetTester tester) async {
    await tester.tap(inCard('Bench Press', find.byIcon(Icons.remove_circle_outline)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip & replace'));
    await tester.pumpAndSettle();
    // The picker's list is lazy - search rather than hunt below the fold.
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'cable',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cable Row'),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'un-skipping after a replace drops a substitute that was never logged',
    (tester) async {
      final db = await openSession(tester);
      await skipAndReplaceBench(tester);
      expect(find.text('Cable Row'), findsOneWidget);

      await tester.tap(inCard('Bench Press', find.byIcon(Icons.replay)));
      await tester.pumpAndSettle();

      expect(find.text('Cable Row'), findsNothing);
      await close(tester, db);
    },
  );

  testWidgets(
    'un-skipping keeps a logged substitute, as a plain addition',
    (tester) async {
      final db = await openSession(tester);
      await skipAndReplaceBench(tester);
      await tester.tap(inCard('Cable Row', find.byIcon(Icons.check)).first);
      await tester.pump();

      await tester.tap(inCard('Bench Press', find.byIcon(Icons.replay)));
      await tester.pumpAndSettle();

      expect(find.text('Cable Row'), findsOneWidget);
      expect(find.textContaining('Replacing Bench Press'), findsNothing);
      expect(
        find.text('Added for this session only - not saved to the plan.'),
        findsOneWidget,
      );
      await close(tester, db);
    },
  );

  testWidgets('logging a timed set while its timer runs keeps the time', (
    tester,
  ) async {
    final db = await openSession(tester);

    await tester.tap(find.byTooltip('Time this set'));
    await tester.pump();
    await tester.tap(inCard('Plank', find.byIcon(Icons.check)));
    await tester.pump();

    expect(find.byTooltip('Stop the timer'), findsNothing);
    expect(
      inCard('Plank', find.widgetWithText(TextField, '0')),
      findsOneWidget,
      reason: 'the elapsed time (0s under the test clock) replaces the 45',
    );
    await close(tester, db);
  });

  testWidgets('a running hold timer survives leaving and reopening', (
    tester,
  ) async {
    final db = await openSession(tester);
    await tester.tap(find.byTooltip('Time this set'));
    await tester.pump();

    // Back out via "Leave", then open the same session again.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    expect(find.text('Open session'), findsOneWidget);
    await tester.tap(find.text('Open session'));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(find.byTooltip('Stop the timer'), findsOneWidget);
    await close(tester, db);
  });

  testWidgets('skipping an exercise stops its running hold timer', (
    tester,
  ) async {
    final db = await openSession(tester);
    await tester.tap(find.byTooltip('Time this set'));
    await tester.pump();

    await tester.tap(inCard('Plank', find.byIcon(Icons.remove_circle_outline)));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Skip'));
    await tester.pumpAndSettle();
    await tester.tap(inCard('Plank', find.byIcon(Icons.replay)));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Stop the timer'), findsNothing);
    expect(find.byTooltip('Time this set'), findsOneWidget);
    await close(tester, db);
  });

  testWidgets('a timed exercise inside a superset gets seconds and a timer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final sessionId = await seedSession(db);
    final details = await db.planDao.getSessionDetails(sessionId);
    // Plank + Bench Press as one superset.
    await db.planDao.setSupersetGroup([
      details!.exercises[0].id,
      details.exercises[1].id,
    ]);
    await tester.pumpWidget(app(db, sessionId));
    await tester.tap(find.text('Open session'));
    await tester.pumpAndSettle();

    expect(find.text('Superset'), findsOneWidget);
    expect(find.text('Time (s)'), findsOneWidget);
    expect(find.byTooltip('Time this set'), findsOneWidget);

    await tester.tap(find.byTooltip('Time this set'));
    await tester.pump();
    expect(find.byTooltip('Stop the timer'), findsOneWidget);
    await close(tester, db);
  });

  testWidgets('a timed set autosaved before the app was killed comes back', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final sessionId = await seedSession(db);
    await db.sessionLogDao.saveDraft(
      planSessionId: sessionId,
      loggedAt: DateTime(2026, 10, 6),
      entries: const [
        LoggedSetInput(exerciseId: 'EX_PL', setNumber: 1, durationSec: 52),
      ],
    );
    await tester.pumpWidget(app(db, sessionId));
    await tester.tap(find.text('Open session'));
    await tester.pumpAndSettle();

    expect(inCard('Plank', find.widgetWithText(TextField, '52')), findsOneWidget);
    expect(
      inCard('Plank', find.byTooltip('Undo - edit this set again')),
      findsOneWidget,
      reason: 'restored as logged',
    );
    await close(tester, db);
  });

  testWidgets('a bodyweight warm-up prescribed with a load shows that load', (
    tester,
  ) async {
    final db = await openSession(tester);

    expect(inCard('Bodyweight Squat', find.text('Added (kg)')), findsOneWidget);
    expect(
      inCard('Bodyweight Squat', find.widgetWithText(TextField, '10')),
      findsNWidgets(2),
      reason: '10 reps and the prescribed 10kg, both visible',
    );
    await close(tester, db);
  });
}
