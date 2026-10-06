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
  /// A plank (1 set, "45 sec") and a rowing interval (1 set, "250m").
  Future<int> seedSession(AppDatabase db) async {
    for (final (id, name, category, type) in [
      ('EX_PL', 'Plank', 'Core', 'Time'),
      ('EX_ROW', 'Rowing Intervals', 'Cardio', 'Distance'),
    ]) {
      await db.exerciseDao.upsertExercise(
        ExercisesCompanion.insert(
          id: id,
          name: name,
          category: category,
          movementPattern: '',
          muscleGroups: 'Core',
          equipment: 'None (Bodyweight)',
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
          sessionName: 'Core & Cardio',
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
              exerciseId: 'EX_ROW',
              exerciseName: 'Rowing Intervals',
              sets: 1,
              reps: '1',
              weightIntensity: '250m',
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

  Widget app(AppDatabase db, Widget home) => ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      notificationServiceProvider.overrideWithValue(FakeNotificationService()),
    ],
    child: MaterialApp(home: home),
  );

  Finder inCard(String exercise, Finder finder) => find.descendant(
    of: find.ancestor(of: find.text(exercise), matching: find.byType(Card)),
    matching: finder,
  );

  testWidgets(
    'a timed set counts seconds and a distance set metres, and both are saved as such',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sessionId = await seedSession(db);

      await tester.pumpWidget(app(db, ExecutionScreen(planSessionId: sessionId)));
      await tester.pumpAndSettle();

      expect(inCard('Plank', find.text('Reps')), findsNothing);
      expect(inCard('Plank', find.text('Time (s)')), findsOneWidget);
      expect(
        inCard('Plank', find.widgetWithText(TextField, '45')),
        findsOneWidget,
        reason: 'pre-filled from the "45 sec" prescription',
      );
      expect(inCard('Rowing Intervals', find.text('Distance (m)')), findsOneWidget);
      expect(
        inCard('Rowing Intervals', find.widgetWithText(TextField, '250')),
        findsOneWidget,
      );

      // The hold timer toggles between start and stop.
      await tester.tap(find.byTooltip('Time this set'));
      await tester.pump();
      expect(find.byTooltip('Stop the timer'), findsOneWidget);
      await tester.tap(find.byTooltip('Stop the timer'));
      await tester.pump();
      expect(find.byTooltip('Time this set'), findsOneWidget);

      // Type the hold time and log both sets.
      await tester.enterText(
        inCard('Plank', find.byType(TextField)).first,
        '50',
      );
      await tester.tap(inCard('Plank', find.byIcon(Icons.check)));
      await tester.pump();
      await tester.tap(inCard('Rowing Intervals', find.byIcon(Icons.check)));
      await tester.pump();

      await tester.tap(find.text('Finish session'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm & finish'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Skip'),
        ),
      );
      await tester.pumpAndSettle();

      final log = (await db.sessionLogDao.getLogsForPlanSession(sessionId))
          .single;
      final sets = await db.sessionLogDao.getLoggedSetsForSessionLog(log.id);
      final plank = sets.singleWhere((s) => s.exerciseId == 'EX_PL');
      expect(plank.durationSec, 50);
      expect(plank.reps, isNull);
      expect(plank.weight, isNull);
      final row = sets.singleWhere((s) => s.exerciseId == 'EX_ROW');
      expect(row.distance, 250);
      expect(row.reps, isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );

  testWidgets('a finished timed set shows and edits as seconds', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final sessionId = await seedSession(db);
    await db.sessionLogDao.createSessionLog(
      id: 'log-1',
      planSessionId: sessionId,
      loggedAt: DateTime(2026, 10, 6),
      entries: const [
        LoggedSetInput(exerciseId: 'EX_PL', setNumber: 1, durationSec: 45),
      ],
    );

    await tester.pumpWidget(
      app(db, const CompletedWorkoutScreen(logId: 'log-1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('45s'), findsOneWidget);

    await tester.tap(find.text('45s'));
    await tester.pumpAndSettle();
    expect(find.text('Time (s)'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, '45'), '55');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('55s'), findsOneWidget);
    final set = (await db.sessionLogDao.getLoggedSetsForSessionLog('log-1'))
        .single;
    expect(set.durationSec, 55);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });
}
