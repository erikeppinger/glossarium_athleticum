import 'package:drift/drift.dart';

import '../../logic/progression.dart';
import '../app_database.dart';
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

  const LoggedSetInput({
    required this.exerciseId,
    required this.setNumber,
    this.reps,
    this.weight,
    this.durationSec,
    this.distance,
    this.rpe,
    this.isPr = false,
  });
}

@DriftAccessor(tables: [SessionLogs, LoggedSets, PlanSessions])
class SessionLogDao extends DatabaseAccessor<AppDatabase>
    with _$SessionLogDaoMixin {
  SessionLogDao(super.db);

  Future<String> createSessionLog({
    required String id,
    required int planSessionId,
    required DateTime loggedAt,
    required List<LoggedSetInput> entries,
  }) {
    return transaction(() async {
      await into(sessionLogs).insert(
        SessionLogsCompanion.insert(
          id: id,
          planSessionId: planSessionId,
          loggedAt: loggedAt,
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
          ),
        );
      }
      return id;
    });
  }

  /// Every weight ever logged for this exercise, for PR checks - the caller
  /// feeds this to [isPersonalRecord] alongside the new set's weight.
  Future<List<double>> getPriorWeights(String exerciseId) async {
    final query = select(loggedSets)
      ..where(
        (s) => s.exerciseId.equals(exerciseId) & s.weight.isNotNull(),
      );
    final rows = await query.get();
    return rows.map((r) => r.weight!).toList();
  }

  /// One entry per session that logged this exercise, reduced to that
  /// session's top set (highest weight) - the shape [suggestNextSet] wants.
  /// Only weight-based sets are considered; Time/Distance-measured exercises
  /// aren't covered by progression suggestions yet.
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
            loggedSets.reps.isNotNull(),
      );
    final rows = await query.get();

    final bySession = <String, List<TypedResult>>{};
    for (final row in rows) {
      final sessionId = row.readTable(sessionLogs).id;
      bySession.putIfAbsent(sessionId, () => []).add(row);
    }

    return bySession.values.map((setsInSession) {
      final topSet = setsInSession.reduce((a, b) {
        final aWeight = a.readTable(loggedSets).weight!;
        final bWeight = b.readTable(loggedSets).weight!;
        return aWeight >= bWeight ? a : b;
      });
      return ProgressionHistoryEntry(
        date: topSet.readTable(sessionLogs).loggedAt,
        weight: topSet.readTable(loggedSets).weight!,
        reps: topSet.readTable(loggedSets).reps!,
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
          ..where((s) => s.planSessionId.equals(planSessionId))
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
        sessionLogs,
      )..where((l) => l.planSessionId.equals(planSessionId))).go();
    });
  }

  /// Every `PlanSessions` id that has at least one logged workout - lets the
  /// calendar mark scheduled days as completed without loading full log data.
  Future<Set<int>> getLoggedPlanSessionIds() async {
    final query = selectOnly(sessionLogs)
      ..addColumns([sessionLogs.planSessionId]);
    final rows = await query.get();
    return rows.map((r) => r.read(sessionLogs.planSessionId)!).toSet();
  }

  /// Adherence/volume/PR counts for the half-open range [start, end) - the
  /// data behind the Progress tab's week/month overview summary.
  Future<PeriodSummary> getPeriodSummary({
    required DateTime start,
    required DateTime end,
  }) async {
    final scheduledQuery = selectOnly(planSessions)
      ..addColumns([planSessions.id])
      ..where(
        planSessions.assignedDate.isBiggerOrEqualValue(start) &
            planSessions.assignedDate.isSmallerThanValue(end),
      );
    final scheduledIds = (await scheduledQuery.get())
        .map((r) => r.read(planSessions.id)!)
        .toSet();

    final logsQuery = select(sessionLogs)
      ..where(
        (l) =>
            l.loggedAt.isBiggerOrEqualValue(start) &
            l.loggedAt.isSmallerThanValue(end),
      );
    final logsInPeriod = await logsQuery.get();
    final completedSessionIds = logsInPeriod.map((l) => l.planSessionId).toSet();

    var totalVolume = 0.0;
    var prCount = 0;
    for (final log in logsInPeriod) {
      final sets = await getLoggedSetsForSessionLog(log.id);
      for (final s in sets) {
        if (s.weight != null && s.reps != null) {
          totalVolume += s.weight! * s.reps!;
        }
        if (s.isPr) prCount++;
      }
    }

    return PeriodSummary(
      sessionsScheduled: scheduledIds.length,
      sessionsCompleted: completedSessionIds.intersection(scheduledIds).length,
      totalVolume: totalVolume,
      prCount: prCount,
    );
  }

  /// One completed workout with every set, plus the exercise names, ready to
  /// display. Grouped by exercise in the order the sets were recorded, which
  /// is the order they were actually performed.
  Future<CompletedWorkout?> getCompletedWorkout(String sessionLogId) async {
    final log = await (select(
      sessionLogs,
    )..where((l) => l.id.equals(sessionLogId))).getSingleOrNull();
    if (log == null) return null;

    final session = await (select(
      planSessions,
    )..where((s) => s.id.equals(log.planSessionId))).getSingleOrNull();

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

    return CompletedWorkout(
      log: log,
      sessionName: session?.sessionName ?? 'Workout',
      exercises: [
        for (final entry in grouped.entries)
          CompletedExercise(
            exerciseId: entry.key,
            exerciseName: names[entry.key] ?? entry.key,
            sets: entry.value,
          ),
      ],
    );
  }

  /// Every completed workout, newest first - the history list.
  Future<List<CompletedWorkoutSummary>> getWorkoutHistory() async {
    final logs = await (select(sessionLogs)
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
          sessionName: sessions[log.planSessionId]?.sessionName ?? 'Workout',
          setCount: sets.length,
          volume: volume,
          prCount: sets.where((s) => s.isPr).length,
        ),
      );
    }
    return result;
  }

  /// Deletes one completed workout and its sets - children before parents,
  /// since this project's connections don't enforce foreign keys.
  Future<void> deleteSessionLog(String sessionLogId) {
    return transaction(() async {
      await (delete(
        loggedSets,
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
          sessionLogs.loggedAt.isSmallerThanValue(end),
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

  /// The most recent logged top (heaviest) set for every exercise that has
  /// weight-based history - the Progress tab's cross-exercise dashboard.
  /// Same weight-only scope limitation as [getProgressionHistory].
  Future<List<ExerciseProgressSummary>> getLatestTopSetPerExercise() async {
    final query = select(loggedSets).join([
      innerJoin(
        sessionLogs,
        sessionLogs.id.equalsExp(loggedSets.sessionLogId),
      ),
    ])..where(loggedSets.weight.isNotNull() & loggedSets.reps.isNotNull());
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
      final rowsInLatestSession = rowsForExercise.where(
        (r) => r.readTable(sessionLogs).loggedAt == latestDate,
      );
      final topSet = rowsInLatestSession.reduce(
        (a, b) =>
            a.readTable(loggedSets).weight! >= b.readTable(loggedSets).weight!
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
    }
    result.sort((a, b) => b.lastLoggedAt.compareTo(a.lastLoggedAt));
    return result;
  }

  /// Every session log in the database, each with its sets - what a full
  /// backup needs to round-trip execution history.
  Future<List<SessionLogWithSets>> getAllSessionLogsWithSets() async {
    final logs = await select(sessionLogs).get();
    final result = <SessionLogWithSets>[];
    for (final log in logs) {
      result.add(
        SessionLogWithSets(
          log: log,
          sets: await getLoggedSetsForSessionLog(log.id),
        ),
      );
    }
    return result;
  }
}

class SessionLogWithSets {
  final SessionLog log;
  final List<LoggedSet> sets;

  const SessionLogWithSets({required this.log, required this.sets});
}

class PeriodSummary {
  final int sessionsScheduled;
  final int sessionsCompleted;
  final double totalVolume;
  final int prCount;

  const PeriodSummary({
    required this.sessionsScheduled,
    required this.sessionsCompleted,
    required this.totalVolume,
    required this.prCount,
  });
}

class CompletedWorkout {
  final SessionLog log;
  final String sessionName;
  final List<CompletedExercise> exercises;

  const CompletedWorkout({
    required this.log,
    required this.sessionName,
    required this.exercises,
  });
}

class CompletedExercise {
  final String exerciseId;
  final String exerciseName;
  final List<LoggedSet> sets;

  const CompletedExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
  });
}

class CompletedWorkoutSummary {
  final String logId;
  final DateTime loggedAt;
  final String sessionName;
  final int setCount;
  final double volume;
  final int prCount;

  const CompletedWorkoutSummary({
    required this.logId,
    required this.loggedAt,
    required this.sessionName,
    required this.setCount,
    required this.volume,
    required this.prCount,
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
  final double topWeight;
  final int topReps;
  final bool isPr;

  const ExerciseProgressSummary({
    required this.exerciseId,
    required this.lastLoggedAt,
    required this.topWeight,
    required this.topReps,
    required this.isPr,
  });
}
