enum WeekStart { monday, sunday }

/// Which period the Progress tab's overview summary defaults to - the user
/// can still switch within the screen, this just picks what loads first.
enum SummaryPeriod { week, month }

typedef PeriodRange = ({DateTime start, DateTime end});

/// The half-open date range [start, end) for the Progress tab's summary,
/// given which period is selected, the user's week-start preference, an
/// offset in periods from the current one (0 = current, -1 = previous, ...),
/// and the current time (passed in explicitly so this stays pure/testable).
PeriodRange computeSummaryRange({
  required SummaryPeriod period,
  required WeekStart weekStart,
  required int offset,
  required DateTime now,
}) {
  final today = DateTime(now.year, now.month, now.day);
  if (period == SummaryPeriod.week) {
    final firstWeekday = weekStart == WeekStart.monday
        ? DateTime.monday
        : DateTime.sunday;
    final daysSinceStart = (today.weekday - firstWeekday) % 7;
    final currentWeekStart = today.subtract(Duration(days: daysSinceStart));
    final start = currentWeekStart.add(Duration(days: offset * 7));
    return (start: start, end: start.add(const Duration(days: 7)));
  }
  final currentMonthStart = DateTime(today.year, today.month, 1);
  final start = DateTime(
    currentMonthStart.year,
    currentMonthStart.month + offset,
    1,
  );
  return (start: start, end: DateTime(start.year, start.month + 1, 1));
}

/// Shifts [range] backward/forward by its own length, [steps] times
/// (negative = backward, matching [computeSummaryRange]'s `offset`
/// convention). There's no calendar-aware definition of "the period before"
/// for an arbitrary custom range the way [computeSummaryRange] has for
/// week/month (a month's own length varies, a custom range's doesn't have
/// a calendar unit at all) - shifting by the range's own length is the one
/// definition that works for any range, so this is what a custom range's
/// prev/next navigation and previous-period comparison both use instead of
/// [computeSummaryRange].
PeriodRange shiftedRange(PeriodRange range, int steps) {
  final shift = range.end.difference(range.start) * steps;
  return (start: range.start.add(shift), end: range.end.add(shift));
}
