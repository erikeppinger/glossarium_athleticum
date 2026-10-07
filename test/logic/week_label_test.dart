import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/logic/week_label.dart';

void main() {
  group('showsWeekNumber', () {
    test('hides the week for a single-week plan', () {
      expect(showsWeekNumber([1, 1, 1]), isFalse);
      // A lone week that isn't week 1 carries no information either.
      expect(showsWeekNumber([3]), isFalse);
    });

    test('shows the week once a plan has two or more', () {
      expect(showsWeekNumber([1, 2]), isTrue);
      expect(showsWeekNumber([1, 1, 4]), isTrue);
    });

    test('an empty plan shows nothing to hide', () {
      expect(showsWeekNumber(const []), isFalse);
    });
  });

  group('joinSessionLabel', () {
    test('joins the parts with a bullet', () {
      expect(
        joinSessionLabel(['Week 2', 'Mon', 'Push Day']),
        'Week 2 • Mon • Push Day',
      );
    });

    test('a left-out week leaves no stray separator', () {
      expect(joinSessionLabel(['Day 3', 'Block 3']), 'Day 3 • Block 3');
      expect(
        joinSessionLabel([null, 'Day 3', '', 'Block 3']),
        'Day 3 • Block 3',
      );
    });
  });
}
