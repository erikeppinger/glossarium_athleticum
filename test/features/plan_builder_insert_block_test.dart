import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/data/daos/block_dao.dart';
import 'package:training_app/features/plans/plan_builder_screen.dart';

// Building a brand new plan is entirely in-memory until "Save plan", so
// "Insert block" here just appends the block's exercises into the draft -
// no fork, unlike the same action on an already-saved session
// (edit_session_screen.dart). Confirms the block's exercises land in the
// draft session and get saved as a real plan.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Widget wrap() => ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
    child: const MaterialApp(home: PlanBuilderScreen()),
  );

  testWidgets(
    'inserting a block adds its exercises to the session draft, saved on "Save plan"',
    (tester) async {
      await db.blockDao.createBlock(
        name: 'Warm-up',
        exercises: const [
          BlockExerciseInput(order: 1, exerciseName: 'Arm Circles', sets: 1, reps: '30s'),
        ],
      );

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'My Plan');

      await tester.tap(find.text('Add session'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose a day'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mon').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Session name'), 'Push Day');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Insert block'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Warm-up'));
      await tester.pumpAndSettle();

      expect(find.text('Arm Circles'), findsOneWidget);

      await tester.tap(find.text('Save plan'));
      await tester.pumpAndSettle();

      final plans = await db.planDao.getAllPlans();
      expect(plans, hasLength(1));
      final details = await db.planDao.getPlanDetails(plans.single.id);
      expect(
        details!.sessions.single.exercises.map((e) => e.exerciseName),
        ['Arm Circles'],
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    '"Insert block" offers "Create new block" so a block can be authored '
    'without having built a session with real exercises first',
    (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'My Plan');
      await tester.tap(find.text('Add session'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose a day'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mon').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Session name'), 'Push Day');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Insert block'));
      await tester.pumpAndSettle();

      expect(find.text('Create new block'), findsOneWidget);
      await tester.tap(find.text('Create new block'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'Cooldown');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Landed in BlockEditScreen for the freshly created, still-empty block.
      expect(find.text('This block has no exercises yet.'), findsOneWidget);
      final blocks = await db.blockDao.getAllBlocks();
      expect(blocks.map((b) => b.name), ['Cooldown']);

      // Popping back with nothing added leaves the in-memory draft untouched.
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.textContaining('Push Day'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
