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

// Found on the emulator (2026-10-15): finishing after ticking off only some
// sets said the untouched, pre-filled ones "have numbers typed in", and the
// only way to finish was "Log & finish" - which saved them as if done. A
// partial workout must be able to finish with just what was ticked off.
void main() {
  testWidgets('a partial workout finishes without the untouched sets', (
    tester,
  ) async {
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
      sessions: const [
        PlanSessionInput(
          weekNumber: 1,
          day: 'Mon',
          sessionName: 'Lower Body',
          exercises: [
            PlanExerciseInput(
              order: 1,
              exerciseId: 'EX_SQ',
              exerciseName: 'Back Squat',
              sets: 3,
              reps: '8',
              weightIntensity: '100kg',
            ),
          ],
        ),
      ],
    );
    final sessionId = (await db.planDao.getPlanDetails('plan-1'))!
        .sessions
        .single
        .session
        .id;

    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    await tester.tap(find.byIcon(Icons.check).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish session'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining("2 sets still show the plan's numbers"),
      findsOneWidget,
    );
    await tester.tap(find.text('Finish without them'));
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

    final logs = await db.sessionLogDao.getLogsForPlanSession(sessionId);
    final sets = await db.sessionLogDao.getLoggedSetsForSessionLog(
      logs.single.id,
    );
    expect(sets, hasLength(1), reason: 'only the set that was ticked off');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });
}
