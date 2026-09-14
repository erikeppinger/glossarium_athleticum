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

  /// See `PlanExercises.supersetGroupId`'s own doc comment - a small
  /// integer scoped to this session only, not a foreign key.
  final int? supersetGroupId;

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
    this.supersetGroupId,
  });

  /// A copy with a different [order] - used wherever a list of these is
  /// assembled in display order and just needs renumbering 1..N before
  /// being saved (see plan_builder_screen.dart, edit_session_screen.dart).
  PlanExerciseInput withOrder(int order) => PlanExerciseInput(
    order: order,
    exerciseId: exerciseId,
    exerciseName: exerciseName,
    sets: sets,
    reps: reps,
    weightIntensity: weightIntensity,
    restSec: restSec,
    notes: notes,
    videoUrl: videoUrl,
    supersetGroupId: supersetGroupId,
  );

  /// A copy with a different (or cleared, via null) [supersetGroupId] -
  /// used by the plan builder to tag several still-in-memory drafts with a
  /// shared group before the plan is even saved.
  PlanExerciseInput withSupersetGroupId(int? supersetGroupId) =>
      PlanExerciseInput(
        order: order,
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        sets: sets,
        reps: reps,
        weightIntensity: weightIntensity,
        restSec: restSec,
        notes: notes,
        videoUrl: videoUrl,
        supersetGroupId: supersetGroupId,
      );
}

/// Converts an already-saved row back into the shape [PlanDao.createPlan]
/// needs to write it again elsewhere - used wherever an existing session's
/// exercises are being copied verbatim (forking a plan) or rebuilt with one
/// added/removed (see plan_fork.dart, edit_session_screen.dart).
extension PlanExerciseToInput on PlanExercise {
  PlanExerciseInput toInput({int? order}) => PlanExerciseInput(
    order: order ?? this.order,
    exerciseId: exerciseId,
    exerciseName: exerciseName,
    sets: sets,
    reps: reps,
    weightIntensity: weightIntensity,
    restSec: restSec,
    notes: notes,
    videoUrl: videoUrl,
    supersetGroupId: supersetGroupId,
  );
}

/// One Week+Day+Session Name group, as supplied when building a plan.
class PlanSessionInput {
  final int weekNumber;
  final String day;
  final String sessionName;
  final List<PlanExerciseInput> exercises;

  /// Only meaningful for JSON plan/backup import (Phase 3+), which
  /// round-trips calendar placement; the spreadsheet importer (Phase 1)
  /// never sets this since a spreadsheet row has no assigned-date column. A
  /// session can now be scheduled on several dates at once, so this is a
  /// list rather than one nullable value - see `PlanSessionDates`.
  final List<DateTime> assignedDates;

  const PlanSessionInput({
    required this.weekNumber,
    required this.day,
    required this.sessionName,
    required this.exercises,
    this.assignedDates = const [],
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

  /// Every date this session is currently scheduled on, ascending - empty
  /// for a still-template-only session. See `PlanSessionDates`.
  final List<DateTime> dates;

  const PlanSessionDetails({
    required this.session,
    required this.exercises,
    this.dates = const [],
  });
}

/// One (session, date) occurrence placed on the calendar, with its parent
/// plan's name attached so the calendar view doesn't need a second lookup
/// per entry. A session scheduled on N dates produces N of these - unlike
/// `PlanSessionDetails.dates` (every date for one session, for the plan-detail
/// chip row), this is already fanned out to one row per occurrence, which is
/// what the calendar/notifications actually iterate over.
class ScheduledSession {
  final PlanSession session;
  final String planName;
  final DateTime date;

  const ScheduledSession({
    required this.session,
    required this.planName,
    required this.date,
  });
}

/// What deleting a plan would actually destroy, in the units a user thinks
/// in. Shown before any irreversible delete so the choice is informed - a
/// bare "Are you sure?" asks someone to consent to a loss they can't see.
class PlanDeletionImpact {
  final int sessions;
  final int exercises;
  final int loggedWorkouts;
  final int loggedSets;

  /// Null when nothing has been logged against this plan.
  final DateTime? firstLoggedAt;
  final DateTime? lastLoggedAt;

  const PlanDeletionImpact({
    required this.sessions,
    required this.exercises,
    required this.loggedWorkouts,
    required this.loggedSets,
    this.firstLoggedAt,
    this.lastLoggedAt,
  });

  /// Whether deleting would destroy training history, as opposed to just
  /// the plan structure. This is the line between "harmless tidying" and
  /// "losing something you can never recreate".
  bool get losesHistory => loggedWorkouts > 0;
}

@DriftAccessor(tables: [Plans, PlanSessions, PlanSessionDates, PlanExercises])
class PlanDao extends DatabaseAccessor<AppDatabase> with _$PlanDaoMixin {
  PlanDao(super.db);

  Future<List<Plan>> getAllPlans() => select(plans).get();

  Stream<List<Plan>> watchAllPlans() => select(plans).watch();

  /// Active (non-archived) plans only - what the plan list shows.
  Stream<List<Plan>> watchActivePlans() =>
      (select(plans)..where((p) => p.archivedAt.isNull())).watch();

  Stream<List<Plan>> watchArchivedPlans() =>
      (select(plans)..where((p) => p.archivedAt.isNotNull())).watch();

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
    String? createdBy,
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
          createdBy: Value(createdBy),
        ),
      );
      for (final s in sessions) {
        final sessionId = await into(planSessions).insert(
          PlanSessionsCompanion.insert(
            planId: id,
            weekNumber: s.weekNumber,
            day: s.day,
            sessionName: s.sessionName,
          ),
        );
        for (final date in s.assignedDates) {
          await into(planSessionDates).insert(
            PlanSessionDatesCompanion.insert(sessionId: sessionId, date: date),
          );
        }
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
              supersetGroupId: Value(e.supersetGroupId),
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
          supersetGroupId: Value(input.supersetGroupId),
        ),
      );
      await _touchUpdatedAt(session.planId);
    });
  }

  /// Clones [sessionId]'s exercises into new sessions at each of
  /// [weekNumbers] (same day and session name) - lets a block that repeats
  /// across a program's weeks be built once and copied, instead of
  /// re-entering every exercise by hand for each repeat week. Skips a week
  /// number if a session with the same day + name already exists in that
  /// plan (idempotent-feeling, matching [addSessionDate]'s own "no-op if
  /// already there" precedent) - returns how many were actually added vs.
  /// skipped so the caller can mention it. Deliberately does not copy
  /// [PlanSessionDates]: a duplicated week's session starts unscheduled,
  /// since copying calendar dates across different weeks makes no sense.
  Future<({int added, int skipped})> duplicateSessionToWeeks({
    required int sessionId,
    required List<int> weekNumbers,
  }) async {
    final source = await getSessionDetails(sessionId);
    if (source == null) return (added: 0, skipped: 0);
    final session = source.session;

    var added = 0;
    var skipped = 0;
    await transaction(() async {
      for (final week in weekNumbers) {
        final exists =
            await (select(planSessions)..where(
                  (s) =>
                      s.planId.equals(session.planId) &
                      s.weekNumber.equals(week) &
                      s.day.equals(session.day) &
                      s.sessionName.equals(session.sessionName),
                ))
                .getSingleOrNull();
        if (exists != null) {
          skipped++;
          continue;
        }
        final newSessionId = await into(planSessions).insert(
          PlanSessionsCompanion.insert(
            planId: session.planId,
            weekNumber: week,
            day: session.day,
            sessionName: session.sessionName,
          ),
        );
        for (final exercise in source.exercises) {
          await into(planExercises).insert(
            PlanExercisesCompanion.insert(
              sessionId: newSessionId,
              order: exercise.order,
              exerciseId: Value(exercise.exerciseId),
              exerciseName: exercise.exerciseName,
              sets: exercise.sets,
              reps: exercise.reps,
              weightIntensity: Value(exercise.weightIntensity),
              restSec: Value(exercise.restSec),
              notes: Value(exercise.notes),
              videoUrl: Value(exercise.videoUrl),
              supersetGroupId: Value(exercise.supersetGroupId),
            ),
          );
        }
        added++;
      }
      if (added > 0) await _touchUpdatedAt(session.planId);
    });
    return (added: added, skipped: skipped);
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
    final dates = await getDatesForSession(session.id);
    return PlanSessionDetails(
      session: session,
      exercises: exerciseRows,
      dates: dates,
    );
  }

  /// Every date [sessionId] is currently scheduled on, ascending - empty if
  /// it's still template-only. Backs the plan-detail chip row.
  Future<List<DateTime>> getDatesForSession(int sessionId) {
    return (select(planSessionDates)
          ..where((d) => d.sessionId.equals(sessionId))
          ..orderBy([(d) => OrderingTerm.asc(d.date)]))
        .map((d) => d.date)
        .get();
  }

  /// One row per (session, date) occurrence that's been placed on the
  /// calendar, with its parent plan's name attached, for the calendar view
  /// and notification scheduling - a session scheduled on N dates produces N
  /// rows here, not one.
  Future<List<ScheduledSession>> getAllScheduledSessions() async {
    final query = select(planSessionDates).join([
      innerJoin(
        planSessions,
        planSessions.id.equalsExp(planSessionDates.sessionId),
      ),
      innerJoin(plans, plans.id.equalsExp(planSessions.planId)),
    ]);
    final rows = await query.get();
    return rows
        .map(
          (row) => ScheduledSession(
            session: row.readTable(planSessions),
            planName: row.readTable(plans).name,
            date: row.readTable(planSessionDates).date,
          ),
        )
        .toList();
  }

  /// Schedules [sessionId] on [date] - a no-op if it's already scheduled on
  /// that exact date, so a caller doesn't need to check first. Bumps the
  /// parent plan's `updated_at` too - see [addSession] for why a direct
  /// mutation to a plan's contents always needs to do this.
  Future<void> addSessionDate(int sessionId, DateTime date) {
    return transaction(() async {
      final session =
          await (select(planSessions)..where((s) => s.id.equals(sessionId)))
              .getSingle();
      final existing =
          await (select(planSessionDates)..where(
                (d) => d.sessionId.equals(sessionId) & d.date.equals(date),
              ))
              .getSingleOrNull();
      if (existing != null) return;
      await into(planSessionDates).insert(
        PlanSessionDatesCompanion.insert(sessionId: sessionId, date: date),
      );
      await _touchUpdatedAt(session.planId);
    });
  }

  /// Unschedules [sessionId] from [date] - only ever removes the scheduling
  /// row, never touches `SessionLogs`/`LoggedSets`: what was actually
  /// trained on that date is independent of whether it's still "upcoming" on
  /// the calendar. See the deletion-philosophy convention in CLAUDE.md.
  Future<void> removeSessionDate(int sessionId, DateTime date) {
    return transaction(() async {
      final session =
          await (select(planSessions)..where((s) => s.id.equals(sessionId)))
              .getSingle();
      await (delete(planSessionDates)..where(
            (d) => d.sessionId.equals(sessionId) & d.date.equals(date),
          ))
          .go();
      await _touchUpdatedAt(session.planId);
    });
  }

  /// Moves one scheduled occurrence of [sessionId] from [from] to [to] -
  /// e.g. the calendar's "move to today?" prompt, or editing one date from
  /// the plan-detail chip row. Bumps the parent plan's `updated_at`.
  Future<void> moveSessionDate(
    int sessionId, {
    required DateTime from,
    required DateTime to,
  }) {
    return transaction(() async {
      final session =
          await (select(planSessions)..where((s) => s.id.equals(sessionId)))
              .getSingle();
      await (update(planSessionDates)..where(
            (d) => d.sessionId.equals(sessionId) & d.date.equals(from),
          ))
          .write(PlanSessionDatesCompanion(date: Value(to)));
      await _touchUpdatedAt(session.planId);
    });
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

  /// Tags every row in [planExerciseIds] with a newly-assigned, shared
  /// `supersetGroupId` - they must all belong to the same session (throws
  /// [ArgumentError] otherwise, since a superset only makes sense within one
  /// session's own round-robin execution). The new id is the smallest
  /// unused positive integer within that session, so re-grouping after an
  /// earlier group was cleared reuses freed numbers rather than growing
  /// forever.
  Future<void> setSupersetGroup(List<int> planExerciseIds) {
    return transaction(() async {
      final rows =
          await (select(
            planExercises,
          )..where((e) => e.id.isIn(planExerciseIds))).get();
      if (rows.length != planExerciseIds.length) {
        throw ArgumentError('One or more planExerciseIds do not exist');
      }
      final sessionIds = rows.map((r) => r.sessionId).toSet();
      if (sessionIds.length > 1) {
        throw ArgumentError(
          'All exercises being grouped must belong to the same session',
        );
      }
      final sessionId = sessionIds.single;

      final siblings =
          await (select(
            planExercises,
          )..where((e) => e.sessionId.equals(sessionId))).get();
      final usedGroupIds = siblings
          .map((e) => e.supersetGroupId)
          .whereType<int>()
          .toSet();
      var newGroupId = 1;
      while (usedGroupIds.contains(newGroupId)) {
        newGroupId++;
      }

      for (final id in planExerciseIds) {
        await (update(planExercises)..where((e) => e.id.equals(id))).write(
          PlanExercisesCompanion(supersetGroupId: Value(newGroupId)),
        );
      }
      final planId = await _planIdForPlanExercise(planExerciseIds.first);
      await _touchUpdatedAt(planId);
    });
  }

  /// Removes one exercise from whatever superset group it's in (a no-op if
  /// it isn't in one), leaving the rest of that group untouched.
  Future<void> clearSupersetGroup(int planExerciseId) {
    return transaction(() async {
      await (update(planExercises)..where((e) => e.id.equals(planExerciseId)))
          .write(
            const PlanExercisesCompanion(supersetGroupId: Value(null)),
          );
      final planId = await _planIdForPlanExercise(planExerciseId);
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

  Future<void> renamePlan(String planId, String name) {
    return transaction(() async {
      await (update(plans)..where((p) => p.id.equals(planId))).write(
        PlansCompanion(name: Value(name)),
      );
      await _touchUpdatedAt(planId);
    });
  }

  /// Free-text notes on the plan itself - a scratchpad for things like "swap
  /// exercise X for Y next block", distinct from a plan exercise's own notes
  /// (edited per-row via `edit_session_screen.dart`). Already part of the
  /// plan JSON export/import and shown read-only in the plan list, but
  /// nothing let it actually be edited from within the app until now.
  Future<void> updatePlanNotes(String planId, String notes) {
    return transaction(() async {
      await (update(plans)..where((p) => p.id.equals(planId))).write(
        PlansCompanion(notes: Value(notes)),
      );
      await _touchUpdatedAt(planId);
    });
  }

  /// Who authored this plan (e.g. a trainer's name) - see
  /// `Plans.createdBy`'s own doc comment. [createdBy] null clears it back to
  /// "no author stated" rather than the empty string [updatePlanNotes] uses,
  /// since a blank author is meaningfully different from an unset one here
  /// (an empty "Created by" field in the UI means "remove this", not "set it
  /// to blank").
  Future<void> updatePlanCreatedBy(String planId, String? createdBy) {
    return transaction(() async {
      await (update(plans)..where((p) => p.id.equals(planId))).write(
        PlansCompanion(createdBy: Value(createdBy)),
      );
      await _touchUpdatedAt(planId);
    });
  }

  /// Hides a plan from the plan list without touching any of its data.
  /// The reversible counterpart to [deletePlan] - see [unarchivePlan].
  Future<void> archivePlan(String planId) {
    return transaction(() async {
      await (update(plans)..where((p) => p.id.equals(planId))).write(
        PlansCompanion(archivedAt: Value(DateTime.now())),
      );
      await _touchUpdatedAt(planId);
    });
  }

  /// Sets this plan's opt-in state for the periodic progress-reminder
  /// notification - see plan_report_prompt.dart. [reportOptInAt] is stamped
  /// to now whenever [preference] is `'enabled'` (including re-enabling
  /// after a change of frequency), since it's the anchor point the actual
  /// reminder schedule is computed from - see
  /// `lib/logic/notification_schedule.dart`'s `buildPlanReportReminder`.
  Future<void> setReportPreference({
    required String planId,
    required String preference,
    int? frequencyDays,
  }) {
    return (update(plans)..where((p) => p.id.equals(planId))).write(
      PlansCompanion(
        reportPreference: Value(preference),
        reportFrequencyDays: Value(preference == 'enabled' ? frequencyDays : null),
        reportOptInAt: Value(preference == 'enabled' ? DateTime.now() : null),
      ),
    );
  }

  Future<void> unarchivePlan(String planId) {
    return transaction(() async {
      await (update(plans)..where((p) => p.id.equals(planId))).write(
        const PlansCompanion(archivedAt: Value(null)),
      );
      await _touchUpdatedAt(planId);
    });
  }

  /// Counts what a hard delete of [planId] would destroy. Reads across the
  /// SessionLogs/LoggedSets tables too, since the whole point is to surface
  /// the training history at stake - which lives outside this DAO's own
  /// tables.
  Future<PlanDeletionImpact> getPlanDeletionImpact(String planId) async {
    final sessionRows = await (select(
      planSessions,
    )..where((s) => s.planId.equals(planId))).get();
    final sessionIds = [for (final s in sessionRows) s.id];

    final exerciseCount = sessionIds.isEmpty
        ? 0
        : (await (select(
            planExercises,
          )..where((e) => e.sessionId.isIn(sessionIds))).get()).length;

    if (sessionIds.isEmpty) {
      return PlanDeletionImpact(
        sessions: 0,
        exercises: exerciseCount,
        loggedWorkouts: 0,
        loggedSets: 0,
      );
    }

    final logs = await (select(
      db.sessionLogs,
    )..where((l) => l.planSessionId.isIn(sessionIds))).get();
    final logIds = [for (final l in logs) l.id];
    final setCount = logIds.isEmpty
        ? 0
        : (await (select(
            db.loggedSets,
          )..where((s) => s.sessionLogId.isIn(logIds))).get()).length;

    final dates = [for (final l in logs) l.loggedAt]..sort();

    return PlanDeletionImpact(
      sessions: sessionRows.length,
      exercises: exerciseCount,
      loggedWorkouts: logs.length,
      loggedSets: setCount,
      firstLoggedAt: dates.isEmpty ? null : dates.first,
      lastLoggedAt: dates.isEmpty ? null : dates.last,
    );
  }

  /// Deletes a plan's structure while leaving its logged workouts in place.
  ///
  /// Logged history is the one thing a user can never recreate, so removing
  /// a plan should not take it down as collateral. The logs keep pointing at
  /// their (now plan-less) session rows, which are deliberately retained as
  /// tombstones so history stays readable and attributable.
  Future<void> deletePlanKeepingHistory(String planId) {
    return transaction(() async {
      final sessionRows = await (select(
        planSessions,
      )..where((s) => s.planId.equals(planId))).get();
      final sessionIds = [for (final s in sessionRows) s.id];

      final loggedSessionIds = <int>{};
      if (sessionIds.isNotEmpty) {
        final logs = await (select(
          db.sessionLogs,
        )..where((l) => l.planSessionId.isIn(sessionIds))).get();
        // Safe to unwrap: every row here matched planSessionId.isIn(sessionIds),
        // so none of them can be an ad-hoc activity's null.
        loggedSessionIds.addAll(logs.map((l) => l.planSessionId!));
      }

      // The prescription rows are safe to drop either way - a logged set
      // records what was actually done, not what was planned.
      if (sessionIds.isNotEmpty) {
        await (delete(
          planExercises,
        )..where((e) => e.sessionId.isIn(sessionIds))).go();
      }

      // A kept, tombstoned session shouldn't still show as scheduled -
      // delete its dates (children before parent, same reasoning as
      // everywhere else in this DAO) rather than leave them pointing at a
      // session whose plan no longer exists.
      if (sessionIds.isNotEmpty) {
        await (delete(
          planSessionDates,
        )..where((d) => d.sessionId.isIn(sessionIds))).go();
      }

      // Keep only the sessions that something was logged against; detach
      // them from the plan being deleted.
      final unloggedIds = sessionIds
          .where((id) => !loggedSessionIds.contains(id))
          .toList();
      if (unloggedIds.isNotEmpty) {
        await (delete(planSessions)..where((s) => s.id.isIn(unloggedIds))).go();
      }

      await (delete(plans)..where((p) => p.id.equals(planId))).go();
    });
  }

  /// Deletes a plan and every workout ever logged against it. The
  /// irreversible option - callers must show [getPlanDeletionImpact] first.
  Future<void> deletePlanAndHistory(String planId) {
    return transaction(() async {
      final sessionRows = await (select(
        planSessions,
      )..where((s) => s.planId.equals(planId))).get();
      final sessionIds = [for (final s in sessionRows) s.id];

      if (sessionIds.isNotEmpty) {
        final logs = await (select(
          db.sessionLogs,
        )..where((l) => l.planSessionId.isIn(sessionIds))).get();
        final logIds = [for (final l in logs) l.id];
        if (logIds.isNotEmpty) {
          await (delete(
            db.loggedSets,
          )..where((s) => s.sessionLogId.isIn(logIds))).go();
          await (delete(db.sessionLogs)..where((l) => l.id.isIn(logIds))).go();
        }
        await (delete(
          planExercises,
        )..where((e) => e.sessionId.isIn(sessionIds))).go();
        await (delete(
          planSessionDates,
        )..where((d) => d.sessionId.isIn(sessionIds))).go();
        await (delete(planSessions)..where((s) => s.id.isIn(sessionIds))).go();
      }
      await (delete(plans)..where((p) => p.id.equals(planId))).go();
    });
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
      await (delete(
        planSessionDates,
      )..where((d) => d.sessionId.isIn(sessionIds))).go();
      await (delete(planSessions)..where((s) => s.planId.equals(id))).go();
      await (delete(plans)..where((p) => p.id.equals(id))).go();
    });
  }
}
