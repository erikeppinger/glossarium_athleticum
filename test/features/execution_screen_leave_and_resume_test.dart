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

// Reported live: leaving execution mode with unsaved sets only ever offered
// "Keep training" (stay) or "Discard" (leave, but lose everything not yet
// finished) - there was no way to actually leave and come back to where you
// left off, despite the dialog's own text promising exactly that ("the rest
// timer keeps running... so you can come back to this session without
// losing anything" - only the timer actually did). In-progress state
// (checked-off sets, mid-session additions, etc.) lived directly on
// _ExecutionScreenState, so any pop disposed it outright. It now lives in
// _InProgressSession, kept alive in a provider keyed by planSessionId, and
// a new explicit "Leave" choice in the discard dialog pops without
// disposing it.
void main() {
  // A logged set's row shows either a check_circle or (if it's a personal
  // record - which the very first ever logged weight for an exercise always
  // is) an emoji_events trophy instead - see execution_screen.dart's
  // `_SetRow`. Both icons share the same "Undo - edit this set again"
  // tooltip, so that's what identifies "this set is logged", independent of
  // which icon happens to be showing.
  Finder loggedSetIndicator() => find.byTooltip('Undo - edit this set again');

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

  testWidgets(
    'choosing "Leave" preserves a logged set - resuming shows it still logged',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sessionId = await seedSession(db);

      await tester.pumpWidget(wrap(db, sessionId));
      await tester.pumpAndSettle();
      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      expect(
        loggedSetIndicator(),
        findsOneWidget,
        reason: 'sanity check - the set is actually logged before leaving',
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Leave without finishing?'), findsOneWidget);

      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();
      expect(
        find.text('start'),
        findsOneWidget,
        reason: 'actually left - back on the screen underneath',
      );

      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();

      expect(
        loggedSetIndicator(),
        findsOneWidget,
        reason: 'the logged set survived the round trip, not just the timer',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );

  testWidgets(
    'choosing "Discard" still actually discards - resuming starts fresh',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sessionId = await seedSession(db);

      await tester.pumpWidget(wrap(db, sessionId));
      await tester.pumpAndSettle();
      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('start'), findsOneWidget);

      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();

      expect(
        loggedSetIndicator(),
        findsNothing,
        reason: 'Discard must still actually clear the in-progress state',
      );
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );

  testWidgets('choosing "Keep training" stays on the same screen, untouched', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final sessionId = await seedSession(db);

    await tester.pumpWidget(wrap(db, sessionId));
    await tester.pumpAndSettle();
    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep training'));
    await tester.pumpAndSettle();

    expect(
      find.text('Leave without finishing?'),
      findsNothing,
      reason: 'dialog dismissed',
    );
    expect(
      find.text('start'),
      findsNothing,
      reason: 'still on the execution screen, not the one underneath',
    );
    expect(loggedSetIndicator(), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });
}
