import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/logic/streaks.dart';

void main() {
  group('computeCurrentStreak', () {
    test('no history at all is a zero streak', () {
      expect(computeCurrentStreak([], DateTime(2026, 9, 4)), 0);
    });

    test('a single day logged today is a 1-day streak', () {
      expect(
        computeCurrentStreak([DateTime(2026, 9, 4)], DateTime(2026, 9, 4)),
        1,
      );
    });

    test('counts backward through consecutive days ending today', () {
      final days = [
        DateTime(2026, 9, 4),
        DateTime(2026, 9, 3),
        DateTime(2026, 9, 2),
      ];
      expect(computeCurrentStreak(days, DateTime(2026, 9, 4)), 3);
    });

    test('a gap breaks the streak - only the run touching today counts', () {
      final days = [
        DateTime(2026, 9, 4),
        DateTime(2026, 9, 3),
        // gap at Sep 2
        DateTime(2026, 9, 1),
      ];
      expect(computeCurrentStreak(days, DateTime(2026, 9, 4)), 2);
    });

    test(
      "today not yet logged doesn't break the streak - counts from yesterday",
      () {
        final days = [DateTime(2026, 9, 3), DateTime(2026, 9, 2)];
        expect(computeCurrentStreak(days, DateTime(2026, 9, 4)), 2);
      },
    );

    test('neither today nor yesterday logged is a zero streak', () {
      final days = [DateTime(2026, 9, 1)];
      expect(computeCurrentStreak(days, DateTime(2026, 9, 4)), 0);
    });

    test('duplicate entries for the same day are not double-counted', () {
      final days = [
        DateTime(2026, 9, 4, 8),
        DateTime(2026, 9, 4, 20),
        DateTime(2026, 9, 3),
      ];
      expect(computeCurrentStreak(days, DateTime(2026, 9, 4)), 2);
    });
  });

  group('computeLongestStreak', () {
    test('no history is zero', () {
      expect(computeLongestStreak([]), 0);
    });

    test('a single day is a 1-day streak', () {
      expect(computeLongestStreak([DateTime(2026, 9, 4)]), 1);
    });

    test('finds the longest run, not just the most recent one', () {
      final days = [
        // A 2-day run.
        DateTime(2026, 8, 1),
        DateTime(2026, 8, 2),
        // A later, longer 4-day run.
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 2),
        DateTime(2026, 9, 3),
        DateTime(2026, 9, 4),
      ];
      expect(computeLongestStreak(days), 4);
    });

    test('is unaffected by input order', () {
      final days = [
        DateTime(2026, 9, 3),
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 2),
      ];
      expect(computeLongestStreak(days), 3);
    });
  });
}
