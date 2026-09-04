import 'package:xml/xml.dart';

import '../logic/geo.dart';

/// Thrown for a file that isn't parseable as GPX at all (not XML, or has no
/// track points) - there's no per-point recovery the way the CSV plan
/// importer has, since a GPX file with no usable points has nothing to
/// import.
class GpxParseException implements Exception {
  final String message;
  const GpxParseException(this.message);
  @override
  String toString() => message;
}

/// What a GPX file boils down to for logging as an ad-hoc activity - see
/// `lib/features/calendar/calendar_screen.dart`'s "Log activity" flow, which
/// this feeds into (pre-filling the same dialog rather than saving directly,
/// so the user can review/correct the name before it's recorded).
///
/// [durationSec] is null if the file has fewer than two timestamped track
/// points - not every GPX file carries `<time>` per point (some route-only
/// exports omit it entirely), and a missing duration shouldn't block
/// importing the distance that *is* available.
class GpxActivity {
  final String? name;
  final DateTime? startTime;
  final double? durationSec;
  final double distanceMeters;

  const GpxActivity({
    this.name,
    this.startTime,
    this.durationSec,
    required this.distanceMeters,
  });
}

/// Parses a GPX file's track points into [GpxActivity]. Standard GPX 1.1
/// `trk`/`trkseg`/`trkpt` structure, which is what phone apps (Strava,
/// Google Fit) and GPS watches/bike computers (Garmin and similar) both
/// export - points from every `trkseg` in the file are flattened into one
/// continuous track rather than kept separate, since "how many segments the
/// recording device split this into" isn't something an ad-hoc activity log
/// needs to represent.
GpxActivity parseGpx(String xmlContent) {
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(xmlContent);
  } on XmlException catch (e) {
    throw GpxParseException('Not a valid GPX file: ${e.message}');
  }

  final trackPoints = doc.findAllElements('trkpt').toList();
  if (trackPoints.isEmpty) {
    throw const GpxParseException(
      'This file has no track points to import.',
    );
  }

  double totalDistance = 0;
  double? prevLat, prevLon;
  DateTime? firstTime, lastTime;

  for (final point in trackPoints) {
    final lat = double.tryParse(point.getAttribute('lat') ?? '');
    final lon = double.tryParse(point.getAttribute('lon') ?? '');
    if (lat == null || lon == null) continue;

    if (prevLat != null && prevLon != null) {
      totalDistance += haversineDistanceMeters(prevLat, prevLon, lat, lon);
    }
    prevLat = lat;
    prevLon = lon;

    final timeText = point.getElement('time')?.innerText.trim();
    final time = timeText == null ? null : DateTime.tryParse(timeText);
    if (time != null) {
      firstTime ??= time;
      lastTime = time;
    }
  }

  final name = doc
      .findAllElements('trk')
      .firstOrNull
      ?.getElement('name')
      ?.innerText
      .trim();

  final durationSec = (firstTime != null && lastTime != null)
      ? lastTime.difference(firstTime).inSeconds.toDouble()
      : null;

  return GpxActivity(
    name: (name == null || name.isEmpty) ? null : name,
    startTime: firstTime ?? _metadataTime(doc),
    durationSec: durationSec != null && durationSec > 0 ? durationSec : null,
    distanceMeters: totalDistance,
  );
}

DateTime? _metadataTime(XmlDocument doc) {
  final text = doc
      .findAllElements('metadata')
      .firstOrNull
      ?.getElement('time')
      ?.innerText
      .trim();
  return text == null ? null : DateTime.tryParse(text);
}
