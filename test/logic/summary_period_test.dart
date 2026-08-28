import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/logic/summary_period.dart';

void main() {
  group('computeSummaryRange - week', () {
    test('Monday week-start: mid-week "now" resolves to that week\'s Monday', () {
      // Wednesday 2026-08-26.
      final range = computeSummaryRange(
        period: SummaryPeriod.week,
        weekStart: WeekStart.monday,
        offset: 0,
        now: DateTime(2026, 8, 26),
      );
      expect(range.start, DateTime(2026, 8, 24));
      expect(range.end, DateTime(2026, 8, 31));
    });

    test('Sunday week-start: same "now" resolves to the preceding Sunday', () {
      final range = computeSummaryRange(
        period: SummaryPeriod.week,
        weekStart: WeekStart.sunday,
        offset: 0,
        now: DateTime(2026, 8, 26),
      );
      expect(range.start, DateTime(2026, 8, 23));
      expect(range.end, DateTime(2026, 8, 30));
    });

    test('"now" that is itself the week-start day stays put', () {
      // 2026-08-24 is a Monday.
      final range = computeSummaryRange(
        period: SummaryPeriod.week,
        weekStart: WeekStart.monday,
        offset: 0,
        now: DateTime(2026, 8, 24),
      );
      expect(range.start, DateTime(2026, 8, 24));
    });

    test('offset -1 goes back exactly one week', () {
      final range = computeSummaryRange(
        period: SummaryPeriod.week,
        weekStart: WeekStart.monday,
        offset: -1,
        now: DateTime(2026, 8, 26),
      );
      expect(range.start, DateTime(2026, 8, 17));
      expect(range.end, DateTime(2026, 8, 24));
    });
  });

  group('computeSummaryRange - month', () {
    test('resolves to the first-to-first range of the current month', () {
      final range = computeSummaryRange(
        period: SummaryPeriod.month,
        weekStart: WeekStart.monday,
        offset: 0,
        now: DateTime(2026, 8, 26),
      );
      expect(range.start, DateTime(2026, 8, 1));
      expect(range.end, DateTime(2026, 9, 1));
    });

    test('offset -1 goes back one month, handling year rollover', () {
      final range = computeSummaryRange(
        period: SummaryPeriod.month,
        weekStart: WeekStart.monday,
        offset: -1,
        now: DateTime(2026, 1, 15),
      );
      expect(range.start, DateTime(2025, 12, 1));
      expect(range.end, DateTime(2026, 1, 1));
    });
  });
}
