import '../data/app_database.dart';
import '../data/daos/plan_dao.dart';
import '../data/daos/session_log_dao.dart';
import 'plan_json_import.dart';

/// What should happen with an incoming plan JSON file (Phase 5's sync,
/// built on top of Phase 4's file-sharing transport), relative to what's
/// already on this device. A plan's `id` is the sync identity - two
/// exports of the *same* plan carry the same id; a plan shared with you
/// for the first time by someone else won't collide with anything local.
sealed class PlanSyncOutcome {
  const PlanSyncOutcome();
}

/// No local plan has this id - a normal import, nothing to reconcile.
class PlanSyncNew extends PlanSyncOutcome {
  const PlanSyncNew();
}

/// The local plan with this id has the exact same `updated_at` as the
/// incoming one - already in sync, nothing to do.
class PlanSyncUpToDate extends PlanSyncOutcome {
  const PlanSyncUpToDate();
}

/// The local plan with this id has a *different* `updated_at` than the
/// incoming one - one or both sides changed since they last matched.
/// Never resolved automatically (a timestamp alone can't safely say which
/// side "wins," especially across two devices' clocks) - the caller must
/// ask the user, per the dev plan's "never silent data loss" exit criteria.
class PlanSyncConflict extends PlanSyncOutcome {
  final PlanDetails local;
  final Map<String, dynamic> incomingJson;
  const PlanSyncConflict({required this.local, required this.incomingJson});
}

Future<PlanSyncOutcome> checkPlanSync(
  Map<String, dynamic> incomingJson,
  AppDatabase db,
) async {
  final id = incomingJson['id'] as String?;
  if (id == null) return const PlanSyncNew();

  final local = await db.planDao.getPlanDetails(id);
  if (local == null) return const PlanSyncNew();

  final incomingUpdatedAt = DateTime.tryParse(
    incomingJson['updated_at'] as String? ?? '',
  );
  if (incomingUpdatedAt != null &&
      incomingUpdatedAt.isAtSameMomentAs(local.plan.updatedAt)) {
    return const PlanSyncUpToDate();
  }
  return PlanSyncConflict(local: local, incomingJson: incomingJson);
}

/// Every local session log that would be deleted if [incomingJson] replaced
/// [local] - i.e. logs attached to a session (by week+day+session name) that
/// doesn't exist in the incoming version. Callers must warn about these
/// *before* calling [applyIncomingPlan], since that's the point where
/// they're actually lost - logs for a session present in both versions
/// survive (see [applyIncomingPlan]).
Future<List<SessionLogWithSets>> findLogsThatWouldBeLost(
  PlanDetails local,
  Map<String, dynamic> incomingJson,
  AppDatabase db,
) async {
  final incomingKeys = <(int, String, String)>{};
  for (final week in incomingJson['weeks'] as List) {
    final weekNumber = week['week_number'] as int;
    for (final session in week['sessions'] as List) {
      incomingKeys.add((
        weekNumber,
        session['day'] as String,
        session['session_name'] as String,
      ));
    }
  }

  final lost = <SessionLogWithSets>[];
  for (final session in local.sessions) {
    final key = (
      session.session.weekNumber,
      session.session.day,
      session.session.sessionName,
    );
    if (incomingKeys.contains(key)) continue;
    final logs = await db.sessionLogDao.getLogsForPlanSession(
      session.session.id,
    );
    for (final log in logs) {
      lost.add(
        SessionLogWithSets(
          log: log,
          sets: await db.sessionLogDao.getLoggedSetsForSessionLog(log.id),
        ),
      );
    }
  }
  return lost;
}

/// Replaces the local plan sharing [incomingJson]'s id with the incoming
/// version, re-linking any existing session logs to the new sessions by
/// natural key (week+day+session name) - the same relinking approach as
/// backup restore (Phase 3), so logged history for a session that still
/// exists in the incoming plan survives the sync. A log whose session was
/// removed in the incoming version has nowhere to attach and is dropped -
/// callers must have already warned about this via [findLogsThatWouldBeLost]
/// before calling this, since there's no undo past this point.
Future<void> applyIncomingPlan(
  Map<String, dynamic> incomingJson,
  AppDatabase db,
) async {
  final id = incomingJson['id'] as String;
  final local = await db.planDao.getPlanDetails(id);

  final logsByKey = <(int, String, String), List<SessionLogWithSets>>{};
  if (local != null) {
    for (final session in local.sessions) {
      final logs = await db.sessionLogDao.getLogsForPlanSession(
        session.session.id,
      );
      if (logs.isEmpty) continue;
      final withSets = <SessionLogWithSets>[];
      for (final log in logs) {
        withSets.add(
          SessionLogWithSets(
            log: log,
            sets: await db.sessionLogDao.getLoggedSetsForSessionLog(log.id),
            skipped: await db.sessionLogDao.getSkippedForSessionLog(log.id),
          ),
        );
      }
      logsByKey[(
        session.session.weekNumber,
        session.session.day,
        session.session.sessionName,
      )] = withSets;
      // Captured above for relinking; must go before deletePlan removes
      // the PlanSessions row these logs still reference, and before it's
      // safe to re-insert a log under the same id (see deleteLogsForPlanSession).
      await db.sessionLogDao.deleteLogsForPlanSession(session.session.id);
    }
    await db.planDao.deletePlan(id);
  }

  await importPlanJson(incomingJson, db, planId: id);

  for (final entry in logsByKey.entries) {
    final (weekNumber, day, sessionName) = entry.key;
    final newSession = await db.planDao.findSessionByNaturalKey(
      planId: id,
      weekNumber: weekNumber,
      day: day,
      sessionName: sessionName,
    );
    if (newSession == null) continue; // dropped - see doc comment above
    for (final logWithSets in entry.value) {
      await db.sessionLogDao.createSessionLog(
        id: logWithSets.log.id,
        planSessionId: newSession.id,
        loggedAt: logWithSets.log.loggedAt,
        notes: logWithSets.log.notes,
        entries: [
          for (final set in logWithSets.sets)
            LoggedSetInput(
              exerciseId: set.exerciseId,
              setNumber: set.setNumber,
              reps: set.reps,
              weight: set.weight,
              durationSec: set.durationSec,
              distance: set.distance,
              rpe: set.rpe,
              isPr: set.isPr,
              notes: set.notes,
            ),
        ],
        skipped: [for (final s in logWithSets.skipped) s.toInput()],
      );
    }
  }
}
