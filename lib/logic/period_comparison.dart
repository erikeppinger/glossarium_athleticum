import '../data/daos/session_log_dao.dart';

/// The signed difference between one period's [PeriodSummary] and another's
/// (the immediately preceding period, in every current caller) - pure and
/// caller-agnostic about which period type produced the two summaries, so
/// the Progress tab's "vs previous" cards can use the same comparison for
/// week, month, or a custom range alike.
class PeriodComparison {
  final int prCountDelta;
  final int activityCountDelta;

  /// Percentage change in total volume, or 0 when [volumeIsNew] is true
  /// (nothing to take a percentage of).
  final double volumeDeltaPercent;

  /// True when the previous period had zero volume but this one has some -
  /// a percentage change from zero is undefined, and "+∞%"/"new" reads far
  /// better than a bogus number.
  final bool volumeIsNew;

  const PeriodComparison({
    required this.prCountDelta,
    required this.activityCountDelta,
    required this.volumeDeltaPercent,
    required this.volumeIsNew,
  });
}

PeriodComparison comparePeriods({
  required PeriodSummary current,
  required PeriodSummary previous,
}) {
  final volumeIsNew = previous.totalVolume == 0 && current.totalVolume > 0;
  final volumeDeltaPercent = previous.totalVolume == 0
      ? 0.0
      : (current.totalVolume - previous.totalVolume) /
            previous.totalVolume *
            100;

  return PeriodComparison(
    prCountDelta: current.prCount - previous.prCount,
    activityCountDelta:
        current.adHocActivityCount - previous.adHocActivityCount,
    volumeDeltaPercent: volumeDeltaPercent,
    volumeIsNew: volumeIsNew,
  );
}

/// "+2"/"-1"/"±0" - a signed count delta for display next to a stat card.
String formatCountDelta(int delta) {
  if (delta > 0) return '+$delta';
  if (delta < 0) return '$delta';
  return '±0';
}

/// "+12%"/"-8%"/"±0%"/"new" - a signed percentage delta, rounded to the
/// nearest whole percent since a fractional percent adds precision nobody
/// asked for on a small stat card.
String formatPercentDelta(double percent, {required bool isNew}) {
  if (isNew) return 'new';
  final rounded = percent.round();
  if (rounded > 0) return '+$rounded%';
  if (rounded < 0) return '$rounded%';
  return '±0%';
}
