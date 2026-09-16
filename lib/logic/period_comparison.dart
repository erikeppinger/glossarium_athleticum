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

  /// False when the *current* period has zero weighted volume - either
  /// nothing was logged at all, or only bodyweight/no-weight exercises were
  /// (see `PeriodSummary.nonWeightedReps` - those never contribute to
  /// `totalVolume`). In that case a raw "-100%" is technically correct but
  /// reads as "training collapsed" when the truth is just "nothing weighted
  /// this period" - the card's own value already shows that plainly, so the
  /// caller should skip the delta chip entirely rather than show it.
  final bool hasVolumeComparison;

  /// False when the current period has zero PRs. A PR count can only ever
  /// go up, never down - "-1" here would read as "you lost a PR", which
  /// isn't a real thing that happens; zero this period (very normal - most
  /// periods have none) just means nothing new, not a regression to flag.
  final bool hasPrComparison;

  const PeriodComparison({
    required this.prCountDelta,
    required this.activityCountDelta,
    required this.volumeDeltaPercent,
    required this.volumeIsNew,
    required this.hasVolumeComparison,
    required this.hasPrComparison,
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
    hasVolumeComparison: current.totalVolume > 0,
    hasPrComparison: current.prCount > 0,
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
