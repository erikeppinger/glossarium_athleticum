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
}
