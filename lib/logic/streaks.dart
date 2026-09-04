/// Pure "training streak" logic (Phase 6's adherence dashboard). Deliberately
/// DB/Flutter-free, matching this project's `lib/logic/` convention. A
/// streak counts consecutive **calendar days with any logged activity** -
/// a scheduled session or an ad-hoc walk/run both count (see
/// `SessionLogDao.getAllLoggedDays`) - not weekly schedule adherence, which
/// the Progress tab's `sessionsScheduled`/`sessionsCompleted` already covers
/// separately.
library;

DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

/// How many consecutive days up to and including [today] have a logged day
/// in [loggedDays]. If [today] itself has no log yet, counts from yesterday
/// instead of treating the streak as already broken - it's not over until
/// the day is, so logging today should never be able to *shrink* what's
/// displayed. [loggedDays] need not be sorted or deduplicated.
int computeCurrentStreak(List<DateTime> loggedDays, DateTime today) {
  final days = loggedDays.map(_dayKey).toSet();
  final todayKey = _dayKey(today);
  var cursor = days.contains(todayKey)
      ? todayKey
      : todayKey.subtract(const Duration(days: 1));
  var streak = 0;
  while (days.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

/// The longest run of consecutive logged days anywhere in [loggedDays],
/// regardless of whether it's still ongoing. 0 for no history.
int computeLongestStreak(List<DateTime> loggedDays) {
  if (loggedDays.isEmpty) return 0;
  final sorted = loggedDays.map(_dayKey).toSet().toList()..sort();
  var longest = 1;
  var current = 1;
  for (var i = 1; i < sorted.length; i++) {
    final gap = sorted[i].difference(sorted[i - 1]).inDays;
    current = gap == 1 ? current + 1 : 1;
    if (current > longest) longest = current;
  }
  return longest;
}
