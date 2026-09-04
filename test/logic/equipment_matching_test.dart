import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/logic/equipment_matching.dart';

// Tested against real values from seed-data/strongman_exercise_database.csv
// rather than made-up examples - this parsing (AND '&' vs OR 'or', stripping
// parenthetical qualifiers, "no equipment needed") is the riskiest part of
// the equipment filter.
void main() {
  group('equipmentTags', () {
    test('a single plain piece of equipment', () {
      expect(equipmentTags('Barbell'), ['Barbell']);
    });

    test('strips a parenthetical qualifier, keeping the equipment itself', () {
      expect(equipmentTags('Barbell (Empty)'), ['Barbell']);
    });

    test('a bodyweight-only exercise needs no equipment at all', () {
      expect(equipmentTags('None (Bodyweight)'), isEmpty);
    });

    test('an AND compound ("&") yields both pieces', () {
      expect(equipmentTags('Barbell & Bench'), ['Barbell', 'Bench']);
      expect(equipmentTags('Yoke & Weight Plates'), ['Yoke', 'Weight Plates']);
    });

    test('an OR compound ("or") yields both alternatives', () {
      expect(equipmentTags('Kettlebell or Dumbbell'), [
        'Kettlebell',
        'Dumbbell',
      ]);
      expect(equipmentTags('PVC Pipe or Band'), ['PVC Pipe', 'Band']);
    });
  });

  group('isDoableWithEquipment', () {
    test('a plain piece of equipment is doable only if owned', () {
      expect(isDoableWithEquipment('Barbell', {'Barbell'}), isTrue);
      expect(isDoableWithEquipment('Barbell', {'Dumbbell'}), isFalse);
    });

    test('matching is case-insensitive', () {
      expect(isDoableWithEquipment('Barbell', {'barbell'}), isTrue);
    });

    test('a bodyweight-only exercise is always doable', () {
      expect(isDoableWithEquipment('None (Bodyweight)', {}), isTrue);
    });

    test('an AND compound needs every piece owned', () {
      expect(
        isDoableWithEquipment('Barbell & Bench', {'Barbell', 'Bench'}),
        isTrue,
      );
      expect(
        isDoableWithEquipment('Barbell & Bench', {'Barbell'}),
        isFalse,
        reason: 'missing the Bench half of the AND',
      );
    });

    test('an OR compound needs only one alternative owned', () {
      expect(
        isDoableWithEquipment('Kettlebell or Dumbbell', {'Dumbbell'}),
        isTrue,
      );
      expect(
        isDoableWithEquipment('Kettlebell or Dumbbell', {'Barbell'}),
        isFalse,
      );
    });

    test('owning nothing fails any exercise that needs real equipment', () {
      expect(isDoableWithEquipment('Barbell', {}), isFalse);
    });
  });
}
