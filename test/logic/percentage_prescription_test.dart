import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/logic/percentage_prescription.dart';

void main() {
  group('isPercentagePrescription', () {
    test('recognizes a plain percentage', () {
      expect(isPercentagePrescription('70%'), isTrue);
      expect(isPercentagePrescription('70.5%'), isTrue);
      expect(isPercentagePrescription(' 70 % '), isTrue);
    });

    test('rejects flat weights, ranges, and free text', () {
      expect(isPercentagePrescription('60kg'), isFalse);
      expect(isPercentagePrescription('60-70kg'), isFalse);
      expect(isPercentagePrescription('bodyweight'), isFalse);
      expect(isPercentagePrescription(''), isFalse);
      expect(isPercentagePrescription('%'), isFalse);
    });
  });

  group('parsePercentage', () {
    test('extracts the numeric value', () {
      expect(parsePercentage('70%'), 70);
      expect(parsePercentage('72.5%'), 72.5);
    });

    test('returns null for a non-percentage string', () {
      expect(parsePercentage('60kg'), isNull);
    });
  });

  group('resolvePercentageWeight', () {
    test('resolves against a known 1RM', () {
      expect(
        resolvePercentageWeight(percent: 70, estimatedOneRepMaxKg: 100),
        70,
      );
    });

    test('returns null with no history yet', () {
      expect(
        resolvePercentageWeight(percent: 70, estimatedOneRepMaxKg: null),
        isNull,
      );
    });

    test('returns null for a non-positive 1RM', () {
      expect(
        resolvePercentageWeight(percent: 70, estimatedOneRepMaxKg: 0),
        isNull,
      );
    });
  });
}
