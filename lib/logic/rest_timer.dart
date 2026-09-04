/// Pure time math for the rest timer. Kept separate from the Timer/
/// StateNotifier plumbing driving the UI so backgrounding never causes
/// drift: the timer is defined by a fixed [DateTime] end point, and
/// "remaining" is always recomputed from that plus the current wall-clock
/// time - never decremented tick-by-tick - so it doesn't matter how long
/// (or whether) the periodic UI-refresh ticks kept firing while the app was
/// backgrounded.
library;

Duration remainingRestTime({required DateTime endTime, required DateTime now}) {
  final remaining = endTime.difference(now);
  return remaining.isNegative ? Duration.zero : remaining;
}

bool isRestTimerFinished({required DateTime endTime, required DateTime now}) =>
    !now.isBefore(endTime);

/// Threshold for the "nearly up" pulsing-red visual treatment - short enough
/// to read as "wrap it up," not so short it's easy to miss altogether.
const restTimerNearEndThreshold = Duration(seconds: 10);

bool isRestTimerNearEnd(Duration remaining) =>
    remaining > Duration.zero && remaining <= restTimerNearEndThreshold;

String formatRestTime(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}
