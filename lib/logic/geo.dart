import 'dart:math';

/// Great-circle distance between two lat/lon points, in meters - the
/// standard haversine formula. Good enough for summing a GPS track's total
/// distance (the error versus an ellipsoidal model is negligible at walk/
/// run/ride distances); not meant for surveying-grade precision.
const _earthRadiusMeters = 6371000.0;

double haversineDistanceMeters(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  final dLat = _radians(lat2 - lat1);
  final dLon = _radians(lon2 - lon1);
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_radians(lat1)) *
          cos(_radians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return _earthRadiusMeters * c;
}

double _radians(double degrees) => degrees * pi / 180;
