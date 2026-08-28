import 'dart:math' as math;

/// A chart's Y-axis top and gridline step, chosen so that [maxValue] fits,
/// the top is an exact multiple of the step, and every label is a round
/// number.
///
/// fl_chart's default interval otherwise lands two labels almost on top of
/// each other near the top of the axis (e.g. "1K" and "1.1K" when maxY is
/// 1056). This is the general form of the fix that `history_screen.dart`
/// hard-codes for its own chart - see CLAUDE.md.
///
/// A non-positive [maxValue] (e.g. a week with no personal records) still
/// gets a usable axis rather than a zero-height one fl_chart can't lay out.
({double max, double interval}) niceAxis(
  double maxValue, {
  int targetLines = 4,
}) {
  if (maxValue <= 0) return (max: targetLines.toDouble(), interval: 1);

  final rough = maxValue / targetLines;
  final magnitude = math
      .pow(10, (math.log(rough) / math.ln10).floor())
      .toDouble();
  // Snap the step to 1, 2, 5, or 10 times a power of ten - the steps people
  // read without doing arithmetic. Thresholds are Heckbert's "nice numbers"
  // (Graphics Gems, 1990); rounding at 1/2/5 alone snaps too coarsely and
  // can collapse a chart to two gridlines.
  final normalized = rough / magnitude;
  final step =
      (normalized < 1.5
          ? 1
          : normalized < 3
          ? 2
          : normalized < 7
          ? 5
          : 10) *
      magnitude;

  // A little headroom so the tallest bar doesn't touch the ceiling.
  return (max: (maxValue * 1.05 / step).ceil() * step, interval: step);
}
