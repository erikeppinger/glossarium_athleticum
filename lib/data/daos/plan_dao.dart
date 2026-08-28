import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

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

  /// Creates a plan with no sessions yet - the starting point for adding
  /// exercises one at a time from the Exercise Library, rather than only
  /// being able to build a plan via spreadsheet/JSON import.
  Future<String> createEmptyPlan({required String name, String notes = ''}) {
    return createPlan(id: const Uuid().v4(), name: name, notes: notes, sessions: const []);
  }

  /// Adds a new session to an existing plan and bumps the plan's
  /// `updated_at` - any direct mutation to a plan's contents must do this,
  /// or Phase 5's sync conflict detection (which compares `updated_at`)
  /// won't notice the change. Returns the new session's row id.
  Future<int> addSession({
    required String planId,
    required int weekNumber,
    required String day,
    required String sessionName,
  }) {
    return transaction(() async {
      final sessionId = await into(planSessions).insert(
        PlanSessionsCompanion.insert(
          planId: planId,
          weekNumber: weekNumber,
          day: day,
          sessionName: sessionName,
        ),
      );
      await _touchUpdatedAt(planId);
      return sessionId;
    });
  }

  /// Appends an exercise to an existing session (after whatever's already
  /// there) and bumps the parent plan's `updated_at` - see [addSession] for
  /// why that matters. Used by the Exercise Library's "Add to plan" flow.
  Future<void> addExerciseToSession({
    required int sessionId,
    required PlanExerciseInput input,
  }) {
    return transaction(() async {
      final session =
          await (select(planSessions)..where((s) => s.id.equals(sessionId)))
              .getSingle();
      final existingOrders = await (select(
        planExercises,
      )..where((e) => e.sessionId.equals(sessionId))).map((e) => e.order).get();
      final nextOrder = existingOrders.isEmpty
          ? 1
          : existingOrders.reduce((a, b) => a > b ? a : b) + 1;

      await into(planExercises).insert(
        PlanExercisesCompanion.insert(
          sessionId: sessionId,
          order: nextOrder,
          exerciseId: Value(input.exerciseId),
          exerciseName: input.exerciseName,
          sets: input.sets,
          reps: input.reps,
          weightIntensity: Value(input.weightIntensity),
          restSec: Value(input.restSec),
          notes: Value(input.notes),
          videoUrl: Value(input.videoUrl),
        ),
      );
      await _touchUpdatedAt(session.planId);
    });
  }

  Future<void> _touchUpdatedAt(String planId) {
    return (update(plans)..where((p) => p.id.equals(planId))).write(
      PlansCompanion(updatedAt: Value(DateTime.now())),
    );
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

  /// Bumps the parent plan's `updated_at` too - see [addSession] for why a
  /// direct mutation to a plan's contents always needs to do this.
  Future<void> assignSessionDate(int sessionId, DateTime? date) {
    return transaction(() async {
      final session =
          await (select(planSessions)..where((s) => s.id.equals(sessionId)))
              .getSingle();
      await (update(
        planSessions,
      )..where((s) => s.id.equals(sessionId))).write(
        PlanSessionsCompanion(assignedDate: Value(date)),
      );
      await _touchUpdatedAt(session.planId);
    });
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

  /// Edits one exercise-in-session row in place. Only the prescription
  /// fields are editable - swapping which exercise a row points at is a
  /// remove-then-add, not an edit. Bumps the parent plan's `updated_at`.
  Future<void> updatePlanExercise({
    required int planExerciseId,
    required int sets,
    required String reps,
    required String weightIntensity,
    int? restSec,
    required String notes,
  }) {
    return transaction(() async {
      final planId = await _planIdForPlanExercise(planExerciseId);
      await (update(
        planExercises,
      )..where((e) => e.id.equals(planExerciseId))).write(
        PlanExercisesCompanion(
          sets: Value(sets),
          reps: Value(reps),
          weightIntensity: Value(weightIntensity),
          restSec: Value(restSec),
          notes: Value(notes),
        ),
      );
      await _touchUpdatedAt(planId);
    });
  }

  /// Removes one exercise from a session, closing the gap it leaves in the
  /// remaining rows' `order` values so they stay contiguous (1, 2, 3, ...) -
  /// [addExerciseToSession] derives the next order from the current max, so
  /// leaving holes would be harmless but leaving duplicates would not.
  Future<void> deletePlanExercise(int planExerciseId) {
    return transaction(() async {
      final row = await (select(
        planExercises,
      )..where((e) => e.id.equals(planExerciseId))).getSingle();
      final planId = await _planIdForPlanExercise(planExerciseId);

      await (delete(
        planExercises,
      )..where((e) => e.id.equals(planExerciseId))).go();

      final remaining =
          await (select(planExercises)
                ..where((e) => e.sessionId.equals(row.sessionId))
                ..orderBy([(e) => OrderingTerm.asc(e.order)]))
              .get();
      for (var i = 0; i < remaining.length; i++) {
        await (update(
          planExercises,
        )..where((e) => e.id.equals(remaining[i].id))).write(
          PlanExercisesCompanion(order: Value(i + 1)),
        );
      }
      await _touchUpdatedAt(planId);
    });
  }

  /// Moves one exercise up or down within its session, swapping `order`
  /// with its neighbour. A no-op at either end of the list.
  Future<void> movePlanExercise({
    required int planExerciseId,
    required bool up,
  }) {
    return transaction(() async {
      final row = await (select(
        planExercises,
      )..where((e) => e.id.equals(planExerciseId))).getSingle();
      final planId = await _planIdForPlanExercise(planExerciseId);

      final siblings =
          await (select(planExercises)
                ..where((e) => e.sessionId.equals(row.sessionId))
                ..orderBy([(e) => OrderingTerm.asc(e.order)]))
              .get();
      final index = siblings.indexWhere((e) => e.id == planExerciseId);
      final swapIndex = up ? index - 1 : index + 1;
      if (swapIndex < 0 || swapIndex >= siblings.length) return;

      final other = siblings[swapIndex];
      await (update(planExercises)..where((e) => e.id.equals(row.id))).write(
        PlanExercisesCompanion(order: Value(other.order)),
      );
      await (update(planExercises)..where((e) => e.id.equals(other.id))).write(
        PlanExercisesCompanion(order: Value(row.order)),
      );
      await _touchUpdatedAt(planId);
    });
  }

  Future<String> _planIdForPlanExercise(int planExerciseId) async {
    final query = select(planExercises).join([
      innerJoin(
        planSessions,
        planSessions.id.equalsExp(planExercises.sessionId),
      ),
    ])..where(planExercises.id.equals(planExerciseId));
    final row = await query.getSingle();
    return row.readTable(planSessions).planId;
  }

  /// Deletes a plan and its sessions/exercises, children before parents -
  /// same reasoning as [MaintenanceDao.wipeAllData]: this must not assume
  /// SQLite's foreign_keys pragma is on. Does NOT touch SessionLogs/
  /// LoggedSets (a different DAO's tables) - callers that also need those
  /// gone (e.g. Phase 5's plan_sync.dart) must delete them first, before
  /// calling this.
  Future<void> deletePlan(String id) {
    return transaction(() async {
      final sessionIds = await (select(
        planSessions,
      )..where((s) => s.planId.equals(id))).map((s) => s.id).get();
      await (delete(
        planExercises,
      )..where((e) => e.sessionId.isIn(sessionIds))).go();
      await (delete(planSessions)..where((s) => s.planId.equals(id))).go();
      await (delete(plans)..where((p) => p.id.equals(id))).go();
    });
  }
}
