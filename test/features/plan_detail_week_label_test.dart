import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/features/plans/plan_detail_screen.dart';

// A single-week plan is a rotation (e.g. nine blocks done over however long
// it takes), so its session cards leave out "Week 1"; a plan with several
// weeks keeps the week in every label.
void main() {
  Future<void> pumpPlan(
    WidgetTester tester,
    AppDatabase db,
    List<PlanSessionInput> sessions,
  ) async {
    await db.planDao.createPlan(id: 'plan-1', name: 'Plan', sessions: sessions);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: PlanDetailScreen(planId: 'plan-1')),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tearDownApp(WidgetTester tester, AppDatabase db) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  }

  PlanSessionInput session(int week, String day, String name) =>
      PlanSessionInput(
        weekNumber: week,
        day: day,
        sessionName: name,
        exercises: const [],
      );

  testWidgets('a single-week plan leaves the week out', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await pumpPlan(tester, db, [
      session(1, 'Day 1', 'Block 1'),
      session(1, 'Day 2', 'Block 2'),
    ]);

    expect(find.text('Day 1 • Block 1'), findsOneWidget);
    expect(find.text('Day 2 • Block 2'), findsOneWidget);
    expect(find.textContaining('Week 1'), findsNothing);

    await tearDownApp(tester, db);
  });

  testWidgets('a plan with several weeks keeps them', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await pumpPlan(tester, db, [
      session(1, 'Mon', 'Push Day'),
      session(2, 'Mon', 'Push Day'),
    ]);

    expect(find.text('Week 1 • Mon • Push Day'), findsOneWidget);
    expect(find.text('Week 2 • Mon • Push Day'), findsOneWidget);

    await tearDownApp(tester, db);
  });
}
