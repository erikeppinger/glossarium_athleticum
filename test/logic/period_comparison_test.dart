import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/daos/session_log_dao.dart';
import 'package:training_app/logic/period_comparison.dart';

void main() {
  group('comparePeriods', () {
    test('computes signed deltas for PRs, activities, and volume percent', () {
      const previous = PeriodSummary(
        sessionsScheduled: 3,
        sessionsCompleted: 2,
        totalVolume: 10000,
        prCount: 1,
        adHocActivityCount: 1,
      );
      const current = PeriodSummary(
        sessionsScheduled: 3,
        sessionsCompleted: 3,
        totalVolume: 12000,
        prCount: 3,
        adHocActivityCount: 3,
      );

      final comparison = comparePeriods(current: current, previous: previous);

      expect(comparison.prCountDelta, 2);
      expect(comparison.activityCountDelta, 2);
      expect(comparison.volumeDeltaPercent, 20);
      expect(comparison.volumeIsNew, isFalse);
    });

    test('a negative delta stays negative', () {
      const previous = PeriodSummary(
        sessionsScheduled: 0,
        sessionsCompleted: 0,
        totalVolume: 10000,
        prCount: 4,
      );
      const current = PeriodSummary(
        sessionsScheduled: 0,
        sessionsCompleted: 0,
        totalVolume: 5000,
        prCount: 1,
      );

      final comparison = comparePeriods(current: current, previous: previous);

      expect(comparison.prCountDelta, -3);
      expect(comparison.volumeDeltaPercent, -50);
    });

    test('zero previous volume with nonzero current volume is flagged as new, not divided by zero', () {
      const previous = PeriodSummary(
        sessionsScheduled: 0,
        sessionsCompleted: 0,
        totalVolume: 0,
        prCount: 0,
      );
      const current = PeriodSummary(
        sessionsScheduled: 0,
        sessionsCompleted: 0,
        totalVolume: 5000,
        prCount: 0,
      );

      final comparison = comparePeriods(current: current, previous: previous);

      expect(comparison.volumeIsNew, isTrue);
      expect(comparison.volumeDeltaPercent, 0);
    });

    test('both periods at zero volume is not treated as new', () {
      const summary = PeriodSummary(
        sessionsScheduled: 0,
        sessionsCompleted: 0,
        totalVolume: 0,
        prCount: 0,
      );

      final comparison = comparePeriods(current: summary, previous: summary);

      expect(comparison.volumeIsNew, isFalse);
      expect(comparison.volumeDeltaPercent, 0);
    });
  });

  group('formatCountDelta', () {
    test('positive gets an explicit plus sign', () {
      expect(formatCountDelta(3), '+3');
    });

    test('negative keeps its own minus sign', () {
      expect(formatCountDelta(-2), '-2');
    });

    test('zero renders as a neutral plus-minus', () {
      expect(formatCountDelta(0), '±0');
    });
  });

  group('formatPercentDelta', () {
    test('isNew always wins regardless of the percent value', () {
      expect(formatPercentDelta(999, isNew: true), 'new');
    });

    test('rounds to the nearest whole percent', () {
      expect(formatPercentDelta(12.6, isNew: false), '+13%');
      expect(formatPercentDelta(-8.4, isNew: false), '-8%');
    });

    test('zero renders as a neutral plus-minus', () {
      expect(formatPercentDelta(0, isNew: false), '±0%');
    });
  });
}
