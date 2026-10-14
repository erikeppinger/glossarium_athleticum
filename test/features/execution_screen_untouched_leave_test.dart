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

// A workout opens with its set rows pre-filled from the plan (here 8 reps at
// 60kg). Those pre-filled values used to count as "unsaved", so opening a
// workout and backing out untouched still asked "Leave without finishing?".
// Only a changed value or a logged set should.
void main() {
  Future<int> seedSession(AppDatabase db) async {
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
    return details!.sessions.single.session.id;
  }

  Widget wrap(AppDatabase db, int sessionId) => ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      notificationServiceProvider.overrideWithValue(FakeNotificationService()),
    ],
    child: MaterialApp(
      home: Navigator(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ExecutionScreen(planSessionId: sessionId),
                  ),
                ),
                child: const Text('start'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> openWorkout(WidgetTester tester, AppDatabase db) async {
    final sessionId = await seedSession(db);
    await tester.pumpWidget(wrap(db, sessionId));
    await tester.pumpAndSettle();
    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();
  }

  Future<void> tearDownApp(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  }

  testWidgets('backing out of an untouched workout leaves without asking', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await openWorkout(tester, db);
    expect(
      find.widgetWithText(TextField, '8'),
      findsOneWidget,
      reason: 'sanity check - the reps field is pre-filled from the plan',
    );

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Leave without finishing?'), findsNothing);
    expect(find.text('start'), findsOneWidget);

    await tearDownApp(tester, db);
  });

  testWidgets('a changed value still asks before leaving', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await openWorkout(tester, db);

    await tester.enterText(find.widgetWithText(TextField, '8'), '10');
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Leave without finishing?'), findsOneWidget);

    await tester.tap(find.text('Keep training'));
    await tester.pumpAndSettle();
    await tearDownApp(tester, db);
  });
}
