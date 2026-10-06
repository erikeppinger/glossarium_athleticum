import 'package:drift/drift.dart';

import '../../logic/progression.dart';
import '../../logic/set_measure.dart';
import '../app_database.dart';
import '../tables/exercises_table.dart';
import '../tables/plans_table.dart';
import '../tables/session_logs_table.dart';

part 'session_log_dao.g.dart';

class LoggedSetInput {
  final String exerciseId;
  final int setNumber;
  final int? reps;
  final double? weight;
  final double? durationSec;
  final double? distance;
  final double? rpe;
  final bool isPr;

  /// See `LoggedSets.notes`' own doc comment - trainee-to-trainer feedback
  /// on this specific set.
  final String? notes;

  const LoggedSetInput({
    required this.exerciseId,
    required this.setNumber,
    this.reps,
    this.weight,
    this.durationSec,
    this.distance,
    this.rpe,
    this.isPr = false,
    this.notes,
  });
}

/// One prescribed exercise skipped in a session being saved - see the
/// `SkippedExercises` table's own doc comment.
class SkippedExerciseInput {
  final String exerciseId;
  final String exerciseName;
  final int prescribedSets;
  final String prescribedReps;
  final String prescribedWeightIntensity;
  final int? prescribedRestSec;

  /// A `SkipReason.key`, or null.
  final String? reason;
  final String? replacedByExerciseId;
  final String? replacedByExerciseName;
  final bool queuedForNextSession;
  final DateTime? dismissedAt;

  const SkippedExerciseInput({
    required this.exerciseId,
    required this.exerciseName,
    required this.prescribedSets,
    required this.prescribedReps,
    this.prescribedWeightIntensity = '',
    this.prescribedRestSec,
    this.reason,
    this.replacedByExerciseId,
    this.replacedByExerciseName,
    this.queuedForNextSession = false,
    this.dismissedAt,
  });
}

extension SkippedExerciseToInput on SkippedExercise {
  /// For re-creating a saved row under a new or relinked session log.
  SkippedExerciseInput toInput() => SkippedExerciseInput(
    exerciseId: exerciseId,
    exerciseName: exerciseName,
    prescribedSets: prescribedSets,
    prescribedReps: prescribedReps,
    prescribedWeightIntensity: prescribedWeightIntensity,
    prescribedRestSec: prescribedRestSec,
    reason: reason,
    replacedByExerciseId: replacedByExerciseId,
    replacedByExerciseName: replacedByExerciseName,
    queuedForNextSession: queuedForNextSession,
    dismissedAt: dismissedAt,
  );
}

/// A skipped exercise still waiting to be made up, with when it was missed.
class PendingMakeUp {
  final SkippedExercise skip;
  final DateTime skippedAt;

  const PendingMakeUp({required this.skip, required this.skippedAt});
}

@DriftAccessor(
  tables: [
    SessionLogs,
    LoggedSets,
    SkippedExercises,
    PlanSessions,
    PlanSessionDates,
    PlanExercises,
    Exercises,
    Plans,
  ],
)
class SessionLogDao extends DatabaseAccessor<AppDatabase>
    with _$SessionLogDaoMixin {
  SessionLogDao(super.db);

  Future<String> createSessionLog({
    required String id,
    required int planSessionId,
    required DateTime loggedAt,
    required List<LoggedSetInput> entries,
    String? notes,
    List<SkippedExerciseInput> skipped = const [],
  }) {
    return transaction(() async {
      // Also clears any autosaved draft for this plan session (see
      // saveDraft/deleteDraft) - a real, finished log now exists, so a
      // stale draft would otherwise sit around as dead data forever (it's
      // already invisible to every read query, but there's no reason to
      // keep it). Uses the non-transactional helper, not the public
      // deleteDraft, since drift's transaction() isn't reentrant.
      await _deleteDraftRows(planSessionId);
      await into(sessionLogs).insert(
        SessionLogsCompanion.insert(
          id: id,
          planSessionId: Value(planSessionId),
          loggedAt: loggedAt,
          finishedAt: Value(loggedAt),
          notes: Value(notes),
        ),
      );
      for (final e in entries) {
        await into(loggedSets).insert(
          LoggedSetsCompanion.insert(
            sessionLogId: id,
            exerciseId: e.exerciseId,
            setNumber: e.setNumber,
            reps: Value(e.reps),
            weight: Value(e.weight),
            durationSec: Value(e.durationSec),
            distance: Value(e.distance),
            rpe: Value(e.rpe),
            isPr: Value(e.isPr),
            notes: Value(e.notes),
          ),
        );
      }
      for (final s in skipped) {
        await into(skippedExercises).insert(
          SkippedExercisesCompanion.insert(
            sessionLogId: id,
            exerciseId: s.exerciseId,
            exerciseName: s.exerciseName,
            prescribedSets: s.prescribedSets,
            prescribedReps: s.prescribedReps,
            prescribedWeightIntensity: Value(s.prescribedWeightIntensity),
            prescribedRestSec: Value(s.prescribedRestSec),
            reason: Value(s.reason),
            replacedByExerciseId: Value(s.replacedByExerciseId),
            replacedByExerciseName: Value(s.replacedByExerciseName),
            queuedForNextSession: Value(s.queuedForNextSession),
            dismissedAt: Value(s.dismissedAt),
          ),
        );
      }
      return id;
    });
  }

  Future<List<SkippedExercise>> getSkippedForSessionLog(String sessionLogId) {
    return (select(skippedExercises)
          ..where((s) => s.sessionLogId.equals(sessionLogId))
          ..orderBy([(s) => OrderingTerm.asc(s.id)]))
        .get();
  }

  /// Skipped exercises still worth making up, newest first: not replaced by
  /// a logged substitute, not dismissed, and not logged in any finished
  /// session after the one it was skipped in. Doing the exercise again for
  /// any reason - a make-up, the same session next week, "Start now" -
  /// clears it, so this never needs its own "done" bookkeeping.
  Future<List<PendingMakeUp>> getPendingMakeUps() async {
    final rows =
        await (select(skippedExercises).join([
                innerJoin(
                  sessionLogs,
                  sessionLogs.id.equalsExp(skippedExercises.sessionLogId),
                ),
                // An exercise deleted from the library since can't be made
                // up; re-importing it (same id) brings the skip back.
                innerJoin(
                  exercises,
                  exercises.id.equalsExp(skippedExercises.exerciseId),
                ),
              ])
              ..where(
                skippedExercises.dismissedAt.isNull() &
                    skippedExercises.replacedByExerciseId.isNull() &
                    sessionLogs.finishedAt.isNotNull(),
              )
              ..orderBy([OrderingTerm.desc(sessionLogs.loggedAt)]))
            .get();
    if (rows.isEmpty) return [];

    final exerciseIds = {
      for (final row in rows) row.readTable(skippedExercises).exerciseId,
    };
    final lastLoggedAt = sessionLogs.loggedAt.max();
    final latestQuery =
        selectOnly(loggedSets).join([
            innerJoin(
              sessionLogs,
              sessionLogs.id.equalsExp(loggedSets.sessionLogId),
            ),
          ])
          ..addColumns([loggedSets.exerciseId, lastLoggedAt])
          ..where(
            loggedSets.exerciseId.isIn(exerciseIds) &
                sessionLogs.finishedAt.isNotNull(),
          )
          ..groupBy([loggedSets.exerciseId]);
    final latestByExercise = {
      for (final row in await latestQuery.get())
        row.read(loggedSets.exerciseId)!: row.read(lastLoggedAt),
    };

    final pending = <PendingMakeUp>[];
    for (final row in rows) {
      final skip = row.readTable(skippedExercises);
      final skippedAt = row.readTable(sessionLogs).loggedAt;
      final latest = latestByExercise[skip.exerciseId];
      if (latest != null && latest.isAfter(skippedAt)) continue;
      pending.add(PendingMakeUp(skip: skip, skippedAt: skippedAt));
    }
    return pending;
  }

  /// Partial update - see `updateLoggedSet` for why not an upsert.
  Future<void> setMakeUpQueued(int skippedExerciseId, bool queued) {
    return (update(skippedExercises)
          ..where((s) => s.id.equals(skippedExerciseId)))
        .write(SkippedExercisesCompanion(queuedForNextSession: Value(queued)));
  }

  /// Dropping a make-up is reversible (the Today tab offers Undo), so this
  /// also clears the dismissal when [dismissed] is false.
  Future<void> setMakeUpDismissed(int skippedExerciseId, bool dismissed) {
    return (update(skippedExercises)
          ..where((s) => s.id.equals(skippedExerciseId)))
        .write(
          SkippedExercisesCompanion(
            dismissedAt: Value(dismissed ? DateTime.now() : null),
          ),
        );
  }

  /// Logs a walk/run/anything-else that isn't tied to a scheduled plan
  /// session - just a date, a name, and optionally how long/far. Has no
  /// [LoggedSets] children: there's no exercise to log sets against, so
  /// `planSessionId == null` is the only thing that distinguishes this from
  /// a normal workout everywhere it's read back.
  Future<String> createAdHocActivity({
    required String id,
    required DateTime loggedAt,
    required String activityName,
    double? durationSec,
    double? distance,
    String? notes,
  }) async {
    await into(sessionLogs).insert(
      SessionLogsCompanion.insert(
        id: id,
        planSessionId: const Value(null),
        loggedAt: loggedAt,
        finishedAt: Value(loggedAt),
        activityName: Value(activityName),
        durationSec: Value(durationSec),
        distance: Value(distance),
        notes: Value(notes),
      ),
    );
    return id;
  }

  /// Autosaves whatever's been checked off so far in an in-progress
  /// execution-mode session, as a **draft** (`finishedAt: null`) - called
  /// from `execution_screen.dart`'s app-lifecycle observer when the app is
  /// backgrounded, so a real Android process kill (common - see the report
  /// this was built for) doesn't silently erase an unfinished workout the
  /// way it used to, when nothing was written to the database at all until
  /// "Finish session". Replaces (delete + reinsert) any prior draft for the
  /// same [planSessionId] wholesale rather than diffing - a session is only
  /// ever actively open in one execution screen at a time, so there's never
  /// more than one draft per plan session to reconcile.
  Future<void> saveDraft({
    required int planSessionId,
    required DateTime loggedAt,
    required List<LoggedSetInput> entries,
  }) {
    return transaction(() async {
      await _deleteDraftRows(planSessionId);
      if (entries.isEmpty) return;
      final draftId = 'draft-$planSessionId';
      await into(sessionLogs).insert(
        SessionLogsCompanion.insert(
          id: draftId,
          planSessionId: Value(planSessionId),
          loggedAt: loggedAt,
        ),
      );
      for (final e in entries) {
        await into(loggedSets).insert(
          LoggedSetsCompanion.insert(
            sessionLogId: draftId,
            exerciseId: e.exerciseId,
            setNumber: e.setNumber,
            reps: Value(e.reps),
            weight: Value(e.weight),
            durationSec: Value(e.durationSec),
            distance: Value(e.distance),
            rpe: Value(e.rpe),
            isPr: Value(e.isPr),
            notes: Value(e.notes),
          ),
        );
      }
    });
  }

  /// Deletes any autosaved draft for [planSessionId] - called once a real
  /// finished log takes its place ([createSessionLog]) or the session is
  /// explicitly discarded (`execution_screen.dart`'s "Discard" choice).
  Future<void> deleteDraft(int planSessionId) {
    return transaction(() => _deleteDraftRows(planSessionId));
  }

  Future<void> _deleteDraftRows(int planSessionId) async {
    final draftIds = await (select(sessionLogs)..where(
          (l) =>
              l.planSessionId.equals(planSessionId) & l.finishedAt.isNull(),
        ))
        .map((l) => l.id)
        .get();
    if (draftIds.isEmpty) return;
    await (delete(loggedSets)..where((s) => s.sessionLogId.isIn(draftIds))).go();
    await (delete(sessionLogs)..where((l) => l.id.isIn(draftIds))).go();
  }

  /// Reads back an autosaved draft's logged sets (see [saveDraft]) so
  /// `execution_screen.dart` can restore a session's checked-off sets after
  /// a cold start following a process kill, where the in-memory
  /// `_InProgressSession` provider is gone along with everything else.
  /// Empty if there's no draft for this plan session.
  Future<List<LoggedSet>> getDraftSets(int planSessionId) async {
    final draft = await (select(sessionLogs)..where(
          (l) =>
              l.planSessionId.equals(planSessionId) & l.finishedAt.isNull(),
        ))
        .getSingleOrNull();
    if (draft == null) return [];
    return getLoggedSetsForSessionLog(draft.id);
  }

  /// The plan session id of the most recently autosaved draft still sitting
  /// around (`finishedAt` null), if any - read once at app startup
  /// (`main.dart`'s `_startupProvider`) to restore
  /// `activeInProgressSessionIdProvider` after a genuine process kill.
  /// Without this, the "session in progress" resume banner only ever came
  /// back once the session's own `ExecutionScreen` happened to be reopened
  /// (e.g. by tapping a still-live rest-timer notification) - a cold start
  /// from the launcher, with no notification involved, showed no sign a
  /// session was ever in progress at all, even though its draft (and thus
  /// its checked-off sets) were safe in the database the whole time.
  /// `saveDraft`'s own doc comment notes only one draft is expected to exist
  /// at a time in normal use - `orderBy` just makes the choice deterministic
  /// if more than one somehow lingers.
  Future<int?> getActiveDraftPlanSessionId() async {
    final draft =
        await (select(sessionLogs)
              ..where(
                (l) => l.finishedAt.isNull() & l.planSessionId.isNotNull(),
              )
              ..orderBy([(l) => OrderingTerm.desc(l.loggedAt)])
              ..limit(1))
            .getSingleOrNull();
    return draft?.planSessionId;
  }

  /// Every weight ever logged for this exercise, for PR checks - the caller
  /// feeds this to [isPersonalRecord] alongside the new set's weight. Joins
  /// sessionLogs (unlike most single-table lookups) purely to exclude an
  /// autosaved draft's sets - a set only checked off in a session that was
  /// never actually finished shouldn't count toward a real PR.
  Future<List<double>> getPriorWeights(String exerciseId) async {
    final query = select(loggedSets).join([
      innerJoin(
        sessionLogs,
        sessionLogs.id.equalsExp(loggedSets.sessionLogId),
      ),
    ])
      ..where(
        loggedSets.exerciseId.equals(exerciseId) &
            loggedSets.weight.isNotNull() &
            sessionLogs.finishedAt.isNotNull(),
      );
    final rows = await query.get();
    return rows.map((r) => r.readTable(loggedSets).weight!).toList();
  }

  /// Every set logged for this exercise in the single most recent session
  /// that logged it - the full breakdown (not reduced to one top set the
  /// way [getProgressionHistory] is), for showing "what did I actually do
  /// last time" while logging the same exercise again. Ordered by set
  /// number. Empty if the exercise has never been logged.
  Future<List<LoggedSet>> getLastLoggedSets(String exerciseId) async {
    final query = select(loggedSets).join([
      innerJoin(
        sessionLogs,
        sessionLogs.id.equalsExp(loggedSets.sessionLogId),
      ),
    ])
      ..where(
        loggedSets.exerciseId.equals(exerciseId) &
            sessionLogs.finishedAt.isNotNull(),
      )
      ..orderBy([OrderingTerm.desc(sessionLogs.loggedAt)]);
    final rows = await query.get();
    if (rows.isEmpty) return [];

    final mostRecentLogId = rows.first.readTable(sessionLogs).id;
    final sets =
        rows
            .where((r) => r.readTable(sessionLogs).id == mostRecentLogId)
            .map((r) => r.readTable(loggedSets))
            .toList()
          ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
    return sets;
  }

  /// Per-session history for a timed or distance exercise (a plank, a
  /// carry), or null when it has none. Time wins if an exercise somehow has
  /// both. [MeasuredHistoryEntry.best] is the longest hold or furthest set
  /// that session; [MeasuredHistoryEntry.total] adds them up.
  Future<MeasuredHistory?> getMeasuredHistory(String exerciseId) async {
    final rows =
        await (select(loggedSets).join([
              innerJoin(
                sessionLogs,
                sessionLogs.id.equalsExp(loggedSets.sessionLogId),
              ),
            ])..where(
              loggedSets.exerciseId.equals(exerciseId) &
                  sessionLogs.finishedAt.isNotNull() &
                  (loggedSets.durationSec.isNotNull() |
                      loggedSets.distance.isNotNull()),
            ))
            .get();
    if (rows.isEmpty) return null;

    final isTime = rows.any(
      (r) => r.readTable(loggedSets).durationSec != null,
    );
    double? valueOf(TypedResult r) {
      final set = r.readTable(loggedSets);
      return isTime ? set.durationSec : set.distance;
    }

    final bySession = <String, List<TypedResult>>{};
    for (final row in rows.where((r) => valueOf(r) != null)) {
      bySession.putIfAbsent(row.readTable(sessionLogs).id, () => []).add(row);
    }
    final entries = [
      for (final sets in bySession.values)
        MeasuredHistoryEntry(
          date: sets.first.readTable(sessionLogs).loggedAt,
          best: sets.map((r) => valueOf(r)!).reduce((a, b) => a > b ? a : b),
          total: sets.map((r) => valueOf(r)!).fold(0.0, (a, b) => a + b),
          setCount: sets.length,
        ),
    ]..sort((a, b) => a.date.compareTo(b.date));
    return MeasuredHistory(
      measure: isTime ? SetMeasure.time : SetMeasure.distance,
      entries: entries,
    );
  }

  /// One entry per session that logged this exercise with no weight at all
  /// (bodyweight/band/Time-type exercises - e.g. a resistance-band warm-up),
  /// reduced to that session's total reps across every set. There's no
  /// weight axis to reduce onto the way [getProgressionHistory] does, so
  /// "total reps that session" is used instead of a single top set - the
  /// most honest simple stand-in for "did more work than last time" without
  /// inventing progression math ([suggestNextSet] and PR detection stay
  /// weight-only; see their own doc comments for why).
  Future<List<RepsHistoryEntry>> getRepsOnlyHistory(String exerciseId) async {
    final query = select(loggedSets).join([
      innerJoin(
        sessionLogs,
        sessionLogs.id.equalsExp(loggedSets.sessionLogId),
      ),
    ])
      ..where(
        loggedSets.exerciseId.equals(exerciseId) &
            loggedSets.weight.isNull() &
            loggedSets.reps.isNotNull() &
            sessionLogs.finishedAt.isNotNull(),
      );
    final rows = await query.get();

    final bySession = <String, List<TypedResult>>{};
    for (final row in rows) {
      final sessionId = row.readTable(sessionLogs).id;
      bySession.putIfAbsent(sessionId, () => []).add(row);
    }

    return bySession.values.map((setsInSession) {
      final totalReps = setsInSession
          .map((r) => r.readTable(loggedSets).reps!)
          .fold(0, (a, b) => a + b);
      return RepsHistoryEntry(
        date: setsInSession.first.readTable(sessionLogs).loggedAt,
        totalReps: totalReps,
        setCount: setsInSession.length,
      );
    }).toList();
  }

  /// One entry per session that logged this exercise, reduced to that
  /// session's top (heaviest) working weight - the shape [suggestNextSet]
  /// wants. Only weight-based sets are considered; Time/Distance-measured
  /// exercises aren't covered by progression suggestions yet (see
  /// [getRepsOnlyHistory] for those instead).
  ///
  /// When a session has multiple sets at that same top weight (the normal
  /// case - e.g. 3 sets of 8 at 60kg), [ProgressionHistoryEntry.reps] is the
  /// *fewest* reps among them, not an arbitrary one. The suggestion logic's
  /// "did you actually beat your target" question should be answered by the
  /// hardest set at that weight, not the easiest - taking the best of the
  /// three would let one lucky set on an otherwise-failed day look like a
  /// clean success. [ProgressionHistoryEntry.rpe] is the *highest* RPE among
  /// those same sets for the same reason (the most-fatigued set is the more
  /// honest signal), when any of them recorded one.
  Future<List<ProgressionHistoryEntry>> getProgressionHistory(
    String exerciseId,
  ) async {
    final query = select(loggedSets).join([
      innerJoin(
        sessionLogs,
        sessionLogs.id.equalsExp(loggedSets.sessionLogId),
      ),
    ])
      ..where(
        loggedSets.exerciseId.equals(exerciseId) &
            loggedSets.weight.isNotNull() &
            loggedSets.reps.isNotNull() &
            sessionLogs.finishedAt.isNotNull(),
      );
    final rows = await query.get();

    final bySession = <String, List<TypedResult>>{};
    for (final row in rows) {
      final sessionId = row.readTable(sessionLogs).id;
      bySession.putIfAbsent(sessionId, () => []).add(row);
    }

    return bySession.values.map((setsInSession) {
      final topWeight = setsInSession
          .map((r) => r.readTable(loggedSets).weight!)
          .reduce((a, b) => a > b ? a : b);
      final atTopWeight = setsInSession
          .where((r) => r.readTable(loggedSets).weight! == topWeight)
          .toList();
      final hardestReps = atTopWeight
          .map((r) => r.readTable(loggedSets).reps!)
          .reduce((a, b) => a < b ? a : b);
      final recordedRpes = atTopWeight
          .map((r) => r.readTable(loggedSets).rpe)
          .whereType<double>()
          .toList();
      final highestRpe = recordedRpes.isEmpty
          ? null
          : recordedRpes.reduce((a, b) => a > b ? a : b);
      return ProgressionHistoryEntry(
        date: setsInSession.first.readTable(sessionLogs).loggedAt,
        weight: topWeight,
        reps: hardestReps,
        rpe: highestRpe,
      );
    }).toList();
  }

  Future<List<LoggedSet>> getLoggedSetsForSessionLog(String sessionLogId) {
    return (select(
      loggedSets,
    )..where((s) => s.sessionLogId.equals(sessionLogId))).get();
  }

  /// All logs for a specific scheduled session (Week+Day+Session Name
  /// instance), most recent first.
  Future<List<SessionLog>> getLogsForPlanSession(int planSessionId) {
    return (select(sessionLogs)
          ..where(
            (s) =>
                s.planSessionId.equals(planSessionId) &
                s.finishedAt.isNotNull(),
          )
          ..orderBy([(s) => OrderingTerm.desc(s.loggedAt)]))
        .get();
  }

  /// Deletes every log (and its logged sets) for one scheduled session,
  /// children before parents - same reasoning as [MaintenanceDao.wipeAllData]:
  /// must not assume SQLite's foreign_keys pragma is on. Used by Phase 5's
  /// plan sync when replacing a plan's sessions, so a fresh session log
  /// insert under a reused id doesn't collide with an orphaned old row.
  Future<void> deleteLogsForPlanSession(int planSessionId) {
    return transaction(() async {
      final logIds = await (select(
        sessionLogs,
      )..where((l) => l.planSessionId.equals(planSessionId))).map((l) => l.id).get();
      await (delete(loggedSets)..where((s) => s.sessionLogId.isIn(logIds))).go();
      await (delete(
        skippedExercises,
      )..where((s) => s.sessionLogId.isIn(logIds))).go();
      await (delete(
        sessionLogs,
      )..where((l) => l.planSessionId.equals(planSessionId))).go();
    });
  }

  /// How many times each `PlanSessions` id has been logged, broken down by
  /// the calendar day each log actually happened on - lets the calendar mark
  /// a *specific date* as completed rather than the session id as a whole.
  ///
  /// This distinction matters once a session can be moved to a new date
  /// after already being logged: `PlanSessions.assignedDate` is a single
  /// mutable column, not a history of every date the session has ever sat
  /// on, so reassigning it doesn't create a fresh not-yet-done slot - the
  /// same row (and, before this, the same "has it ever been logged, at all"
  /// bit) just relocates to the new date. Moving an already-completed
  /// session to next month would otherwise make next month's occurrence show
  /// as already done, with no way to start it from the calendar at all.
  /// Keying by (session id, day) instead means a session only reads as done
  /// on a day it was actually logged on - moving it to an unlogged date
  /// correctly shows that date as not-yet-done.
  Future<Map<int, Map<DateTime, int>>> getLoggedPlanSessionCounts() async {
    final query = selectOnly(sessionLogs)
      ..addColumns([sessionLogs.planSessionId, sessionLogs.loggedAt])
      ..where(
        sessionLogs.planSessionId.isNotNull() &
            sessionLogs.finishedAt.isNotNull(),
      );
    final rows = await query.get();
    final counts = <int, Map<DateTime, int>>{};
    for (final row in rows) {
      final id = row.read(sessionLogs.planSessionId);
      if (id == null) continue;
      final loggedAt = row.read(sessionLogs.loggedAt)!;
      final day = DateTime(loggedAt.year, loggedAt.month, loggedAt.day);
      final byDay = counts.putIfAbsent(id, () => {});
      byDay[day] = (byDay[day] ?? 0) + 1;
    }
    return counts;
  }

  /// Every ad-hoc activity (a walk/run/etc. logged directly against a date,
  /// not a scheduled plan session) - the calendar groups these by
  /// [SessionLog.loggedAt] itself rather than an `assignedDate`, since
  /// there's no [PlanSession] row to carry one.
  Future<List<SessionLog>> getAdHocActivities() {
    return (select(sessionLogs)..where(
          (l) => l.planSessionId.isNull() & l.finishedAt.isNotNull(),
        ))
        .get();
  }

  /// Every distinct calendar day anything has ever been logged on - a
  /// scheduled session or an ad-hoc activity both count. Backs the Progress
  /// tab's streak card (`lib/logic/streaks.dart`), which looks at contiguous
  /// history rather than one period in isolation, unlike [getPeriodSummary]'s
  /// range-scoped queries.
  Future<List<DateTime>> getAllLoggedDays() async {
    final query = selectOnly(sessionLogs)
      ..addColumns([sessionLogs.loggedAt])
      ..where(sessionLogs.finishedAt.isNotNull());
    final rows = await query.get();
    final days = <DateTime>{};
    for (final row in rows) {
      final loggedAt = row.read(sessionLogs.loggedAt)!;
      days.add(DateTime(loggedAt.year, loggedAt.month, loggedAt.day));
    }
    return days.toList();
  }

  /// Adherence/volume/PR counts for the half-open range [start, end) - the
  /// data behind the Progress tab's week/month overview summary.
  ///
  /// "Scheduled" counts (session, date) *occurrences* in range, not distinct
  /// sessions - a session scheduled on 3 dates this week contributes 3, not
  /// 1, matching how the calendar's own completion tracking already counts
  /// per-occurrence rather than per-session (see `getLoggedPlanSessionCounts`
  /// below). "Completed" counts how many of those specific occurrences were
  /// actually logged on their own scheduled day - not just "was this session
  /// logged at all somewhere in range" - for the same reason moving an
  /// already-completed session's date mustn't carry its old completion
  /// forward: a log only counts against the occurrence it was actually
  /// trained on.
  Future<PeriodSummary> getPeriodSummary({
    required DateTime start,
    required DateTime end,
  }) async {
    final scheduledQuery = select(planSessionDates)
      ..where(
        (d) =>
            d.date.isBiggerOrEqualValue(start) &
            d.date.isSmallerThanValue(end),
      );
    final occurrences = await scheduledQuery.get();

    final logsQuery = select(sessionLogs)
      ..where(
        (l) =>
            l.loggedAt.isBiggerOrEqualValue(start) &
            l.loggedAt.isSmallerThanValue(end) &
            l.finishedAt.isNotNull(),
      );
    final logsInPeriod = await logsQuery.get();
    final loggedDaysBySession = <int, Set<DateTime>>{};
    for (final log in logsInPeriod) {
      final sessionId = log.planSessionId;
      if (sessionId == null) continue;
      final day = DateTime(
        log.loggedAt.year,
        log.loggedAt.month,
        log.loggedAt.day,
      );
      loggedDaysBySession.putIfAbsent(sessionId, () => {}).add(day);
    }
    final completedOccurrences = occurrences.where((o) {
      final day = DateTime(o.date.year, o.date.month, o.date.day);
      return loggedDaysBySession[o.sessionId]?.contains(day) ?? false;
    }).length;

    var totalVolume = 0.0;
    var prCount = 0;
    // Reps logged on a set with no weight at all (bodyweight/band/Time-type
    // exercises) contribute nothing to totalVolume above - weight × reps
    // isn't meaningful without a weight - so without this they were
    // invisible in the period summary entirely, even though real work was
    // done. Tracked as its own tally rather than folded into totalVolume,
    // since kilograms and bare reps aren't the same unit.
    var nonWeightedReps = 0;
    for (final log in logsInPeriod) {
      final sets = await getLoggedSetsForSessionLog(log.id);
      for (final s in sets) {
        if (s.weight != null && s.reps != null) {
          totalVolume += s.weight! * s.reps!;
        } else if (s.weight == null && s.reps != null) {
          nonWeightedReps += s.reps!;
        }
        if (s.isPr) prCount++;
      }
    }

    // Ad-hoc activities (walks/runs/etc.) have zero LoggedSets rows, so they
    // never contributed anything to totalVolume/prCount above - previously
    // they were entirely invisible in the Progress tab and its shared
    // summary, even though they show up in Workout History and the
    // calendar. Reuses logsInPeriod (already fetched) rather than a second
    // query.
    final adHocActivities = logsInPeriod
        .where((l) => l.planSessionId == null)
        .toList();
    final adHocDurationSec = adHocActivities.fold<double>(
      0,
      (sum, l) => sum + (l.durationSec ?? 0),
    );
    final adHocDistanceMeters = adHocActivities.fold<double>(
      0,
      (sum, l) => sum + (l.distance ?? 0),
    );

    return PeriodSummary(
      sessionsScheduled: occurrences.length,
      adHocActivityCount: adHocActivities.length,
      adHocDurationSec: adHocDurationSec,
      adHocDistanceMeters: adHocDistanceMeters,
      sessionsCompleted: completedOccurrences,
      totalVolume: totalVolume,
      prCount: prCount,
      nonWeightedReps: nonWeightedReps,
    );
  }

  /// One entry per exercise with at least one real (finished) set logged in
  /// [start, end) - its raw `muscleGroups` text plus how many sets it got -
  /// feeding `lib/logic/muscle_group_volume.dart`'s `tallyMuscleGroupVolume()`
  /// for the Progress tab's "This week's sets by muscle group" card. Kept as
  /// flat, unaggregated data rather than doing the muscle-group splitting/
  /// tallying here, matching this project's `lib/logic/` DB-free-pure-logic
  /// convention - the actual per-muscle-group counting is unit-tested there,
  /// not against a live database.
  Future<List<({String muscleGroupsRaw, int setsLogged})>>
  getSetCountsByExercise({required DateTime start, required DateTime end}) async {
    final query = select(loggedSets).join([
      innerJoin(
        sessionLogs,
        sessionLogs.id.equalsExp(loggedSets.sessionLogId),
      ),
      innerJoin(exercises, exercises.id.equalsExp(loggedSets.exerciseId)),
    ])..where(
      sessionLogs.finishedAt.isNotNull() &
          sessionLogs.loggedAt.isBiggerOrEqualValue(start) &
          sessionLogs.loggedAt.isSmallerThanValue(end),
    );
    final rows = await query.get();

    final setCounts = <String, int>{};
    final muscleGroupsByExercise = <String, String>{};
    for (final row in rows) {
      final exerciseId = row.readTable(loggedSets).exerciseId;
      setCounts[exerciseId] = (setCounts[exerciseId] ?? 0) + 1;
      muscleGroupsByExercise[exerciseId] = row
          .readTable(exercises)
          .muscleGroups;
    }

    return [
      for (final exerciseId in setCounts.keys)
        (
          muscleGroupsRaw: muscleGroupsByExercise[exerciseId]!,
          setsLogged: setCounts[exerciseId]!,
        ),
    ];
  }

  /// One completed workout with every set, plus the exercise names, ready to
  /// display. Grouped by exercise in the order the sets were recorded, which
  /// is the order they were actually performed.
  Future<CompletedWorkout?> getCompletedWorkout(String sessionLogId) async {
    final log = await (select(sessionLogs)..where(
          (l) => l.id.equals(sessionLogId) & l.finishedAt.isNotNull(),
        ))
        .getSingleOrNull();
    if (log == null) return null;

    // Null for an ad-hoc activity - it has no plan session to look up.
    final planSessionId = log.planSessionId;
    final session = planSessionId == null
        ? null
        : await (select(
            planSessions,
          )..where((s) => s.id.equals(planSessionId))).getSingleOrNull();

    // Who this workout's plan was created by (e.g. a trainer's name, see
    // Plans.createdBy) - lets a multi-plan report (the Progress tab's
    // export spans whatever's logged in the date range, not one plan) show
    // the trainer's name in its header when every workout in range traces
    // back to the same one. Null for an ad-hoc activity, an exercise added
    // mid-session with no session at all, or a plan nobody set this on.
    final planCreatedBy = session == null
        ? null
        : (await (select(
                plans,
              )..where((p) => p.id.equals(session.planId))).getSingleOrNull())
              ?.createdBy;

    final sets = await (select(loggedSets)
          ..where((s) => s.sessionLogId.equals(sessionLogId))
          ..orderBy([(s) => OrderingTerm.asc(s.id)]))
        .get();

    final names = <String, String>{};
    for (final row in await select(db.exercises).get()) {
      names[row.id] = row.name;
    }

    final grouped = <String, List<LoggedSet>>{};
    for (final set in sets) {
      grouped.putIfAbsent(set.exerciseId, () => []).add(set);
    }

    // What the plan actually prescribed for this exercise in this session -
    // alongside [sets] (what was actually logged), this is what lets a
    // trainer-facing report show prescribed vs. actual side by side instead
    // of just the raw sets on their own. Null for an ad-hoc activity (no
    // plan session at all) or an exercise added mid-session that was never
    // part of the plan template to begin with. Keyed by exerciseId - the
    // rare case of the same exercise appearing twice in one session's
    // template (e.g. as two different superset members) just keeps
    // whichever row's map insertion wins, since there's no per-set way to
    // tell which prescribed row a given logged set was actually answering.
    final prescriptionByExerciseId = <String, PlanExercise>{};
    if (planSessionId != null) {
      final prescribed = await (select(
        planExercises,
      )..where((e) => e.sessionId.equals(planSessionId))).get();
      for (final row in prescribed) {
        if (row.exerciseId != null) {
          prescriptionByExerciseId[row.exerciseId!] = row;
        }
      }
    }

    final skipped = await getSkippedForSessionLog(sessionLogId);
    final substituteFor = <String, String>{
      for (final s in skipped)
        if (s.replacedByExerciseId != null)
          s.replacedByExerciseId!: s.exerciseName,
    };

    return CompletedWorkout(
      log: log,
      sessionName: session?.sessionName ?? log.activityName ?? 'Workout',
      planCreatedBy: planCreatedBy,
      exercises: [
        for (final entry in grouped.entries)
          CompletedExercise(
            exerciseId: entry.key,
            exerciseName: names[entry.key] ?? entry.key,
            sets: entry.value,
            prescription: prescriptionByExerciseId[entry.key],
            substituteFor: substituteFor[entry.key],
          ),
      ],
      skipped: skipped,
    );
  }

  /// Every completed workout in [start, end), each with its full exercise/set
  /// breakdown - the data behind the Progress tab's "detailed log" export
  /// (see `progress_report_pdf.dart`'s `fullLog`), as opposed to
  /// [getWorkoutHistory]'s flat summary rows or [getPeriodSummary]'s
  /// aggregate counts. Same N+1-per-log shape as [getWorkoutHistory]/
  /// [getPeriodSummary] already use - simplicity over a single mega-query,
  /// consistent with the rest of this DAO.
  Future<List<CompletedWorkout>> getCompletedWorkoutsInRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final logs = await (select(sessionLogs)
          ..where(
            (l) =>
                l.finishedAt.isNotNull() &
                l.loggedAt.isBiggerOrEqualValue(start) &
                l.loggedAt.isSmallerThanValue(end),
          )
          ..orderBy([(l) => OrderingTerm.asc(l.loggedAt)]))
        .get();

    final result = <CompletedWorkout>[];
    for (final log in logs) {
      final workout = await getCompletedWorkout(log.id);
      if (workout != null) result.add(workout);
    }
    return result;
  }

  /// Every completed workout, newest first - the history list.
  /// [start]/[end] scope this to a date range (matching every other
  /// range-scoped query's half-open [start, end) convention) instead of the
  /// whole database - both null (the default) preserves the original
  /// all-time behaviour every existing caller relies on. [adHocOnly] narrows
  /// to just the walks/runs/etc. with no plan session, for a view scoped to
  /// what the Progress tab's activity chips themselves summarize.
  Future<List<CompletedWorkoutSummary>> getWorkoutHistory({
    DateTime? start,
    DateTime? end,
    bool adHocOnly = false,
  }) async {
    final logs = await (select(sessionLogs)
          ..where((l) {
            Expression<bool> condition = l.finishedAt.isNotNull();
            if (start != null) {
              condition = condition & l.loggedAt.isBiggerOrEqualValue(start);
            }
            if (end != null) {
              condition = condition & l.loggedAt.isSmallerThanValue(end);
            }
            if (adHocOnly) {
              condition = condition & l.planSessionId.isNull();
            }
            return condition;
          })
          ..orderBy([(l) => OrderingTerm.desc(l.loggedAt)]))
        .get();
    if (logs.isEmpty) return [];

    final sessions = {
      for (final s in await select(planSessions).get()) s.id: s,
    };

    final result = <CompletedWorkoutSummary>[];
    for (final log in logs) {
      final sets = await getLoggedSetsForSessionLog(log.id);
      var volume = 0.0;
      for (final s in sets) {
        if (s.weight != null && s.reps != null) volume += s.weight! * s.reps!;
      }
      result.add(
        CompletedWorkoutSummary(
          logId: log.id,
          loggedAt: log.loggedAt,
          sessionName:
              sessions[log.planSessionId]?.sessionName ??
              log.activityName ??
              'Workout',
          setCount: sets.length,
          volume: volume,
          prCount: sets.where((s) => s.isPr).length,
          isAdHocActivity: log.planSessionId == null,
          durationSec: log.durationSec,
          distance: log.distance,
        ),
      );
    }
    return result;
  }

  /// Updates one already-logged set's reps/weight/rpe in place - a genuine
  /// partial `update()`, never `insertOnConflictUpdate` (see this file's own
  /// DAO convention on why). Closes a real gap: once a session was
  /// finished, the only way to correct a mistyped value (e.g. the wrong rep
  /// count) was deleting the entire workout and redoing it from scratch.
  /// Deliberately never touches `isPr` - recomputing personal-record status
  /// after an edit would mean re-evaluating every *later* session's own PR
  /// too (a value that was a PR might no longer be after editing it down,
  /// or a newly-higher one might newly qualify), which is out of scope for
  /// a single-set correction. `null` for any parameter clears that column,
  /// matching how the edit dialog treats an emptied field.
  Future<void> updateLoggedSet({
    required int id,
    int? reps,
    double? weight,
    double? rpe,
    double? durationSec,
    double? distance,
  }) {
    return (update(loggedSets)..where((s) => s.id.equals(id))).write(
      LoggedSetsCompanion(
        reps: Value(reps),
        weight: Value(weight),
        rpe: Value(rpe),
        durationSec: Value(durationSec),
        distance: Value(distance),
      ),
    );
  }

  /// Edits the whole-session note after the fact; null or blank clears it.
  Future<void> updateSessionLogNotes(String sessionLogId, String? notes) {
    final value = notes == null || notes.trim().isEmpty ? null : notes.trim();
    return (update(sessionLogs)..where((l) => l.id.equals(sessionLogId)))
        .write(SessionLogsCompanion(notes: Value(value)));
  }

  /// Edits a trainee note on one set (an exercise's note lives on one of
  /// its sets - see `LoggedSets.notes`); null or blank clears it.
  Future<void> updateLoggedSetNotes(int loggedSetId, String? notes) {
    final value = notes == null || notes.trim().isEmpty ? null : notes.trim();
    return (update(loggedSets)..where((s) => s.id.equals(loggedSetId)))
        .write(LoggedSetsCompanion(notes: Value(value)));
  }

  /// Deletes one completed workout and its sets - children before parents,
  /// since this project's connections don't enforce foreign keys.
  Future<void> deleteSessionLog(String sessionLogId) {
    return transaction(() async {
      await (delete(
        loggedSets,
      )..where((s) => s.sessionLogId.equals(sessionLogId))).go();
      await (delete(
        skippedExercises,
      )..where((s) => s.sessionLogId.equals(sessionLogId))).go();
      await (delete(sessionLogs)..where((l) => l.id.equals(sessionLogId))).go();
    });
  }

  /// Per-day totals across [start, end) - the series behind the Progress
  /// tab's trend charts. Days with no logged work are omitted; the caller
  /// decides whether to render gaps or a continuous line.
  Future<List<DailyTotals>> getDailyTotals({
    required DateTime start,
    required DateTime end,
  }) async {
    final query = select(loggedSets).join([
      innerJoin(
        sessionLogs,
        sessionLogs.id.equalsExp(loggedSets.sessionLogId),
      ),
    ])..where(
      sessionLogs.loggedAt.isBiggerOrEqualValue(start) &
          sessionLogs.loggedAt.isSmallerThanValue(end) &
          sessionLogs.finishedAt.isNotNull(),
    );
    final rows = await query.get();

    final byDay = <DateTime, List<TypedResult>>{};
    for (final row in rows) {
      final loggedAt = row.readTable(sessionLogs).loggedAt;
      final day = DateTime(loggedAt.year, loggedAt.month, loggedAt.day);
      byDay.putIfAbsent(day, () => []).add(row);
    }

    final result = <DailyTotals>[];
    for (final entry in byDay.entries) {
      var volume = 0.0;
      var sets = 0;
      var reps = 0;
      var prs = 0;
      final sessionIds = <String>{};
      for (final row in entry.value) {
        final set = row.readTable(loggedSets);
        sets++;
        if (set.reps != null) reps += set.reps!;
        if (set.weight != null && set.reps != null) {
          volume += set.weight! * set.reps!;
        }
        if (set.isPr) prs++;
        sessionIds.add(row.readTable(sessionLogs).id);
      }
      result.add(
        DailyTotals(
          day: entry.key,
          volume: volume,
          sets: sets,
          reps: reps,
          prs: prs,
          sessions: sessionIds.length,
        ),
      );
    }
    result.sort((a, b) => a.day.compareTo(b.day));
    return result;
  }

  /// The most recent logged set for every exercise that has any reps-based
  /// history - the Progress tab's cross-exercise dashboard. An exercise
  /// whose latest session has a weight on at least one set is reduced to
  /// that session's top (heaviest) set, same as before; an exercise with no
  /// weight at all that session (bodyweight/band/Time-type - e.g. Hip
  /// Circles) instead gets [ExerciseProgressSummary.topWeight] left null and
  /// [ExerciseProgressSummary.topReps] set to that session's *total* reps
  /// across all its sets - there's no weight to reduce onto a single "top"
  /// set the way there is for a weighted exercise. Previously this query
  /// required both weight and reps, which meant a no-weight exercise never
  /// appeared in the dashboard at all, however consistently it was actually
  /// trained.
  Future<List<ExerciseProgressSummary>> getLatestTopSetPerExercise() async {
    final query = select(loggedSets).join([
      innerJoin(
        sessionLogs,
        sessionLogs.id.equalsExp(loggedSets.sessionLogId),
      ),
    ])..where(
      (loggedSets.reps.isNotNull() |
              loggedSets.durationSec.isNotNull() |
              loggedSets.distance.isNotNull()) &
          sessionLogs.finishedAt.isNotNull(),
    );
    final rows = await query.get();

    final byExercise = <String, List<TypedResult>>{};
    for (final row in rows) {
      final exerciseId = row.readTable(loggedSets).exerciseId;
      byExercise.putIfAbsent(exerciseId, () => []).add(row);
    }

    final result = <ExerciseProgressSummary>[];
    for (final entry in byExercise.entries) {
      final rowsForExercise = entry.value;
      final latestDate = rowsForExercise
          .map((r) => r.readTable(sessionLogs).loggedAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final rowsInLatestSession = rowsForExercise
          .where((r) => r.readTable(sessionLogs).loggedAt == latestDate)
          .toList();
      final weightedRows = rowsInLatestSession
          .where(
            (r) =>
                r.readTable(loggedSets).weight != null &&
                r.readTable(loggedSets).reps != null,
          )
          .toList();
      final repRows = rowsInLatestSession
          .where((r) => r.readTable(loggedSets).reps != null)
          .toList();

      if (weightedRows.isEmpty && repRows.isEmpty) {
        // A hold or a carry: summarized by its best time, else distance.
        final timed = rowsInLatestSession
            .where((r) => r.readTable(loggedSets).durationSec != null)
            .toList();
        final measured = timed.isNotEmpty ? timed : rowsInLatestSession;
        double valueOf(TypedResult r) => timed.isNotEmpty
            ? r.readTable(loggedSets).durationSec!
            : r.readTable(loggedSets).distance!;
        final best = measured.reduce((a, b) => valueOf(a) >= valueOf(b) ? a : b);
        result.add(
          ExerciseProgressSummary(
            exerciseId: entry.key,
            lastLoggedAt: latestDate,
            topWeight: best.readTable(loggedSets).weight,
            topReps: 0,
            isPr: false,
            topDurationSec: timed.isNotEmpty ? valueOf(best) : null,
            topDistance: timed.isNotEmpty ? null : valueOf(best),
          ),
        );
      } else if (weightedRows.isNotEmpty) {
        final topSet = weightedRows.reduce(
          (a, b) =>
              a.readTable(loggedSets).weight! >=
                  b.readTable(loggedSets).weight!
              ? a
              : b,
        );
        result.add(
          ExerciseProgressSummary(
            exerciseId: entry.key,
            lastLoggedAt: latestDate,
            topWeight: topSet.readTable(loggedSets).weight!,
            topReps: topSet.readTable(loggedSets).reps!,
            isPr: topSet.readTable(loggedSets).isPr,
          ),
        );
      } else {
        final totalReps = repRows
            .map((r) => r.readTable(loggedSets).reps!)
            .fold(0, (a, b) => a + b);
        result.add(
          ExerciseProgressSummary(
            exerciseId: entry.key,
            lastLoggedAt: latestDate,
            topWeight: null,
            topReps: totalReps,
            isPr: false,
          ),
        );
      }
    }
    result.sort((a, b) => b.lastLoggedAt.compareTo(a.lastLoggedAt));
    return result;
  }

  /// Every session log in the database, each with its sets - what a full
  /// backup needs to round-trip execution history.
  Future<List<SessionLogWithSets>> getAllSessionLogsWithSets() async {
    final logs = await (select(
      sessionLogs,
    )..where((l) => l.finishedAt.isNotNull())).get();
    final result = <SessionLogWithSets>[];
    for (final log in logs) {
      result.add(
        SessionLogWithSets(
          log: log,
          sets: await getLoggedSetsForSessionLog(log.id),
          skipped: await getSkippedForSessionLog(log.id),
        ),
      );
    }
    return result;
  }
}

class SessionLogWithSets {
  final SessionLog log;
  final List<LoggedSet> sets;
  final List<SkippedExercise> skipped;

  const SessionLogWithSets({
    required this.log,
    required this.sets,
    this.skipped = const [],
  });
}

class PeriodSummary {
  final int sessionsScheduled;
  final int sessionsCompleted;
  final double totalVolume;
  final int prCount;

  /// How many ad-hoc activities (walks/runs/etc. - see
  /// `lib/data/tables/session_logs_table.dart`) were logged in this period,
  /// and their combined duration/distance. Zero/0 rather than null when
  /// there were none, matching every other count on this class.
  final int adHocActivityCount;
  final double adHocDurationSec;
  final double adHocDistanceMeters;

  /// Total reps logged in this period on sets with no weight at all
  /// (bodyweight/band/Time-type exercises) - kept separate from
  /// [totalVolume] since kilograms and bare reps aren't the same unit and
  /// summing them would be meaningless. Zero when there were none, matching
  /// every other count on this class.
  final int nonWeightedReps;

  const PeriodSummary({
    required this.sessionsScheduled,
    required this.sessionsCompleted,
    required this.totalVolume,
    required this.prCount,
    this.adHocActivityCount = 0,
    this.adHocDurationSec = 0,
    this.adHocDistanceMeters = 0,
    this.nonWeightedReps = 0,
  });
}

class CompletedWorkout {
  final SessionLog log;
  final String sessionName;
  final List<CompletedExercise> exercises;

  /// See `SessionLogDao.getCompletedWorkout`'s own doc comment for why this
  /// can be null.
  final String? planCreatedBy;

  /// Prescribed exercises skipped in this session, replaced or not.
  final List<SkippedExercise> skipped;

  const CompletedWorkout({
    required this.log,
    required this.sessionName,
    required this.exercises,
    this.planCreatedBy,
    this.skipped = const [],
  });
}

class CompletedExercise {
  final String exerciseId;
  final String exerciseName;
  final List<LoggedSet> sets;

  /// What the plan actually prescribed for this exercise in this session -
  /// see [SessionLogDao.getCompletedWorkout]'s own doc comment for why this
  /// can be null.
  final PlanExercise? prescription;

  /// The name of the skipped exercise this one was done in place of, if any.
  final String? substituteFor;

  const CompletedExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    this.prescription,
    this.substituteFor,
  });
}

class CompletedWorkoutSummary {
  final String logId;
  final DateTime loggedAt;
  final String sessionName;
  final int setCount;
  final double volume;
  final int prCount;
  final bool isAdHocActivity;
  final double? durationSec;
  final double? distance;

  const CompletedWorkoutSummary({
    required this.logId,
    required this.loggedAt,
    required this.sessionName,
    required this.setCount,
    required this.volume,
    required this.prCount,
    this.isAdHocActivity = false,
    this.durationSec,
    this.distance,
  });
}

class DailyTotals {
  final DateTime day;
  final double volume;
  final int sets;
  final int reps;
  final int prs;
  final int sessions;

  const DailyTotals({
    required this.day,
    required this.volume,
    required this.sets,
    required this.reps,
    required this.prs,
    required this.sessions,
  });
}

class ExerciseProgressSummary {
  final String exerciseId;
  final DateTime lastLoggedAt;

  /// Null for an exercise whose latest session logged no weight at all
  /// (bodyweight/band/Time-type) - see [topReps]'s doc comment for what it
  /// means instead in that case.
  final double? topWeight;

  /// The hardest set's reps at [topWeight] when it's non-null; the *total*
  /// reps across every set in the latest session when [topWeight] is null.
  /// These are deliberately different reductions - see
  /// [SessionLogDao.getLatestTopSetPerExercise]'s doc comment for why.
  final int topReps;
  final bool isPr;

  /// For a hold or a carry: the latest session's longest time or furthest
  /// distance, with [topWeight] that set's load (if any) and [topReps] 0.
  final double? topDurationSec;
  final double? topDistance;

  const ExerciseProgressSummary({
    required this.exerciseId,
    required this.lastLoggedAt,
    required this.topWeight,
    required this.topReps,
    required this.isPr,
    this.topDurationSec,
    this.topDistance,
  });
}

/// See [SessionLogDao.getMeasuredHistory].
class MeasuredHistory {
  /// [SetMeasure.time] (values in seconds) or [SetMeasure.distance] (metres).
  final SetMeasure measure;
  final List<MeasuredHistoryEntry> entries;

  const MeasuredHistory({required this.measure, required this.entries});
}

class MeasuredHistoryEntry {
  final DateTime date;
  final double best;
  final double total;
  final int setCount;

  const MeasuredHistoryEntry({
    required this.date,
    required this.best,
    required this.total,
    required this.setCount,
  });
}

/// One past session's total reps for a no-weight exercise (bodyweight/band/
/// Time-type) - the reps-only counterpart to [ProgressionHistoryEntry],
/// which requires a weight. See [SessionLogDao.getRepsOnlyHistory].
class RepsHistoryEntry {
  final DateTime date;
  final int totalReps;
  final int setCount;

  const RepsHistoryEntry({
    required this.date,
    required this.totalReps,
    required this.setCount,
  });
}
