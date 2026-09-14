import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/data/daos/block_dao.dart';
import 'package:training_app/features/plans/block_edit_screen.dart';

// Unlike edit_session_screen.dart, editing a block never forks - it has no
// logged history of its own to protect, only the independent stamped copies
// already inserted elsewhere do (see block_dao_test.dart). Confirms rename,
// edit, reorder, and remove all mutate the same block in place.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<String> seedBlock() {
    return db.blockDao.createBlock(
      name: 'Warm-up',
      exercises: const [
        BlockExerciseInput(
          order: 1,
          exerciseName: 'Band Pull-Apart',
          sets: 2,
          reps: '15',
        ),
        BlockExerciseInput(
          order: 2,
          exerciseName: 'Arm Circles',
          sets: 1,
          reps: '30s',
        ),
      ],
    );
  }

  Future<void> pump(WidgetTester tester, String blockId) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: BlockEditScreen(blockId: blockId)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renaming the block updates the app bar title', (tester) async {
    final blockId = await seedBlock();
    await pump(tester, blockId);

    expect(find.text('Warm-up'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Warm-up (updated)');
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    expect(find.text('Warm-up (updated)'), findsOneWidget);
    expect((await db.blockDao.getBlockDetails(blockId))!.block.name, 'Warm-up (updated)');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'moving the second exercise up swaps its order with the first',
    (tester) async {
      final blockId = await seedBlock();
      await pump(tester, blockId);

      final upButtons = find.widgetWithIcon(IconButton, Icons.arrow_upward);
      // First row's "up" is disabled; tap the second row's.
      await tester.tap(upButtons.at(1));
      await tester.pumpAndSettle();

      final details = await db.blockDao.getBlockDetails(blockId);
      expect(details!.exercises.map((e) => e.exerciseName), [
        'Arm Circles',
        'Band Pull-Apart',
      ]);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('editing an exercise updates its sets/reps in place', (
    tester,
  ) async {
    final blockId = await seedBlock();
    await pump(tester, blockId);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.edit).first);
    await tester.pumpAndSettle();

    final setsField = find.byType(TextField).first;
    await tester.enterText(setsField, '3');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final details = await db.blockDao.getBlockDetails(blockId);
    expect(details!.exercises.first.sets, 3);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('removing an exercise confirms, then deletes just that one', (
    tester,
  ) async {
    final blockId = await seedBlock();
    await pump(tester, blockId);

    await tester
        .tap(find.widgetWithIcon(IconButton, Icons.delete_outline).first);
    await tester.pumpAndSettle();
    expect(find.text('Remove "Band Pull-Apart"?'), findsOneWidget);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    final details = await db.blockDao.getBlockDetails(blockId);
    expect(details!.exercises.map((e) => e.exerciseName), ['Arm Circles']);
    expect(details.exercises.single.order, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
