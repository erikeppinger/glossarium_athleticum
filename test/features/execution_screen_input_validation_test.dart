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

// Regression test: keyboardType only picks which on-screen keyboard shows -
// it does nothing to stop a physical/Bluetooth keyboard (or adb `input
// text`, as used here) from entering arbitrary text. Reported live: typing
// "test" into the Weight field was accepted with no feedback, then silently
// logged the set with a null weight once "Log set" was tapped. The Reps/
// Weight/RPE fields now carry real inputFormatters that reject the
// keystrokes themselves.
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
            ),
          ],
        ),
      ],
    );
    final details = await db.planDao.getPlanDetails('plan-1');
    return details!.sessions.single.session.id;
  }

  Future<void> pumpExecutionScreen(WidgetTester tester, AppDatabase db, int sessionId) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(FakeNotificationService()),
        ],
        child: MaterialApp(home: ExecutionScreen(planSessionId: sessionId)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the Weight field rejects non-numeric text entirely', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final sessionId = await seedSession(db);
    await pumpExecutionScreen(tester, db, sessionId);

    final weightField = find.byType(TextField).at(1);
    await tester.enterText(weightField, 'test');
    await tester.pump();

    expect(
      tester.widget<TextField>(weightField).controller!.text,
      isEmpty,
      reason: 'letters should never reach the controller, not just fail to parse later',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });

  testWidgets(
    'a bulk paste containing any invalid character is rejected as a whole',
    (tester) async {
      // decimalInputFormatters uses an anchored ^...$ pattern, so a whole
      // new value either fully matches or is fully rejected (reverting to
      // whatever was there before) - unlike digitsOnly below, it can't
      // "keep the good characters" out of one bulk replacement, only out of
      // real keystroke-by-keystroke typing (each keystroke is its own
      // whole-value check). tester.enterText simulates a single bulk
      // replacement, same as a paste.
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sessionId = await seedSession(db);
      await pumpExecutionScreen(tester, db, sessionId);

      final weightField = find.byType(TextField).at(1);
      await tester.enterText(weightField, '65.5kg');
      await tester.pump();

      expect(tester.widget<TextField>(weightField).controller!.text, isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );

  testWidgets('a valid decimal weight is entered untouched', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final sessionId = await seedSession(db);
    await pumpExecutionScreen(tester, db, sessionId);

    final weightField = find.byType(TextField).at(1);
    await tester.enterText(weightField, '102.5');
    await tester.pump();

    expect(tester.widget<TextField>(weightField).controller!.text, '102.5');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });

  testWidgets(
    'the Weight field caps decimal precision at two places',
    (tester) async {
      // Reported live (2026-09-15): pasting/autocorrect could produce
      // something like "90.89554545" - no realistic weight (barbell,
      // dumbbell, plate math, even competition lifting) needs more than
      // two decimal places, and an unbounded tail read as a data bug.
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sessionId = await seedSession(db);
      await pumpExecutionScreen(tester, db, sessionId);

      final weightField = find.byType(TextField).at(1);
      await tester.enterText(weightField, '90.895');
      await tester.pump();

      expect(
        tester.widget<TextField>(weightField).controller!.text,
        isEmpty,
        reason:
            'more than two decimal places is rejected as a whole, same as any other invalid bulk value',
      );

      await tester.enterText(weightField, '90.89');
      await tester.pump();
      expect(tester.widget<TextField>(weightField).controller!.text, '90.89');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );

  testWidgets('the Reps field rejects letters and a decimal point', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final sessionId = await seedSession(db);
    await pumpExecutionScreen(tester, db, sessionId);

    final repsField = find.byType(TextField).at(0);
    await tester.enterText(repsField, '8.5abc');
    await tester.pump();

    expect(
      tester.widget<TextField>(repsField).controller!.text,
      '85',
      reason: 'reps is whole numbers only - digits are kept, everything else dropped',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });
}
