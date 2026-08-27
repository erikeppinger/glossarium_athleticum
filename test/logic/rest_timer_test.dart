import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/logic/rest_timer.dart';

void main() {
  final endTime = DateTime(2026, 8, 26, 12, 0, 0);

  group('remainingRestTime', () {
    test('before end time returns the difference', () {
      final now = endTime.subtract(const Duration(seconds: 90));
      expect(
        remainingRestTime(endTime: endTime, now: now),
        const Duration(seconds: 90),
      );
    });

    test('at exactly end time returns zero', () {
      expect(remainingRestTime(endTime: endTime, now: endTime), Duration.zero);
    });

    test('after end time (e.g. app was backgrounded past it) clamps to zero, never negative', () {
      final now = endTime.add(const Duration(minutes: 20));
      expect(remainingRestTime(endTime: endTime, now: now), Duration.zero);
    });

    test('a long background gap does not cause drift - remaining is still exact', () {
      // Simulates: timer started, app backgrounded for an arbitrary long
      // time, then resumed while the timer should still be running because
      // the rest period itself was long.
      final longEnd = DateTime(2026, 8, 26, 13, 0, 0);
      final resumedAt = longEnd.subtract(const Duration(seconds: 45));
      expect(
        remainingRestTime(endTime: longEnd, now: resumedAt),
        const Duration(seconds: 45),
      );
    });
  });

  group('isRestTimerFinished', () {
    test('false before end time', () {
      expect(
        isRestTimerFinished(
          endTime: endTime,
          now: endTime.subtract(const Duration(seconds: 1)),
        ),
        isFalse,
      );
    });

    test('true at exactly end time', () {
      expect(isRestTimerFinished(endTime: endTime, now: endTime), isTrue);
    });

    test('true well after end time', () {
      expect(
        isRestTimerFinished(
          endTime: endTime,
          now: endTime.add(const Duration(hours: 1)),
        ),
        isTrue,
      );
    });
  });

  group('formatRestTime', () {
    test('pads seconds and minutes to two digits', () {
      expect(formatRestTime(const Duration(seconds: 5)), '00:05');
      expect(formatRestTime(const Duration(minutes: 1, seconds: 30)), '01:30');
    });

    test('minutes roll over past 60 seconds correctly', () {
      expect(formatRestTime(const Duration(seconds: 125)), '02:05');
    });

    test('zero duration formats as 00:00', () {
      expect(formatRestTime(Duration.zero), '00:00');
    });
  });
}
