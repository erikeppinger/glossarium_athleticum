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
}
