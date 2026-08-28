import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/logic/units.dart';

void main() {
  group('kgToDisplay / displayToKg', () {
    test('kg unit is a no-op', () {
      expect(kgToDisplay(100, WeightUnit.kg), 100);
      expect(displayToKg(100, WeightUnit.kg), 100);
    });

    test('converts kg to lbs and back', () {
      final lbs = kgToDisplay(100, WeightUnit.lbs);
      expect(lbs, closeTo(220.46, 0.01));
      expect(displayToKg(lbs, WeightUnit.lbs), closeTo(100, 0.001));
    });
  });

  group('formatWeightNumber', () {
    test('drops decimals for whole numbers', () {
      expect(formatWeightNumber(60.0), '60');
    });

    test('keeps one decimal place otherwise', () {
      expect(formatWeightNumber(60.5), '60.5');
    });
  });

  group('formatWeightInUnit', () {
    test('formats kg with kg suffix', () {
      expect(formatWeightInUnit(60, WeightUnit.kg), '60kg');
    });

    test('converts and formats lbs with lbs suffix', () {
      expect(formatWeightInUnit(100, WeightUnit.lbs), '220.5lbs');
    });
  });

  group('lengths (body measurements)', () {
    test('cm unit is a no-op', () {
      expect(cmToDisplay(88, WeightUnit.kg), 88);
      expect(displayToCm(88, WeightUnit.kg), 88);
    });

    test('converts cm to inches and back', () {
      final inches = cmToDisplay(88, WeightUnit.lbs);
      expect(inches, closeTo(34.65, 0.01));
      expect(displayToCm(inches, WeightUnit.lbs), closeTo(88, 0.001));
    });

    test('unit label follows the weight-unit preference', () {
      expect(lengthUnitLabel(WeightUnit.kg), 'cm');
      expect(lengthUnitLabel(WeightUnit.lbs), 'in');
    });

    test('formats with the right suffix', () {
      expect(formatLengthInUnit(88, WeightUnit.kg), '88cm');
      // 88 cm is 34.6457 in, which rounds to one decimal as 34.6.
      expect(formatLengthInUnit(88, WeightUnit.lbs), '34.6in');
    });

    test('a round-trip through the display unit is lossless', () {
      for (final cm in [70.0, 88.5, 102.0]) {
        for (final unit in WeightUnit.values) {
          expect(
            displayToCm(cmToDisplay(cm, unit), unit),
            closeTo(cm, 1e-9),
          );
        }
      }
    });
  });
}
