import '../data/app_database.dart';
import '../data/daos/plan_dao.dart';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../data/daos/session_log_dao.dart';
import '../export/plan_export.dart';
import '../logic/plan_fingerprint.dart';
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

/// A newer version of a plan that was imported from someone else's file
/// (typically a trainer's) - matched through `Plans.sourcePlanId`, since an
/// import gets a fresh local id. The sender owns the plan's contents; the
/// person on this device owns its calendar dates and logged workouts.
/// [editedHere] is whether the contents on this device were changed since
/// the last import or update: if not, a single confirmation can replace
/// them (see [applyPlanUpdate]); if so, the user must choose.
class PlanSyncUpdate extends PlanSyncOutcome {
  final PlanDetails local;
  final Map<String, dynamic> incomingJson;
  final bool editedHere;
  const PlanSyncUpdate({
    required this.local,
    required this.incomingJson,
    required this.editedHere,
  });
}

Future<PlanSyncOutcome> checkPlanSync(
  Map<String, dynamic> incomingJson,
  AppDatabase db,
) async {
  final id = incomingJson['id'] as String?;
  if (id == null) return const PlanSyncNew();

  final incomingUpdatedAt = DateTime.tryParse(
    incomingJson['updated_at'] as String? ?? '',
  );

  // Same id: this plan itself, exported from another of the user's devices.
  final local = await db.planDao.getPlanDetails(id);
  if (local != null) {
    if (incomingUpdatedAt != null &&
        incomingUpdatedAt.isAtSameMomentAs(local.plan.updatedAt)) {
      return const PlanSyncUpToDate();
    }
    return PlanSyncConflict(local: local, incomingJson: incomingJson);
  }

  // A plan imported from this file's plan before: a new version of it.
  final copy = await db.planDao.findPlanBySourceId(id);
  if (copy == null) return const PlanSyncNew();
  final copyDetails = (await db.planDao.getPlanDetails(copy.id))!;
  final hereNow = planContentFingerprint(planToJson(copyDetails));
  final seenBefore =
      incomingUpdatedAt != null &&
      copy.sourceUpdatedAt != null &&
      incomingUpdatedAt.isAtSameMomentAs(copy.sourceUpdatedAt!);
  if (seenBefore || planContentFingerprint(incomingJson) == hereNow) {
    return const PlanSyncUpToDate();
  }
  return PlanSyncUpdate(
    local: copyDetails,
    incomingJson: incomingJson,
    editedHere: hereNow != copy.sourceContentHash,
  );
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
///
/// Runs in one transaction: the local plan and its logs are deleted before
/// the incoming version is imported, so a failure part-way must roll back
/// rather than leave the plan and its training history gone.
Future<void> applyIncomingPlan(
  Map<String, dynamic> incomingJson,
  AppDatabase db,
) => db.transaction(() => _replacePlan(incomingJson, db));

/// Replaces [local]'s contents with [incomingJson], a newer version from
/// the plan's sender (see [PlanSyncUpdate]). Keeps what belongs to the
/// person on this device: the local plan id, its calendar dates and logged
/// workouts (by session, like [applyIncomingPlan]), and whether it's
/// archived and its progress-reminder choice. Logs of a session the new
/// version removed are lost - warn first via [findLogsThatWouldBeLost].
Future<void> applyPlanUpdate(
  PlanDetails local,
  Map<String, dynamic> incomingJson,
  AppDatabase db,
) => db.transaction(() async {
  final plan = local.plan;
  await _replacePlan(
    incomingJson,
    db,
    localId: plan.id,
    keepLocalDates: true,
  );
  await (db.update(db.plans)..where((p) => p.id.equals(plan.id))).write(
    PlansCompanion(
      archivedAt: Value(plan.archivedAt),
      reportPreference: Value(plan.reportPreference),
      reportFrequencyDays: Value(plan.reportFrequencyDays),
      reportOptInAt: Value(plan.reportOptInAt),
    ),
  );
  await db.planDao.setPlanSource(
    plan.id,
    sourcePlanId: incomingJson['id'] as String,
    sourceUpdatedAt: DateTime.tryParse(
      incomingJson['updated_at'] as String? ?? '',
    ),
    sourceContentHash: planContentFingerprint(incomingJson),
  );
});

/// The user kept their own version of [local] over an update: remember the
/// update as seen, so the same file doesn't ask again. The stored content
/// fingerprint stays, so their edits still count as edits next time.
Future<void> keepLocalOverUpdate(
  PlanDetails local,
  Map<String, dynamic> incomingJson,
  AppDatabase db,
) => db.planDao.setPlanSource(
  local.plan.id,
  sourcePlanId: local.plan.sourcePlanId,
  sourceUpdatedAt: DateTime.tryParse(
    incomingJson['updated_at'] as String? ?? '',
  ),
  sourceContentHash: local.plan.sourceContentHash,
);

/// The user kept both: the update is imported as its own plan and becomes
/// the one that follows the sender's updates; [local] becomes their own.
Future<void> keepBothAfterUpdate(
  PlanDetails local,
  Map<String, dynamic> incomingJson,
  AppDatabase db,
) => db.transaction(() async {
  await importPlanJson(incomingJson, db);
  await db.planDao.setPlanSource(
    local.plan.id,
    sourcePlanId: null,
    sourceUpdatedAt: null,
    sourceContentHash: null,
  );
});

Future<void> _replacePlan(
  Map<String, dynamic> incomingJson,
  AppDatabase db, {
  String? localId,
  bool keepLocalDates = false,
}) async {
  final id = localId ?? incomingJson['id'] as String;
  final local = await db.planDao.getPlanDetails(id);

  final datesByKey = <(int, String, String), List<DateTime>>{
    if (keepLocalDates && local != null)
      for (final session in local.sessions)
        (
          session.session.weekNumber,
          session.session.day,
          session.session.sessionName,
        ): session.dates,
  };

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

  await importPlanJson(
    keepLocalDates ? _withoutDates(incomingJson) : incomingJson,
    db,
    planId: id,
  );

  for (final entry in datesByKey.entries) {
    if (entry.value.isEmpty) continue;
    final (weekNumber, day, sessionName) = entry.key;
    final session = await db.planDao.findSessionByNaturalKey(
      planId: id,
      weekNumber: weekNumber,
      day: day,
      sessionName: sessionName,
    );
    if (session == null) continue; // the new version removed this session
    for (final date in entry.value) {
      await db.planDao.addSessionDate(session.id, date);
    }
  }

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

/// A deep copy of a plan file with every session's dates removed - the
/// sender's calendar isn't the recipient's.
Map<String, dynamic> _withoutDates(Map<String, dynamic> planJson) {
  final copy = jsonDecode(jsonEncode(planJson)) as Map<String, dynamic>;
  for (final week in copy['weeks'] as List) {
    for (final session in (week as Map)['sessions'] as List) {
      (session as Map)
        ..remove('assigned_date')
        ..['assigned_dates'] = <String>[];
    }
  }
  return copy;
}
