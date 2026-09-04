import 'summary_period.dart';
import 'units.dart';

/// One bodyweight reading, reduced to just what the trend calculation
/// needs - kept DB-free (no `BodyMeasurement` dependency) to match every
/// other file in `lib/logic/`.
typedef BodyWeightReading = ({DateTime measuredAt, double weightKg});

/// The bodyweight change to show alongside a period summary. [deltaKg] is
/// signed - negative means lighter than [baselineDate], positive heavier.
typedef BodyWeightChange = ({double deltaKg, double currentKg, DateTime baselineDate});

/// The bodyweight trend for [range]: the latest weight at or before the
/// period's end, compared against the latest weight before the period's
/// start (or, if nothing was recorded that far back yet, the earliest
/// reading available) - the "baseline".
///
/// Comparing against the nearest *prior* reading, rather than only entries
/// strictly inside the range, matters because most people don't weigh in
/// daily: someone who logs once a week would have exactly one point inside
/// a "week" range, and a first-vs-last-within-range comparison would show
/// "not enough data" every single week. Comparing against the last known
/// reading before the period started gives a real week-over-week (or
/// month-over-month) trend even from sparse, irregular logging.
///
/// Returns null once there's fewer than two distinct readings at or before
/// [range]'s end - there's nothing to compare yet.
BodyWeightChange? computeBodyWeightChange({
  required List<BodyWeightReading> readings,
  required PeriodRange range,
}) {
  final upToEnd = readings.where((r) => r.measuredAt.isBefore(range.end)).toList()
    ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
  if (upToEnd.length < 2) return null;

  final current = upToEnd.last;
  final beforeStart = upToEnd.where((r) => r.measuredAt.isBefore(range.start));
  final baseline = beforeStart.isNotEmpty ? beforeStart.last : upToEnd.first;

  return (
    deltaKg: current.weightKg - baseline.weightKg,
    currentKg: current.weightKg,
    baselineDate: baseline.measuredAt,
  );
}

/// "↓ 2kg" / "↑ 2kg" / "No change" - shared by the Progress screen's summary
/// card, its shared text, and the PDF report, so the three can't drift.
String formatWeightChange(BodyWeightChange change, WeightUnit unit) {
  final magnitude = formatWeightInUnit(change.deltaKg.abs(), unit);
  // Sub-gram differences are floating-point noise from unit conversion, not
  // a real reading - round to "no change" rather than show "↓ 0kg".
  if (change.deltaKg.abs() < 0.05) return 'No change';
  return change.deltaKg < 0 ? '↓ $magnitude' : '↑ $magnitude';
}
