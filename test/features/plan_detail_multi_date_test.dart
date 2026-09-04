import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/features/notifications/reminder_coordinator.dart';
import 'package:training_app/features/plans/plan_detail_screen.dart';

import 'fake_notification_service.dart';

// Regression coverage for multi-date scheduling: a session used to have one
// "Assign date" button tied to a single assignedDate column - it now shows
// one chip per scheduled date, each independently removable without
// touching what's already been logged against the session.
void main() {
  Future<int> seedSession(AppDatabase db, {List<DateTime> dates = const []}) async {
    await db.planDao.createPlan(
      id: 'plan-1',
      name: 'Plan A',
      sessions: [
        PlanSessionInput(
          weekNumber: 1,
          day: 'Mon',
          sessionName: 'Push Day',
          assignedDates: dates,
          exercises: const [
            PlanExerciseInput(
              order: 1,
              exerciseName: 'Bench Press',
              sets: 3,
              reps: '8-10',
            ),
          ],
        ),
      ],
    );
    final details = await db.planDao.getPlanDetails('plan-1');
    return details!.sessions.single.session.id;
  }

  Widget wrap(AppDatabase db) => ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      notificationServiceProvider.overrideWithValue(FakeNotificationService()),
    ],
    child: const MaterialApp(home: PlanDetailScreen(planId: 'plan-1')),
  );

  testWidgets('a session with no dates shows "Not scheduled" and an Add date chip', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await seedSession(db);

    await tester.pumpWidget(wrap(db));
    await tester.pumpAndSettle();

    expect(find.text('Not scheduled'), findsOneWidget);
    expect(find.text('Add date'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });

  testWidgets('a session with several dates shows one chip per date', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await seedSession(
      db,
      dates: [DateTime(2026, 9, 1), DateTime(2026, 9, 8)],
    );

    await tester.pumpWidget(wrap(db));
    await tester.pumpAndSettle();

    expect(find.text('Not scheduled'), findsNothing);
    expect(find.text('Sep 1, 2026'), findsOneWidget);
    expect(find.text('Sep 8, 2026'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });

  testWidgets(
    'removing a date via its chip menu unschedules it without touching a log '
    'already recorded on that date',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final sessionId = await seedSession(
        db,
        dates: [DateTime(2026, 9, 1), DateTime(2026, 9, 8)],
      );
      await db.sessionLogDao.createSessionLog(
        id: 'log-1',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 9, 1),
        entries: const [],
      );

      await tester.pumpWidget(wrap(db));
      await tester.pumpAndSettle();

      // The chip's trailing "more" icon opens the move/remove bottom sheet.
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove this date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(
        await db.planDao.getDatesForSession(sessionId),
        [DateTime(2026, 9, 8)],
        reason: 'only the removed date should be gone',
      );
      expect(
        await db.sessionLogDao.getLogsForPlanSession(sessionId),
        hasLength(1),
        reason: 'removing a date must not delete what was logged on it',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
