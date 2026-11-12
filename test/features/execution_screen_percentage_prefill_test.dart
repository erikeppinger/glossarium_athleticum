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

// Found in the 2026-11 code review: a "70%" prescription showed its resolved
// load in the header but left the weight field empty, because the rows were
// created before the estimated 1RM had loaded. Ticking the set off as
// prescribed then saved it with no weight.
void main() {
  testWidgets('a percentage prescription pre-fills the weight', (tester) async {
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
          sessionName: 'Lower',
          exercises: [
            PlanExerciseInput(
              order: 1,
              exerciseId: 'EX_SQ',
              exerciseName: 'Back Squat',
              sets: 2,
              reps: '5',
              weightIntensity: '70%',
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
    // 100 kg x 5 -> estimated 1RM 116.7 kg -> 70% = 81.7 kg.
    await db.sessionLogDao.createSessionLog(
      id: 'earlier',
      planSessionId: sessionId,
      loggedAt: DateTime(2026, 1, 1),
      entries: const [
        LoggedSetInput(exerciseId: 'EX_SQ', setNumber: 1, reps: 5, weight: 100),
      ],
    );

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

    final weights = tester
        .widgetList<TextField>(find.byType(TextField))
        .where((f) => f.decoration?.labelText == 'Weight (kg)')
        .map((f) => f.controller!.text)
        .toList();
    expect(weights, ['81.7', '81.7']);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });
}
