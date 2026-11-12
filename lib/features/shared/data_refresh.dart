import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../calendar/calendar_screen.dart';
import '../execution/rest_timer_controller.dart';
import '../history/workout_history_screen.dart';
import '../notifications/reminder_coordinator.dart';
import '../plans/plan_providers.dart';
import '../progress/body_measurements_screen.dart';
import '../progress/progress_providers.dart';
import 'exercise_list_invalidation.dart';

/// After everything on the device was replaced or erased (a backup restore,
/// "Delete all data"): refreshes every cached view of it and rebuilds the
/// reminders. Each of these is a one-shot provider on an always-mounted tab,
/// so without this the Calendar and Today tabs kept showing sessions that no
/// longer exist until the app was restarted, and their old reminders still
/// fired.
Future<void> refreshAfterAllDataReplaced(WidgetRef ref) async {
  invalidateExerciseListProviders(ref);
  invalidateProgressProviders(ref);
  ref.invalidate(scheduledSessionsProvider);
  ref.invalidate(loggedPlanSessionIdsProvider);
  ref.invalidate(adHocActivitiesProvider);
  ref.invalidate(planDetailsProvider);
  ref.invalidate(bodyMeasurementsProvider);
  ref.invalidate(workoutHistoryProvider);
  ref.invalidate(workoutHistoryInRangeProvider);
  ref.invalidate(completedWorkoutProvider);

  // A workout in progress pointed at a session that is gone now.
  ref.read(activeInProgressSessionIdProvider.notifier).state = null;
  if (ref.read(restTimerControllerProvider).planSessionId != null) {
    ref.read(restTimerControllerProvider.notifier).skip();
  }

  await resyncReminders(ref);
}
