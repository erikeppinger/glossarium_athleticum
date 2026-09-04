import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/logic/body_weight_trend.dart';
import 'package:training_app/logic/summary_period.dart';

void main() {
  PeriodRange weekRange() =>
      (start: DateTime(2026, 8, 10), end: DateTime(2026, 8, 17));

  group('computeBodyWeightChange', () {
    test('returns null with fewer than two readings', () {
      expect(computeBodyWeightChange(readings: [], range: weekRange()), isNull);
      expect(
        computeBodyWeightChange(
          readings: [(measuredAt: DateTime(2026, 8, 12), weightKg: 80)],
          range: weekRange(),
        ),
        isNull,
      );
    });

    test(
      'compares against the last reading before the period when one exists',
      () {
        final change = computeBodyWeightChange(
          readings: [
            (measuredAt: DateTime(2026, 8, 1), weightKg: 82), // before period
            (measuredAt: DateTime(2026, 8, 12), weightKg: 80), // in period
          ],
          range: weekRange(),
        );
        expect(change, isNotNull);
        expect(change!.deltaKg, closeTo(-2, 1e-9));
        expect(change.currentKg, 80);
        expect(change.baselineDate, DateTime(2026, 8, 1));
      },
    );

    test(
      'falls back to the earliest reading when nothing exists before the period',
      () {
        // Someone's very first two weigh-ins, both inside the first week
        // they ever tracked - no reading exists before range.start at all.
        final change = computeBodyWeightChange(
          readings: [
            (measuredAt: DateTime(2026, 8, 11), weightKg: 80),
            (measuredAt: DateTime(2026, 8, 14), weightKg: 79),
          ],
          range: weekRange(),
        );
        expect(change, isNotNull);
        expect(change!.deltaKg, closeTo(-1, 1e-9));
        expect(change.baselineDate, DateTime(2026, 8, 11));
      },
    );

    test('a weight gain reports a positive delta', () {
      final change = computeBodyWeightChange(
        readings: [
          (measuredAt: DateTime(2026, 8, 1), weightKg: 78),
          (measuredAt: DateTime(2026, 8, 12), weightKg: 80),
        ],
        range: weekRange(),
      );
      expect(change!.deltaKg, closeTo(2, 1e-9));
    });

    test('ignores readings after the period end', () {
      final change = computeBodyWeightChange(
        readings: [
          (measuredAt: DateTime(2026, 8, 1), weightKg: 82),
          (measuredAt: DateTime(2026, 8, 12), weightKg: 80),
          (measuredAt: DateTime(2026, 8, 20), weightKg: 999), // after range
        ],
        range: weekRange(),
      );
      expect(change!.currentKg, 80);
    });

    test('is order-independent - readings need not be pre-sorted', () {
      final change = computeBodyWeightChange(
        readings: [
          (measuredAt: DateTime(2026, 8, 12), weightKg: 80),
          (measuredAt: DateTime(2026, 8, 1), weightKg: 82),
        ],
        range: weekRange(),
      );
      expect(change!.deltaKg, closeTo(-2, 1e-9));
    });
  });
}
