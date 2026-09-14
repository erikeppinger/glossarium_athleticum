import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/features/plans/edit_session_screen.dart';

// "Save as block" and "Group into superset" share one checkbox-selection UI
// on this screen (see _SelectionPurpose) - confirms selecting exercises for
// the block purpose shows the right helper text/button label, is gated on
// at least one selection (unlike grouping, which needs two), and actually
// creates a block with the selected exercises in their session order.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<int> seedSession() async {
    await db.planDao.createPlan(
      id: 'plan-1',
      name: 'Plan A',
      sessions: const [
        PlanSessionInput(
          weekNumber: 1,
          day: 'Mon',
          sessionName: 'Push Day',
          exercises: [
            PlanExerciseInput(
              order: 1,
              exerciseName: 'Bench Press',
              sets: 4,
              reps: '8-10',
            ),
            PlanExerciseInput(
              order: 2,
              exerciseName: 'Overhead Press',
              sets: 3,
              reps: '8-10',
            ),
          ],
        ),
      ],
    );
    return (await db.planDao.getPlanDetails(
      'plan-1',
    ))!.sessions.single.session.id;
  }

  testWidgets(
    'selecting one exercise and saving as a block creates it with that exercise',
    (tester) async {
      final sessionId = await seedSession();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: EditSessionScreen(sessionId: sessionId, planId: 'plan-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save as block'));
      await tester.pumpAndSettle();

      expect(
        find.text('Select the exercises to save as a reusable block.'),
        findsOneWidget,
      );
      // Unlike grouping (needs 2+), the confirm button is disabled with
      // nothing selected yet and enabled the moment one is.
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );

      await tester.tap(find.text('Bench Press'));
      await tester.pumpAndSettle();

      expect(find.text('Save as block (1)'), findsOneWidget);
      await tester.tap(find.text('Save as block (1)'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Warm-up');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Saved "Warm-up" as a block.'), findsOneWidget);
      final blocks = await db.blockDao.getAllBlocks();
      expect(blocks, hasLength(1));
      expect(blocks.single.name, 'Warm-up');
      final details = await db.blockDao.getBlockDetails(blocks.single.id);
      expect(details!.exercises.single.exerciseName, 'Bench Press');

      // Selection mode is exited afterward, back to the two entry buttons.
      expect(find.text('Save as block'), findsOneWidget);
      expect(find.text('Group into superset'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
