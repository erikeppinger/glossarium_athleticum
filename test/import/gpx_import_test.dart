import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/import/gpx_import.dart';

const _sampleGpx = '''
<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="Test">
  <trk>
    <name>Morning Run</name>
    <trkseg>
      <trkpt lat="51.5000" lon="-0.1000">
        <ele>10</ele>
        <time>2026-08-20T07:00:00Z</time>
      </trkpt>
      <trkpt lat="51.5010" lon="-0.1000">
        <ele>12</ele>
        <time>2026-08-20T07:05:00Z</time>
      </trkpt>
      <trkpt lat="51.5020" lon="-0.1000">
        <ele>11</ele>
        <time>2026-08-20T07:10:00Z</time>
      </trkpt>
    </trkseg>
  </trk>
</gpx>
''';

const _gpxWithoutTimes = '''
<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1">
  <trk>
    <trkseg>
      <trkpt lat="51.5000" lon="-0.1000"></trkpt>
      <trkpt lat="51.5010" lon="-0.1000"></trkpt>
    </trkseg>
  </trk>
</gpx>
''';

const _gpxWithMultipleSegments = '''
<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1">
  <trk>
    <trkseg>
      <trkpt lat="0" lon="0"><time>2026-08-20T07:00:00Z</time></trkpt>
      <trkpt lat="0" lon="0.5"><time>2026-08-20T07:05:00Z</time></trkpt>
    </trkseg>
    <trkseg>
      <trkpt lat="0" lon="0.5"><time>2026-08-20T07:06:00Z</time></trkpt>
      <trkpt lat="0" lon="1"><time>2026-08-20T07:10:00Z</time></trkpt>
    </trkseg>
  </trk>
</gpx>
''';

const _gpxWithMetadataTimeOnly = '''
<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1">
  <metadata>
    <time>2026-08-20T07:00:00Z</time>
  </metadata>
  <trk>
    <trkseg>
      <trkpt lat="51.5000" lon="-0.1000"></trkpt>
      <trkpt lat="51.5010" lon="-0.1000"></trkpt>
    </trkseg>
  </trk>
</gpx>
''';

void main() {
  group('parseGpx', () {
    test('extracts name, start time, duration, and distance', () {
      final activity = parseGpx(_sampleGpx);
      expect(activity.name, 'Morning Run');
      expect(activity.startTime, DateTime.utc(2026, 8, 20, 7, 0, 0));
      expect(activity.durationSec, 600); // 10 minutes
      expect(activity.distanceMeters, greaterThan(0));
    });

    test('computes distance even with no timestamps at all', () {
      final activity = parseGpx(_gpxWithoutTimes);
      expect(activity.durationSec, isNull);
      expect(activity.startTime, isNull);
      expect(activity.distanceMeters, greaterThan(0));
    });

    test('falls back to metadata time when track points have none', () {
      final activity = parseGpx(_gpxWithMetadataTimeOnly);
      expect(activity.startTime, DateTime.utc(2026, 8, 20, 7, 0, 0));
      expect(activity.durationSec, isNull);
    });

    test('flattens points across multiple trkseg elements into one track', () {
      final activity = parseGpx(_gpxWithMultipleSegments);
      // 4 points spanning 0..1 degree of longitude at the equator, ~111.2km
      // (this project's haversine uses Earth's mean radius - see geo_test.dart).
      expect(activity.distanceMeters, closeTo(111195, 50));
      expect(activity.durationSec, 600); // 07:00 to 07:10
    });

    test('name is null when the track has none', () {
      final activity = parseGpx(_gpxWithoutTimes);
      expect(activity.name, isNull);
    });

    test('throws for a file with no track points', () {
      expect(
        () => parseGpx('<?xml version="1.0"?><gpx version="1.1"></gpx>'),
        throwsA(isA<GpxParseException>()),
      );
    });

    test('throws for content that is not XML at all', () {
      expect(
        () => parseGpx('this is not xml'),
        throwsA(isA<GpxParseException>()),
      );
    });
  });
}
