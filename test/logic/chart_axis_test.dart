import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/logic/chart_axis.dart';

void main() {
  group('niceAxis', () {
    test('the top is always an exact multiple of the interval', () {
      for (final value in [3.0, 17.0, 88.0, 240.0, 880.0, 1056.0, 12345.0]) {
        final axis = niceAxis(value);
        final steps = axis.max / axis.interval;
        expect(
          steps,
          closeTo(steps.roundToDouble(), 1e-9),
          reason: 'max ${axis.max} is not a clean multiple of ${axis.interval} '
              'for input $value',
        );
      }
    });

    test('the top always fits the data', () {
      for (final value in [3.0, 17.0, 88.0, 880.0, 1056.0]) {
        expect(niceAxis(value).max, greaterThanOrEqualTo(value));
      }
    });

    test('intervals snap to 1/2/5 times a power of ten', () {
      for (final value in [3.0, 17.0, 88.0, 240.0, 880.0, 12345.0]) {
        final interval = niceAxis(value).interval;
        final mantissa = interval.toStringAsExponential().split('e').first;
        expect(
          double.parse(mantissa),
          anyOf(1.0, 2.0, 5.0),
          reason: 'interval $interval for $value is not a round step',
        );
      }
    });

    test('the 880 case that produced overlapping "1K"/"1.1K" labels', () {
      // fl_chart's default interval on maxY 1056 put two labels almost on
      // top of each other. Making the top an exact multiple of the step
      // means the max IS a gridline, so no stray max label can crowd one.
      final axis = niceAxis(880);
      expect(axis.max, 1000);
      expect(axis.interval, 200);
    });

    test('the top is a gridline, so no max label sits beside a tick', () {
      for (final value in [3.0, 17.0, 88.0, 880.0, 1056.0, 12345.0]) {
        final axis = niceAxis(value);
        expect(
          axis.max % axis.interval,
          closeTo(0, 1e-9),
          reason: 'the axis top must land exactly on a tick for $value',
        );
      }
    });

    test('gridlines stay readable in number - never just one or two', () {
      for (final value in [3.0, 17.0, 88.0, 240.0, 880.0, 12345.0]) {
        final axis = niceAxis(value);
        final lines = axis.max / axis.interval;
        expect(
          lines,
          inInclusiveRange(3, 8),
          reason: 'got $lines gridlines for $value',
        );
      }
    });

    test('a zero/absent metric still gets a usable axis', () {
      final axis = niceAxis(0);
      expect(axis.max, greaterThan(0));
      expect(axis.interval, greaterThan(0));
    });

    test('small integer counts get an integer-friendly axis', () {
      final axis = niceAxis(3);
      expect(axis.max, 4);
      expect(axis.interval, 1);
    });

    test('leaves headroom so the tallest bar does not touch the ceiling', () {
      for (final value in [17.0, 88.0, 880.0]) {
        expect(niceAxis(value).max, greaterThan(value));
      }
    });
  });
}
