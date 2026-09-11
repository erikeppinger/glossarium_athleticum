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

// A 2-exercise superset (Bench Press: 4 sets, Overhead Press: 3 sets) built
// via PlanDao.setSupersetGroup, verified end-to-end in execution mode: both
// members render inside one card, round 4 (the uneven tail) only shows the
// longer exercise, logging a non-last member's set doesn't start the rest
// timer, and logging the round's last active member's set does.
void main() {
  Future<int> seedSupersetSession(AppDatabase db) async {
    for (final id in ['EX_BP', 'EX_OHP']) {
      await db.exerciseDao.upsertExercise(
        ExercisesCompanion.insert(
          id: id,
          name: id == 'EX_BP' ? 'Bench Press' : 'Overhead Press',
          category: 'Main Lift',
          movementPattern: 'Push',
          muscleGroups: 'Chest',
          equipment: 'Barbell',
          difficulty: 'Intermediate',
          measurementType: 'Weight x Reps',
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
          sessionName: 'Push Day',
          exercises: [
            PlanExerciseInput(
              order: 1,
              exerciseId: 'EX_BP',
              exerciseName: 'Bench Press',
              sets: 4,
              reps: '8',
              restSec: 90,
            ),
            PlanExerciseInput(
              order: 2,
              exerciseId: 'EX_OHP',
              exerciseName: 'Overhead Press',
              sets: 3,
              reps: '8',
              restSec: 60,
            ),
          ],
        ),
      ],
    );
    final details = (await db.planDao.getPlanDetails('plan-1'))!;
    final sessionId = details.sessions.single.session.id;
    final exercises = details.sessions.single.exercises;
    await db.planDao.setSupersetGroup(exercises.map((e) => e.id).toList());
    return sessionId;
  }

  Widget wrap(AppDatabase db, int sessionId) => ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      notificationServiceProvider.overrideWithValue(FakeNotificationService()),
    ],
    child: MaterialApp(home: ExecutionScreen(planSessionId: sessionId)),
  );

  testWidgets('renders both members in one superset card', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final sessionId = await seedSupersetSession(db);

    await tester.pumpWidget(wrap(db, sessionId));
    await tester.pumpAndSettle();

    expect(find.text('Superset'), findsOneWidget);
    expect(find.textContaining('Bench Press'), findsWidgets);
    expect(find.textContaining('Overhead Press'), findsWidgets);
    expect(find.text('Round 1'), findsOneWidget);
    expect(find.text('Round 4'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });

  testWidgets(
    'round 4 (past the shorter exercise\'s set count) only shows the '
    'longer exercise',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sessionId = await seedSupersetSession(db);

      await tester.pumpWidget(wrap(db, sessionId));
      await tester.pumpAndSettle();

      final round4 = find.byKey(const ValueKey('superset_round_3'));
      expect(round4, findsOneWidget);
      expect(
        find.descendant(
          of: round4,
          matching: find.textContaining('Bench Press'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: round4,
          matching: find.textContaining('Overhead Press'),
        ),
        findsNothing,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );

  testWidgets(
    'logging the non-last member\'s set in a round does not start the '
    'rest timer, but logging the last active member\'s does',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sessionId = await seedSupersetSession(db);

      await tester.pumpWidget(wrap(db, sessionId));
      await tester.pumpAndSettle();

      final round1 = find.byKey(const ValueKey('superset_round_0'));
      final checkButtons = find.descendant(
        of: round1,
        matching: find.byIcon(Icons.check),
      );
      expect(checkButtons, findsNWidgets(2));

      // Bench Press is order 1, so it's first in round 1 - not the last
      // active member - logging it should not start the rest timer.
      await tester.tap(checkButtons.first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Rest:'), findsNothing);

      // Overhead Press is order 2, last in round 1 - logging it should
      // start the rest timer, using its own 60s restSec.
      final remainingCheck = find.descendant(
        of: round1,
        matching: find.byIcon(Icons.check),
      );
      expect(remainingCheck, findsOneWidget);
      await tester.tap(remainingCheck);
      await tester.pumpAndSettle();
      expect(find.textContaining('Rest:'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
