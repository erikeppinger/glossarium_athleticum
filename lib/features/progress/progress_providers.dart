import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database_provider.dart';
import '../../data/daos/session_log_dao.dart';
import '../../logic/muscle_group_volume.dart';
import '../../logic/one_rep_max.dart';
import '../../logic/progression.dart';
import '../../logic/streaks.dart';
import '../../logic/summary_period.dart';
import '../settings/app_preferences.dart';

final periodSummaryProvider = FutureProvider.family<PeriodSummary, PeriodRange>(
  (ref, range) {
    final db = ref.watch(appDatabaseProvider);
    return db.sessionLogDao.getPeriodSummary(start: range.start, end: range.end);
  },
);

final exerciseProgressDashboardProvider =
    FutureProvider<List<ExerciseProgressSummary>>((ref) {
      final db = ref.watch(appDatabaseProvider);
      return db.sessionLogDao.getLatestTopSetPerExercise();
    });

final dailyTotalsProvider = FutureProvider.family<List<DailyTotals>, PeriodRange>(
  (ref, range) {
    final db = ref.watch(appDatabaseProvider);
    return db.sessionLogDao.getDailyTotals(start: range.start, end: range.end);
  },
);

/// One exercise's progression history (reduced session-by-session results,
/// see `SessionLogDao.getProgressionHistory`'s own doc comment) - backs the
/// "Suggested next session" card on the History screen and the "Best: ..."
/// line in execution mode. Both screens used to define their own private,
/// near-identical copy of this provider, and neither was ever invalidated
/// after a session was logged - the suggestion/best-weight only updated
/// after a full app restart, the same one-shot-FutureProvider gotcha this
/// file's own [invalidateProgressProviders] already exists to fix for the
/// Progress tab. One shared, invalidated provider fixes both at once.
final exerciseProgressionHistoryProvider =
    FutureProvider.family<List<ProgressionHistoryEntry>, String>((
      ref,
      exerciseId,
    ) {
      final db = ref.watch(appDatabaseProvider);
      return db.sessionLogDao.getProgressionHistory(exerciseId);
    });

/// One exercise's reps-only history (see `SessionLogDao.getRepsOnlyHistory`)
/// - the no-weight counterpart to [exerciseProgressionHistoryProvider],
/// backing the History screen's fallback view for a bodyweight/band/
/// Time-type exercise that has never logged a weight.
final repsOnlyHistoryProvider =
    FutureProvider.family<List<RepsHistoryEntry>, String>((ref, exerciseId) {
      final db = ref.watch(appDatabaseProvider);
      return db.sessionLogDao.getRepsOnlyHistory(exerciseId);
    });

/// Derived from [exerciseProgressionHistoryProvider] via `.future` rather
/// than its own DAO query - stays fresh automatically whenever that
/// provider is invalidated (see [invalidateProgressProviders] below), so
/// this needs no new invalidation call site of its own.
final estimatedOneRepMaxProvider = FutureProvider.family<double?, String>((
  ref,
  exerciseId,
) async {
  final history = await ref.watch(
    exerciseProgressionHistoryProvider(exerciseId).future,
  );
  return bestEstimatedOneRepMax(history);
});

/// Period-independent (a streak isn't scoped to the selected week/month) -
/// both derive from the same logged-days query, so this is one provider
/// composing the DB call through the two pure functions in
/// `lib/logic/streaks.dart` rather than two separate DB round-trips.
final _loggedDaysProvider = FutureProvider<List<DateTime>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.sessionLogDao.getAllLoggedDays();
});

final currentStreakProvider = FutureProvider<int>((ref) async {
  final days = await ref.watch(_loggedDaysProvider.future);
  return computeCurrentStreak(days, DateTime.now());
});

final longestStreakProvider = FutureProvider<int>((ref) async {
  final days = await ref.watch(_loggedDaysProvider.future);
  return computeLongestStreak(days);
});

/// The current calendar week's sets-per-muscle-group tally (see
/// `lib/logic/muscle_group_volume.dart`) - deliberately independent of the
/// Progress tab's own selected Week/Month/Custom view, the same way
/// [currentStreakProvider] is, since the underlying guideline this is
/// measured against is inherently a weekly one regardless of what period
/// the rest of the screen happens to be showing.
final muscleGroupVolumeProvider = FutureProvider<List<MuscleGroupVolume>>((
  ref,
) async {
  final db = ref.watch(appDatabaseProvider);
  final weekStart = ref.watch(
    appPreferencesProvider.select((p) => p.weekStart),
  );
  final range = computeSummaryRange(
    period: SummaryPeriod.week,
    weekStart: weekStart,
    offset: 0,
    now: DateTime.now(),
  );
  final entries = await db.sessionLogDao.getSetCountsByExercise(
    start: range.start,
    end: range.end,
  );
  return tallyMuscleGroupVolume(entries);
});

/// Every one-shot FutureProvider the Progress tab reads from - call this
/// after any write that changes logged sessions/activities (finishing a
/// session, logging an ad-hoc activity, importing/restoring, deleting a
/// log, ...). The Progress tab is a permanently-mounted IndexedStack tab
/// (see home_screen.dart), so without this its numbers only update on a
/// full app restart rather than on switching back to the tab - invalidating
/// just [currentStreakProvider]/[longestStreakProvider] wouldn't be enough
/// on its own either, since they'd still read the stale cached
/// [_loggedDaysProvider] they depend on.
void invalidateProgressProviders(WidgetRef ref) {
  ref.invalidate(periodSummaryProvider);
  ref.invalidate(dailyTotalsProvider);
  ref.invalidate(exerciseProgressDashboardProvider);
  ref.invalidate(_loggedDaysProvider);
  ref.invalidate(currentStreakProvider);
  ref.invalidate(longestStreakProvider);
  ref.invalidate(exerciseProgressionHistoryProvider);
  ref.invalidate(repsOnlyHistoryProvider);
  ref.invalidate(muscleGroupVolumeProvider);
}
