import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/plans_table.dart';

part 'plan_dao.g.dart';

/// One exercise-in-session entry, as supplied when building a plan (native
/// builder or spreadsheet import) - mirrors schema/plan.schema.json's
/// "planExercise".
class PlanExerciseInput {
  final int order;
  final String? exerciseId;
  final String exerciseName;
  final int sets;
  final String reps;
  final String weightIntensity;
  final int? restSec;
  final String notes;
  final String videoUrl;

  const PlanExerciseInput({
    required this.order,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    this.exerciseId,
    this.weightIntensity = '',
    this.restSec,
    this.notes = '',
    this.videoUrl = '',
  });
}

/// One Week+Day+Session Name group, as supplied when building a plan.
class PlanSessionInput {
  final int weekNumber;
  final String day;
  final String sessionName;
  final List<PlanExerciseInput> exercises;

  /// Only meaningful for JSON plan/backup import (Phase 3), which round-trips
  /// calendar placement; the spreadsheet importer (Phase 1) never sets this
  /// since a spreadsheet row has no assigned-date column.
  final DateTime? assignedDate;

  const PlanSessionInput({
    required this.weekNumber,
    required this.day,
    required this.sessionName,
    required this.exercises,
    this.assignedDate,
  });
}

/// A fully-loaded plan: the Plan row plus its sessions, each with its
/// exercises - the shape callers (UI, JSON export) actually want to work with.
class PlanDetails {
  final Plan plan;
  final List<PlanSessionDetails> sessions;

  const PlanDetails({required this.plan, required this.sessions});
}

class PlanSessionDetails {
  final PlanSession session;
  final List<PlanExercise> exercises;

  const PlanSessionDetails({required this.session, required this.exercises});
}

/// A session placed on the calendar, with its parent plan's name attached
/// so the calendar view doesn't need a second lookup per entry.
class ScheduledSession {
  final PlanSession session;
  final String planName;

  const ScheduledSession({required this.session, required this.planName});
}

@DriftAccessor(tables: [Plans, PlanSessions, PlanExercises])
class PlanDao extends DatabaseAccessor<AppDatabase> with _$PlanDaoMixin {
  PlanDao(super.db);

  Future<List<Plan>> getAllPlans() => select(plans).get();

  Stream<List<Plan>> watchAllPlans() => select(plans).watch();

  /// [createdAt]/[updatedAt] default to now - only JSON plan/backup import
  /// (Phase 3) passes the original values through, to keep an
  /// export-then-reimport round-trip byte-for-byte faithful.
  Future<String> createPlan({
    required String id,
    required String name,
    String notes = '',
    required List<PlanSessionInput> sessions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return transaction(() async {
      await into(plans).insert(
        PlansCompanion.insert(
          id: id,
          name: name,
          notes: Value(notes),
          createdAt: createdAt ?? now,
          updatedAt: updatedAt ?? now,
        ),
      );
      for (final s in sessions) {
        final sessionId = await into(planSessions).insert(
          PlanSessionsCompanion.insert(
            planId: id,
            weekNumber: s.weekNumber,
            day: s.day,
            sessionName: s.sessionName,
            assignedDate: Value(s.assignedDate),
          ),
        );
        for (final e in s.exercises) {
          await into(planExercises).insert(
            PlanExercisesCompanion.insert(
              sessionId: sessionId,
              order: e.order,
              exerciseId: Value(e.exerciseId),
              exerciseName: e.exerciseName,
              sets: e.sets,
              reps: e.reps,
              weightIntensity: Value(e.weightIntensity),
              restSec: Value(e.restSec),
              notes: Value(e.notes),
              videoUrl: Value(e.videoUrl),
            ),
          );
        }
      }
      return id;
    });
  }

  Future<PlanDetails?> getPlanDetails(String planId) async {
    final plan =
        await (select(plans)..where((p) => p.id.equals(planId)))
            .getSingleOrNull();
    if (plan == null) return null;

    final sessionRows =
        await (select(planSessions)
              ..where((s) => s.planId.equals(planId))
              ..orderBy([
                (s) => OrderingTerm.asc(s.weekNumber),
                (s) => OrderingTerm.asc(s.id),
              ]))
            .get();

    final sessions = <PlanSessionDetails>[];
    for (final session in sessionRows) {
      sessions.add(await _loadSessionDetails(session));
    }
    return PlanDetails(plan: plan, sessions: sessions);
  }

  /// Finds a session by its natural key (week + day + session name) within
  /// a plan, rather than by row id - used to re-link session logs to the
  /// right session during backup restore, since a fresh import's
  /// auto-incremented session ids won't match the ids from before the
  /// restore wiped the database.
  Future<PlanSession?> findSessionByNaturalKey({
    required String planId,
    required int weekNumber,
    required String day,
    required String sessionName,
  }) {
    return (select(planSessions)..where(
          (s) =>
              s.planId.equals(planId) &
              s.weekNumber.equals(weekNumber) &
              s.day.equals(day) &
              s.sessionName.equals(sessionName),
        ))
        .getSingleOrNull();
  }

  /// A single scheduled session with its exercises, for execution mode -
  /// doesn't need the whole plan loaded around it.
  Future<PlanSessionDetails?> getSessionDetails(int sessionId) async {
    final session =
        await (select(planSessions)..where((s) => s.id.equals(sessionId)))
            .getSingleOrNull();
    if (session == null) return null;
    return _loadSessionDetails(session);
  }

  Future<PlanSessionDetails> _loadSessionDetails(PlanSession session) async {
    final exerciseRows =
        await (select(planExercises)
              ..where((e) => e.sessionId.equals(session.id))
              ..orderBy([(e) => OrderingTerm.asc(e.order)]))
            .get();
    return PlanSessionDetails(session: session, exercises: exerciseRows);
  }

  /// All sessions that have been placed on the calendar, with their plan's
  /// name attached, for the calendar view.
  Future<List<ScheduledSession>> getAllScheduledSessions() async {
    final query = select(planSessions).join([
      innerJoin(plans, plans.id.equalsExp(planSessions.planId)),
    ])
      ..where(planSessions.assignedDate.isNotNull());
    final rows = await query.get();
    return rows
        .map(
          (row) => ScheduledSession(
            session: row.readTable(planSessions),
            planName: row.readTable(plans).name,
          ),
        )
        .toList();
  }

  Future<void> assignSessionDate(int sessionId, DateTime? date) {
    return (update(
      planSessions,
    )..where((s) => s.id.equals(sessionId))).write(
      PlanSessionsCompanion(assignedDate: Value(date)),
    );
  }

  /// Sessions whose assignedDate falls within [start, end] (inclusive),
  /// for the calendar view.
  Future<List<PlanSession>> getSessionsInRange(DateTime start, DateTime end) {
    return (select(planSessions)..where(
          (s) =>
              s.assignedDate.isNotNull() &
              s.assignedDate.isBiggerOrEqualValue(start) &
              s.assignedDate.isSmallerOrEqualValue(end),
        ))
        .get();
  }

  Future<int> deletePlan(String id) =>
      (delete(plans)..where((p) => p.id.equals(id))).go();
}
