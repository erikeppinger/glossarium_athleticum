import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/logic/plate_calculator.dart';

void main() {
  group('calculatePlateLoad', () {
    test('exact fit with standard kg plates', () {
      final result = calculatePlateLoad(targetWeight: 100, barWeight: 20);
      // Per side: 40kg -> 25 + 15
      expect(result.platesPerSide, [
        const PlateCount(size: 25, count: 1),
        const PlateCount(size: 15, count: 1),
      ]);
      expect(result.loadedWeight, 100);
      expect(result.shortfall, 0);
    });

    test('reports a shortfall when the target is not exactly reachable', () {
      final result = calculatePlateLoad(targetWeight: 101, barWeight: 20);
      // Per side target 40.5 - closest reachable with these plates is 40
      // per side (25+15), leaving a 1kg total shortfall.
      expect(result.loadedWeight, 100);
      expect(result.shortfall, 1);
    });

    test('target at or below the bar weight needs no plates', () {
      final atBar = calculatePlateLoad(targetWeight: 20, barWeight: 20);
      expect(atBar.platesPerSide, isEmpty);
      expect(atBar.loadedWeight, 20);
      expect(atBar.shortfall, 0);

      final belowBar = calculatePlateLoad(targetWeight: 15, barWeight: 20);
      expect(belowBar.platesPerSide, isEmpty);
      expect(belowBar.loadedWeight, 20);
      expect(belowBar.shortfall, 0);
    });

    test('lbs plate set', () {
      final result = calculatePlateLoad(
        targetWeight: 225,
        barWeight: 45,
        availablePlates: standardPlatesLbs,
      );
      // Per side: 90lbs -> greedy takes the largest plate as many times as
      // possible first, so 2x45 rather than 45+35+10 (both sum to 90).
      expect(result.platesPerSide, [const PlateCount(size: 45, count: 2)]);
      expect(result.loadedWeight, 225);
      expect(result.shortfall, 0);
    });

    test('uses multiple plates of the same size when needed', () {
      final result = calculatePlateLoad(targetWeight: 140, barWeight: 20);
      // Per side: 60kg -> 25 + 25 + 10
      expect(result.platesPerSide, [
        const PlateCount(size: 25, count: 2),
        const PlateCount(size: 10, count: 1),
      ]);
      expect(result.loadedWeight, 140);
      expect(result.shortfall, 0);
    });

    test('a custom plate size not in the standard set can still be used', () {
      // Reported live: not every gym has 25kg plates, some have 40kg ones.
      final result = calculatePlateLoad(
        targetWeight: 100,
        barWeight: 20,
        availablePlates: const [40.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25],
      );
      // Per side: 40kg -> a single 40kg plate exactly.
      expect(result.platesPerSide, [const PlateCount(size: 40, count: 1)]);
      expect(result.loadedWeight, 100);
      expect(result.shortfall, 0);
    });
  });

  group('formatPlateWeight', () {
    test('whole numbers show with no decimal', () {
      expect(formatPlateWeight(20), '20');
    });

    test('a standard half-kilogram shows one decimal', () {
      expect(formatPlateWeight(2.5), '2.5');
    });

    test(
      'a 1.25kg "quarter" plate keeps both decimals, rather than rounding '
      'to a materially wrong 1.3',
      () {
        expect(formatPlateWeight(1.25), '1.25');
      },
    );
  });
}
