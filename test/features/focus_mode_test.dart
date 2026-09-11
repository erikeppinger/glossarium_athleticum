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
import 'package:training_app/features/progress/progress_screen.dart';
import 'package:training_app/features/settings/app_preferences.dart';
import 'package:training_app/features/today/today_screen.dart';

import 'fake_notification_service.dart';

// Focus Mode's two sub-toggles (hide progress/PRs, hide streaks/weekly
// summary) are already covered at the preference level in
// app_preferences_test.dart - these cover the actual UI gates they drive.
void main() {
  testWidgets(
    'Progress tab shows the Focus Mode empty state instead of its real content',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            appPreferencesProvider.overrideWith(
              (ref) => AppPreferencesNotifier()
                ..state = const AppPreferences(
                  focusModeEnabled: true,
                  focusModeHideProgress: true,
                ),
            ),
          ],
          child: const MaterialApp(home: ProgressScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Focus mode is on'), findsOneWidget);
      expect(
        find.text('"A work of art is never finished, only abandoned."'),
        findsOneWidget,
      );
      expect(find.text('— Paul Valéry'), findsOneWidget);
      // The real content (period selector) must not be built at all.
      expect(find.text('Week'), findsNothing);
      expect(find.text('Month'), findsNothing);

      await tester.tap(find.text('Show progress again'));
      await tester.pumpAndSettle();

      expect(find.text('Focus mode is on'), findsNothing);
      expect(find.text('Week'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );

  testWidgets(
    'Progress tab renders normally when only the streaks sub-toggle is on',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            appPreferencesProvider.overrideWith(
              (ref) => AppPreferencesNotifier()
                ..state = const AppPreferences(
                  focusModeEnabled: true,
                  focusModeHideProgress: false,
                  focusModeHideStreaks: true,
                ),
            ),
          ],
          child: const MaterialApp(home: ProgressScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Focus mode is on'), findsNothing);
      expect(find.text('Week'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );

  testWidgets(
    'Today tab hides the streak and this-week cards when that sub-toggle is on',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            appPreferencesProvider.overrideWith(
              (ref) => AppPreferencesNotifier()
                ..state = const AppPreferences(
                  focusModeEnabled: true,
                  focusModeHideStreaks: true,
                ),
            ),
          ],
          child: const MaterialApp(home: TodayScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Unaffected content stays.
      expect(find.text('Nothing scheduled'), findsOneWidget);
      expect(find.text('Quick actions'), findsOneWidget);
      // Hidden content is gone.
      expect(find.text('This week'), findsNothing);
      expect(find.textContaining('streak'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );

  testWidgets(
    'a new PR shows the plain checkmark, not the trophy, while progress is hidden',
    (tester) async {
      // Same seeded-history shape as execution_screen_pr_history_test.dart -
      // two real prior weights, so isPersonalRecord actually has something
      // to compare against - just with Focus Mode's progress sub-toggle on.
      final db = AppDatabase.forTesting(NativeDatabase.memory());
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
      final sessionId = details!.sessions.single.session.id;

      await db.sessionLogDao.createSessionLog(
        id: 'log-1',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 1, 1),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 55),
        ],
      );
      await db.sessionLogDao.createSessionLog(
        id: 'log-2',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 1, 8),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 60),
        ],
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
                  focusModeEnabled: true,
                  focusModeHideProgress: true,
                ),
            ),
          ],
          child: MaterialApp(home: ExecutionScreen(planSessionId: sessionId)),
        ),
      );
      await tester.pumpAndSettle();

      final weightField = find.byType(TextField).at(1);
      await tester.enterText(weightField, '65');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byIcon(Icons.check_circle),
        findsOneWidget,
        reason: '65kg against prior [55, 60] is a real PR, but Focus Mode '
            'is hiding progress - it should still log fine, just without '
            'the celebration icon',
      );
      expect(find.byIcon(Icons.emoji_events), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
