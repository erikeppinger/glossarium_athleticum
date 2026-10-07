import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/daos/plan_dao.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  final date = DateTime(2026, 10, 7);

  PlanSessionInput session(int week, String day, String name) =>
      PlanSessionInput(
        weekNumber: week,
        day: day,
        sessionName: name,
        exercises: const [],
        assignedDates: [date],
      );

  Future<Map<String, bool>> showWeekByPlan() async => {
    for (final s in await db.planDao.getAllScheduledSessions())
      s.session.planId: s.showWeek,
  };

  test('scheduled sessions of a single-week plan leave the week out', () async {
    await db.planDao.createPlan(
      id: 'blocks',
      name: 'Nine-Block',
      sessions: [
        session(1, 'Day 1', 'Block 1'),
        session(1, 'Day 2', 'Block 2'),
      ],
    );
    await db.planDao.createPlan(
      id: 'weekly',
      name: 'Four Weeks',
      sessions: [session(1, 'Mon', 'Push'), session(2, 'Mon', 'Push')],
    );

    expect(await db.planDao.getSingleWeekPlanIds(), {'blocks'});
    expect(await showWeekByPlan(), {'blocks': false, 'weekly': true});

    // Adding a second week brings the week back.
    await db.planDao.addSession(
      planId: 'blocks',
      weekNumber: 2,
      day: 'Day 1',
      sessionName: 'Block 1',
    );
    expect(await db.planDao.getSingleWeekPlanIds(), isEmpty);
    expect(await showWeekByPlan(), {'blocks': true, 'weekly': true});
  });
}
