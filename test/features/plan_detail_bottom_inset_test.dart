import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/features/plans/plan_detail_screen.dart';

// Regression test (seen on the emulator, 2026-10-07): the plan's list ran
// behind Android's navigation bar, so the last session card's buttons sat
// underneath it. The list's bottom padding must include the system inset.
void main() {
  testWidgets('the session list clears the navigation bar', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.planDao.createPlan(
      id: 'plan-1',
      name: 'Plan',
      sessions: const [
        PlanSessionInput(
          weekNumber: 1,
          day: 'Mon',
          sessionName: 'Push Day',
          exercises: [],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: PlanDetailScreen(planId: 'plan-1')),
      ),
    );
    await tester.pumpAndSettle();

    final list = tester.widget<ListView>(find.byType(ListView).first);
    expect(list.padding?.resolve(TextDirection.ltr).bottom, 16 + 48);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });
}
