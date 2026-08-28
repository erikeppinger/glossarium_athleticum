import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database_provider.dart';
import '../../data/daos/session_log_dao.dart';
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
