import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/features/history/workout_history_screen.dart';

// Regression test: deleting a workout from a period-scoped list (the
// Progress tab's activity-chip drill-down, or a custom range) previously
// left the just-deleted row showing until a full app restart, because
// _delete() invalidated workoutHistoryProvider (all-time) but not the
// separate workoutHistoryInRangeProvider family the scoped screen actually
// reads from.
void main() {
  testWidgets(
    'deleting a workout from a range-scoped list removes it from that same list',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.sessionLogDao.createAdHocActivity(
        id: 'activity-1',
        loggedAt: DateTime(2026, 9, 14),
        activityName: 'Walk',
        durationSec: 1800,
        distance: 3000,
      );

      final range = (start: DateTime(2026, 9, 8), end: DateTime(2026, 9, 15));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: WorkoutHistoryScreen(range: range, adHocOnly: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Walk'), findsOneWidget);

      await tester.tap(find.text('Walk'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Back on the scoped list - it must reflect the deletion immediately,
      // not just workoutHistoryProvider's own all-time list.
      expect(find.text('Walk'), findsNothing);
      expect(find.text('Nothing logged in this period.'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
