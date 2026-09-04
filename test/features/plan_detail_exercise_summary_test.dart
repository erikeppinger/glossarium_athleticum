import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/data/daos/plan_dao.dart';
import 'package:training_app/features/plans/plan_detail_screen.dart';

// Regression test: a session card's subtitle used to join every exercise
// name in the session with ", " and no line limit - fine for a handful of
// exercises, but a plan with many (e.g. a spreadsheet import with one row
// per exercise) turned the subtitle into a long, unreadable wall of text.
void main() {
  testWidgets(
    'a session with many exercises shows a truncated summary, not every name',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.planDao.createPlan(
        id: 'plan-1',
        name: 'Plan A',
        sessions: [
          PlanSessionInput(
            weekNumber: 1,
            day: 'Mon',
            sessionName: 'Big Day',
            exercises: [
              for (var i = 1; i <= 6; i++)
                PlanExerciseInput(
                  order: i,
                  exerciseId: 'EX$i',
                  exerciseName: 'Custom Move $i',
                  sets: 3,
                  reps: '8-10',
                ),
            ],
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

      expect(
        find.textContaining('+3 more'),
        findsOneWidget,
        reason:
            'only the first 3 of 6 exercise names should show, plus a count '
            'of the rest',
      );
      expect(
        find.textContaining('Custom Move 6'),
        findsNothing,
        reason: 'the tail of a long exercise list should be summarized, not printed',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await db.close();
    },
  );
}
