import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/data/daos/session_log_dao.dart';
import 'package:training_app/features/history/history_screen.dart';
import 'package:training_app/features/settings/app_preferences.dart';

// Regression coverage: history_screen.dart used to hardcode
// ExperienceLevel.intermediate for everyone (see its old _defaultLevel
// constant); the suggested next set should now change with the user's own
// fitness-level preference.
void main() {
  Future<AppDatabase> seedDb() async {
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
    final sessionId = await db.planDao.addSession(
      planId: await db.planDao.createEmptyPlan(name: 'Plan A'),
      weekNumber: 1,
      day: 'Mon',
      sessionName: 'Push Day',
    );
    // Hit the 8-rep target, so suggestNextSet's "try <last + increment>"
    // branch fires - the branch whose suggested weight actually depends on
    // ExperienceLevel (see lib/logic/progression.dart's increments: 5.0 /
    // 2.5 / 1.25 kg for beginner / intermediate / advanced).
    await db.sessionLogDao.createSessionLog(
      id: 'log-1',
      planSessionId: sessionId,
      loggedAt: DateTime.now().subtract(const Duration(days: 1)),
      entries: const [
        LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 8, weight: 100),
      ],
    );
    return db;
  }

  Future<void> pumpWithLevel(
    WidgetTester tester,
    AppDatabase db,
    ExperienceLevel level,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          appPreferencesProvider.overrideWith(
            (ref) => AppPreferencesNotifier()
              ..state = AppPreferences(experienceLevel: level),
          ),
        ],
        child: const MaterialApp(
          home: HistoryScreen(exerciseId: 'EX_BP', exerciseName: 'Bench Press'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a beginner is suggested a bigger jump than an intermediate lifter',
    (tester) async {
      final db = await seedDb();

      // beginner: +5.0kg increment (lib/logic/progression.dart).
      await pumpWithLevel(tester, db, ExperienceLevel.beginner);
      expect(find.textContaining('105kg'), findsOneWidget);

      // Unmount before repumping with a different ProviderScope - otherwise
      // Flutter's element diffing can reuse the existing ProviderScope
      // (same widget position/type) instead of creating a fresh
      // ProviderContainer, so the new override for the second level below
      // wouldn't actually take effect.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      // intermediate: +2.5kg increment - a different, smaller suggestion for
      // the exact same logged history, proving the preference (not just the
      // history) drives the number.
      await pumpWithLevel(tester, db, ExperienceLevel.intermediate);
      expect(find.textContaining('102.5kg'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
