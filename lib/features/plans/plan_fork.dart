import 'package:uuid/uuid.dart';

import '../../data/app_database.dart';
import '../../data/daos/plan_dao.dart';

/// Creates a new plan that's a copy of [sourcePlanId], except session
/// [editedSessionId]'s exercises are replaced by [newExercisesForEditedSession]
/// - used whenever an exercise is added to or removed from a session on an
/// already-existing plan (edit_session_screen.dart), so that structural
/// change lands as a new, separately-named plan rather than silently
/// rewriting the one the user opened. Every other session is copied
/// verbatim, including its scheduled dates, so the fork is immediately
/// just as usable (already on the calendar, already loggable) as the
/// original was.
///
/// Deliberately never touches `SessionLogs`/`LoggedSets`: nothing has been
/// trained against the fork yet, so logged history has no reason to move -
/// it stays attached to the *original* plan's session rows, which is
/// exactly where it belongs. The original plan itself is never modified by
/// this function.
Future<String> forkPlanWithModifiedSession(
  AppDatabase db, {
  required String sourcePlanId,
  required String newPlanName,
  required int editedSessionId,
  required List<PlanExerciseInput> newExercisesForEditedSession,
}) async {
  final source = await db.planDao.getPlanDetails(sourcePlanId);
  if (source == null) {
    throw StateError('Plan $sourcePlanId not found.');
  }

  final sessionInputs = [
    for (final session in source.sessions)
      PlanSessionInput(
        weekNumber: session.session.weekNumber,
        day: session.session.day,
        sessionName: session.session.sessionName,
        assignedDates: session.dates,
        exercises: session.session.id == editedSessionId
            ? newExercisesForEditedSession
            : [for (final exercise in session.exercises) exercise.toInput()],
      ),
  ];

  return db.planDao.createPlan(
    id: const Uuid().v4(),
    name: newPlanName,
    notes: source.plan.notes,
    sessions: sessionInputs,
  );
}
