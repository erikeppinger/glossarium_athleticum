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

  const _StartButton({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () =>
              startSessionWithMoveToTodayPrompt(context, ref, session),
          child: const Text('start'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets(
    'starting a never-scheduled session silently assigns it to today, so it '
    'shows up on the calendar once finished instead of staying invisible '
    'there forever',
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
      final details = await db.planDao.getPlanDetails('plan-1');
      final session = details!.sessions.single.session;
      expect(session.assignedDate, isNull);

      // Skip the plan-report and body-tracking opt-in prompts (both fire
      // the first time a session is started) so this test only exercises
      // the assign-today fix, not an unrelated dialog.
      await db.planDao.setReportPreference(
        planId: 'plan-1',
        preference: 'declined',
      );

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
          child: MaterialApp(home: _StartButton(session: session)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();

      final updated = await db.planDao.getPlanDetails('plan-1');
      final updatedSession = updated!.sessions.single.session;
      final now = DateTime.now();
      expect(
        updatedSession.assignedDate,
        DateTime(now.year, now.month, now.day),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
