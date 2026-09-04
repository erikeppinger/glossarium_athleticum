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
