import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/data/daos/session_log_dao.dart';
import 'package:training_app/features/history/history_screen.dart';

// Regression coverage: a bodyweight/band/Time-type exercise (e.g. Hip
// Circles) never logs a weight, so exerciseProgressionHistoryProvider always
// resolved empty for it - HistoryScreen used to show "No logged sets yet for
// this exercise" even when it had real, repeated reps-only history. It
// should now fall back to a reps-over-time view instead.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.exerciseDao.upsertExercise(
      ExercisesCompanion.insert(
        id: 'EX_HIP',
        name: 'Hip Circles',
        category: 'Warm-up',
        movementPattern: '',
        muscleGroups: 'Legs',
        equipment: 'None (Bodyweight)',
        difficulty: 'Beginner',
        measurementType: 'Time',
      ),
    );
  });

  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(
          home: HistoryScreen(exerciseId: 'EX_HIP', exerciseName: 'Hip Circles'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'shows a reps-over-time fallback instead of "No logged sets yet" once '
    'there is reps-only history',
    (tester) async {
      final sessionId = await db.planDao.addSession(
        planId: await db.planDao.createEmptyPlan(name: 'Plan A'),
        weekNumber: 1,
        day: 'Mon',
        sessionName: 'Warm-up',
      );
      await db.sessionLogDao.createSessionLog(
        id: 'log-1',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 8, 13),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_HIP', setNumber: 1, reps: 10),
          LoggedSetInput(exerciseId: 'EX_HIP', setNumber: 2, reps: 12),
        ],
      );
      await db.sessionLogDao.createSessionLog(
        id: 'log-2',
        planSessionId: sessionId,
        loggedAt: DateTime(2026, 8, 20),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_HIP', setNumber: 1, reps: 15),
        ],
      );

      await pump(tester);

      expect(find.text('No logged sets yet for this exercise.'), findsNothing);
      expect(find.text('Reps over time'), findsOneWidget);
      expect(find.text('22 reps (2 sets)'), findsOneWidget);
      expect(find.text('15 reps (1 set)'), findsOneWidget);
      // Weight-only machinery (1RM, auto-progression) must not appear for a
      // no-weight exercise - both are genuinely weight-based math.
      expect(find.textContaining('Estimated 1RM'), findsNothing);
      expect(find.text('Suggested next session'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'still shows "No logged sets yet" when there is no history at all',
    (tester) async {
      await pump(tester);

      expect(find.text('No logged sets yet for this exercise.'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
