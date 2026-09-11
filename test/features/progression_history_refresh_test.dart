import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/data/daos/session_log_dao.dart';
import 'package:training_app/features/progress/progress_providers.dart';

// Regression coverage: `exerciseProgressionHistoryProvider` (backing both
// the History screen's "Suggested next session" card and execution mode's
// "Best: ..." line) used to be two separate, never-invalidated
// FutureProviders - finishing a session wrote new logged sets to the DB, but
// neither screen noticed until a full app restart. This is the same
// one-shot-FutureProvider gotcha `invalidateProgressProviders` already
// exists to fix for the Progress tab; it just wasn't wired up here too.
void main() {
  testWidgets(
    'reflects a newly logged session once invalidateProgressProviders is '
    'called - stays stale before that, proving the fix actually matters',
    (tester) async {
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

      late WidgetRef capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                final history = ref
                    .watch(exerciseProgressionHistoryProvider('EX_BP'))
                    .valueOrNull;
                return Text('count:${history?.length ?? -1}');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('count:0'), findsOneWidget);

      await db.sessionLogDao.createSessionLog(
        id: 'log-1',
        planSessionId: sessionId,
        loggedAt: DateTime.now(),
        entries: const [
          LoggedSetInput(exerciseId: 'EX_BP', setNumber: 1, reps: 10, weight: 60),
        ],
      );
      await tester.pump();
      expect(
        find.text('count:0'),
        findsOneWidget,
        reason: 'without invalidation the provider stays cached at empty',
      );

      invalidateProgressProviders(capturedRef);
      await tester.pumpAndSettle();
      expect(find.text('count:1'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
