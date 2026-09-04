import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/logic/geo.dart';

void main() {
  group('haversineDistanceMeters', () {
    test('the same point is zero distance apart', () {
      expect(haversineDistanceMeters(51.5, -0.1, 51.5, -0.1), 0);
    });

    test('one degree of longitude at the equator is about 111.2 km', () {
      // 2*pi*6371000 (this function's mean Earth radius) / 360 degrees -
      // deliberately the mean-radius figure (111.2km), not the
      // WGS84-equatorial-radius one (111.32km) that's more commonly quoted;
      // haversine's whole premise is a spherical approximation, so mean
      // radius is the right constant to check it against here.
      final meters = haversineDistanceMeters(0, 0, 0, 1);
      expect(meters, closeTo(111195, 5));
    });

    test('one degree of latitude anywhere is about 111.2 km', () {
      final meters = haversineDistanceMeters(10, 20, 11, 20);
      expect(meters, closeTo(111195, 5));
    });

    test('is symmetric regardless of point order', () {
      final a = haversineDistanceMeters(48.8566, 2.3522, 51.5074, -0.1278);
      final b = haversineDistanceMeters(51.5074, -0.1278, 48.8566, 2.3522);
      expect(a, closeTo(b, 1e-6));
    });
  });
}
