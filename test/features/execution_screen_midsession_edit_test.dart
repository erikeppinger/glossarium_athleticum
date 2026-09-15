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

// Covers three related mid-session adjustments: adding/removing a set on the
// fly, skipping an exercise entirely, and adding an exercise from the library
// that wasn't part of the plan - none of these existed before; the set count
// was fixed once a session started, and there was no way in or out of a
// block short of finishing the whole session.
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
    await db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: 'EX_ROW',
        name: 'Cable Row',
        category: 'Main Lift',
        movementPattern: 'Pull',
        muscleGroups: 'Back',
        equipment: 'Cable',
        difficulty: 'Beginner',
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

  testWidgets('adding and removing a set changes how many rows can be logged', (
    tester,
  ) async {
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

    expect(find.byIcon(Icons.check), findsNWidgets(2));

    await tester.tap(find.text('Add set'));
    await tester.pump();
    expect(find.byIcon(Icons.check), findsNWidgets(3));

    // Remove one of the not-yet-logged rows via its own remove icon.
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pump();
    expect(find.byIcon(Icons.check), findsNWidgets(2));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });

  testWidgets('skipping an exercise hides its sets and finishing logs nothing for it', (
    tester,
  ) async {
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

    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pump();

    expect(find.text('Skipped for this session.'), findsOneWidget);
    expect(
      find.byIcon(Icons.check),
      findsNothing,
      reason: 'set rows should be hidden while skipped',
    );

    await tester.tap(find.text('Finish session'));
    await tester.pumpAndSettle();

    // Nothing was logged, so there's no note prompt and no session log at
    // all - the screen should have popped straight away.
    final logs = await db.sessionLogDao.getLogsForPlanSession(sessionId);
    expect(logs, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });

  testWidgets('adding an exercise from the library mid-session makes it loggable', (
    tester,
  ) async {
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

    expect(find.text('Cable Row'), findsNothing);

    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cable Row'));
    await tester.pumpAndSettle();

    expect(find.text('Cable Row'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });

  testWidgets(
    "an exercise added mid-session is logged for today but never saved to "
    "the plan's own prescription - a one-off addition shouldn't silently "
    'rewrite what every future occurrence of this session prescribes',
    (tester) async {
      // Two exercises' worth of set rows plus their headers don't all fit
      // in flutter_test's default 800x600 surface - a ListView (not
      // .builder) only mounts what's within the viewport, so Cable Row's
      // card (appended after Bench Press's) ends up off-screen and
      // un-hit-testable rather than just needing a scroll. See CLAUDE.md's
      // note on this same gotcha for a different screen.
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

      await tester.tap(find.text('Add exercise'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cable Row'));
      await tester.pumpAndSettle();

      expect(
        find.text('Added for this session only - not saved to the plan.'),
        findsOneWidget,
      );

      // Log only Cable Row's own 3 default sets - scoped to its own card so
      // this doesn't need to know or care how many of Bench Press's sets
      // exist, and a bounded loop (not an open-ended `while`) so a wrong
      // assumption here fails the test instead of hanging it.
      final cableRowCard = find.ancestor(
        of: find.text('Cable Row'),
        matching: find.byType(Card),
      );
      for (var i = 0; i < 3; i++) {
        await tester.tap(
          find
              .descendant(of: cableRowCard, matching: find.byIcon(Icons.check))
              .first,
        );
        await tester.pump();
      }
      await tester.tap(find.text('Finish session'));
      await tester.pumpAndSettle();
      // Bench Press's own 2 sets were never explicitly logged (only Cable
      // Row's were, above) but still have their plan-prefilled reps/weight
      // sitting in the fields - that's exactly what the "Unlogged sets"
      // dialog exists for. Log & finish auto-logs them too, which is fine:
      // this test only cares that Cable Row survives as a log without
      // becoming part of the plan, not that Bench Press stays unlogged.
      await tester.tap(find.text('Log & finish'));
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

      // Logged for today...
      final logs = await db.sessionLogDao.getLogsForPlanSession(sessionId);
      expect(logs, hasLength(1));
      final sets = await db.sessionLogDao.getLoggedSetsForSessionLog(
        logs.single.id,
      );
      expect(
        sets.where((s) => s.exerciseId == 'EX_ROW'),
        isNotEmpty,
        reason: 'the ad-hoc exercise should still be logged for this session',
      );

      // ...but the plan's own prescription is untouched - re-fetching it
      // shows only the exercise it always had.
      final details = await db.planDao.getPlanDetails('plan-1');
      expect(
        details!.sessions.single.exercises.map((e) => e.exerciseName),
        ['Bench Press'],
        reason:
            "the plan template must not gain Cable Row just because it was "
            'logged once during a session',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
