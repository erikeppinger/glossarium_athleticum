import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/features/execution/start_session_helper.dart';
import 'package:training_app/features/notifications/reminder_coordinator.dart';
import 'package:training_app/features/settings/app_preferences.dart';

import 'fake_notification_service.dart';

class _StartButton extends ConsumerWidget {
  final PlanSession session;
  final DateTime date;

  const _StartButton({required this.session, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () =>
              startSessionWithMoveToTodayPrompt(context, ref, session, date),
          child: const Text('start'),
        ),
      ),
    );
  }
}

// A session can now be scheduled on several dates (see PlanSessionDates), so
// starting one always names which specific occurrence is being started -
// there's no longer a "session with no date at all" case to silently assign
// today to, since a zero-date session has no Start affordance to tap in the
// first place (see plan_detail_screen.dart's per-date chips).
void main() {
  testWidgets(
    'starting a session scheduled for another day prompts to move it to '
    'today, and confirming moves that occurrence (not just any date)',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.planDao.createPlan(
        id: 'plan-1',
        name: 'Plan A',
        sessions: const [
          PlanSessionInput(
            weekNumber: 1,
            day: 'Mon',
            sessionName: 'Push Day',
            exercises: [],
          ),
        ],
      );
      final sessionId =
          (await db.planDao.getPlanDetails('plan-1'))!.sessions.single.session.id;
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowDateOnly = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
      );
      await db.planDao.addSessionDate(sessionId, tomorrowDateOnly);
      final farFuture = DateTime(tomorrow.year + 1, 1, 1);
      await db.planDao.addSessionDate(sessionId, farFuture);

      // Skip the plan-report and body-tracking opt-in prompts (both fire
      // the first time a session is started) so this test only exercises
      // the move-to-today fix, not an unrelated dialog.
      await db.planDao.setReportPreference(
        planId: 'plan-1',
        preference: 'declined',
      );

      final session = (await db.planDao.getPlanDetails('plan-1'))!.sessions.single.session;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            notificationServiceProvider.overrideWithValue(
              FakeNotificationService(),
            ),
            appPreferencesProvider.overrideWith(
              (ref) => AppPreferencesNotifier()
                ..state = const AppPreferences(
                  bodyTracking: BodyTracking.declined,
                ),
            ),
          ],
          child: MaterialApp(
            home: _StartButton(session: session, date: tomorrowDateOnly),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();

      expect(find.text('Move to today?'), findsOneWidget);
      await tester.tap(find.text('Move to today'));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dates = await db.planDao.getDatesForSession(sessionId);
      expect(
        dates,
        containsAll([today, farFuture]),
        reason: 'only the started occurrence should move to today',
      );
      expect(
        dates,
        isNot(contains(tomorrowDateOnly)),
        reason: 'the old date for the moved occurrence should be gone',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
