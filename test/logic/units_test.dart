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

  group('formatDurationSec', () {
    test('formats under an hour as minutes', () {
      expect(formatDurationSec(1800), '30 min');
    });

    test('formats an exact hour with no minutes remainder', () {
      expect(formatDurationSec(3600), '1 h');
    });

    test('formats over an hour with a minutes remainder', () {
      expect(formatDurationSec(5400), '1 h 30 min');
    });
  });

  group('formatDistanceMeters', () {
    test('formats under a kilometre in metres', () {
      expect(formatDistanceMeters(450), '450 m');
    });

    test('formats an exact kilometre with no decimal', () {
      expect(formatDistanceMeters(3000), '3 km');
    });

    test('formats a partial kilometre with one decimal', () {
      expect(formatDistanceMeters(3200), '3.2 km');
    });
  });

  group('formatTimeOfDay', () {
    test('24-hour pads hour and minute to two digits', () {
      expect(formatTimeOfDay(8, 0, use24Hour: true), '08:00');
      expect(formatTimeOfDay(23, 5, use24Hour: true), '23:05');
    });

    test('12-hour midnight and noon both show 12, not 0', () {
      expect(formatTimeOfDay(0, 0, use24Hour: false), '12:00 AM');
      expect(formatTimeOfDay(12, 0, use24Hour: false), '12:00 PM');
    });

    test('12-hour morning and evening hours convert and label correctly', () {
      expect(formatTimeOfDay(8, 30, use24Hour: false), '8:30 AM');
      expect(formatTimeOfDay(20, 15, use24Hour: false), '8:15 PM');
    });

    test('12-hour keeps minute zero-padded', () {
      expect(formatTimeOfDay(9, 5, use24Hour: false), '9:05 AM');
    });
  });
}
