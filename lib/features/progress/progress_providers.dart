import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database_provider.dart';
import '../../data/daos/session_log_dao.dart';
import '../../logic/streaks.dart';
import '../../logic/summary_period.dart';

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
}
