import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';

import '../generated_migrations/schema.dart';

// Every schema version that ever shipped in a commit (7, 8, 11, 12 and 14
// were only ever intermediate steps inside a single commit; v1 is the empty
// starter project with no tables, so no device ever held data at v1). A user's
// database can be at any of these when they install an update, and the
// upgrade must end in exactly the schema a fresh install creates.
//
// Snapshots live in drift_schemas/app_database/ - dumped from each version's
// own commit. After bumping schemaVersion, add the new snapshot with
//   dart run drift_dev schema dump lib/data/app_database.dart drift_schemas/app_database/drift_schema_v<N>.json
//   dart run drift_dev schema generate drift_schemas/app_database/ test/generated_migrations/
// and add <N> to the list below.
const shippedVersions = [2, 3, 4, 5, 6, 9, 10, 13, 15, 16, 17];

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  for (final from in shippedVersions) {
    test('upgrading from v$from gives the current schema', () async {
      final connection = await verifier.startAt(from);
      final db = AppDatabase.forTesting(connection);
      await verifier.migrateAndValidate(db, db.schemaVersion);
      await db.close();
    });
  }

  test('a v6 database keeps its plan, schedule and logged workout', () async {
    final schema = await verifier.schemaAt(6);
    final raw = schema.rawDatabase;
    // Drift stores DateTime as Unix seconds by default.
    final sep27 = DateTime.utc(2026, 9, 27).millisecondsSinceEpoch ~/ 1000;
    raw.execute(
      "INSERT INTO exercises (id, name, category, movement_pattern, "
      "muscle_groups, equipment, difficulty, measurement_type, is_custom) "
      "VALUES ('EX_BP', 'Bench Press', 'Main Lift', 'Push', 'Chest', "
      "'Barbell', 'Intermediate', 'Weight x Reps', 0)",
    );
    raw.execute(
      "INSERT INTO plans (id, name, created_at, updated_at) "
      "VALUES ('plan-1', 'Old Plan', $sep27, $sep27)",
    );
    raw.execute(
      "INSERT INTO plan_sessions (id, plan_id, week_number, day, "
      "session_name, assigned_date) "
      "VALUES (1, 'plan-1', 1, 'Mon', 'Push Day', $sep27)",
    );
    raw.execute(
      'INSERT INTO plan_exercises (id, session_id, "order", exercise_id, '
      "exercise_name, sets, reps) "
      "VALUES (1, 1, 1, 'EX_BP', 'Bench Press', 3, '8')",
    );
    raw.execute(
      "INSERT INTO session_logs (id, plan_session_id, logged_at) "
      "VALUES ('log-1', 1, $sep27)",
    );
    raw.execute(
      "INSERT INTO logged_sets (session_log_id, exercise_id, set_number, "
      "reps, weight, is_pr) VALUES ('log-1', 'EX_BP', 1, 8, 60.0, 1)",
    );

    final db = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(db, db.schemaVersion);

    final plan = (await db.planDao.getPlanDetails('plan-1'))!;
    expect(plan.plan.name, 'Old Plan');
    final session = plan.sessions.single;
    expect(session.session.sessionName, 'Push Day');
    expect(session.exercises.single.exerciseName, 'Bench Press');
    expect(
      session.dates.map((d) => d.toUtc()),
      [DateTime.utc(2026, 9, 27)],
      reason:
          'v6 kept one assigned_date on the session; it must survive '
          'the move to plan_session_dates',
    );

    final logs = await db.sessionLogDao.getLogsForPlanSession(
      session.session.id,
    );
    expect(logs.map((l) => l.id), ['log-1']);
    final sets = await db.sessionLogDao.getLoggedSetsForSessionLog('log-1');
    expect(sets.single.reps, 8);
    expect(sets.single.weight, 60.0);
    expect(sets.single.isPr, isTrue);

    await db.close();
  });
}
