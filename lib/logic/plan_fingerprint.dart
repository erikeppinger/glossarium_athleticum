import 'dart:convert';

/// A short fingerprint of a plan's *contents* - what a trainer writes: the
/// name, notes, sessions and their exercises (with supersets). Computed from
/// the plan JSON shape (`planToJson` / a plan file), so a plan on this device
/// and an incoming file can be compared.
///
/// Deliberately left out: ids and timestamps, every exercise id (they differ
/// between devices for the same exercise), and scheduled dates - a client
/// putting sessions on their calendar hasn't changed the plan.
String planContentFingerprint(Map<String, dynamic> planJson) {
  String text(Object? value) => (value as String?) ?? '';

  final sessions = <List<Object?>>[];
  for (final week in planJson['weeks'] as List? ?? const []) {
    for (final session in (week as Map)['sessions'] as List? ?? const []) {
      final s = session as Map;
      final exercises = [
        for (final exercise in s['exercises'] as List? ?? const [])
          [
            (exercise as Map)['order'],
            text(exercise['exercise_name']),
            exercise['sets'],
            text(exercise['reps']),
            text(exercise['weight_intensity']),
            exercise['rest_sec'],
            text(exercise['notes']),
            text(exercise['video_url']),
            exercise['superset_group_id'],
          ],
      ]..sort((a, b) => (a[0] as int).compareTo(b[0] as int));
      sessions.add([
        week['week_number'],
        text(s['day']),
        text(s['session_name']),
        exercises,
      ]);
    }
  }
  sessions.sort((a, b) {
    final week = (a[0] as int).compareTo(b[0] as int);
    if (week != 0) return week;
    final day = (a[1] as String).compareTo(b[1] as String);
    if (day != 0) return day;
    return (a[2] as String).compareTo(b[2] as String);
  });

  final canonical = jsonEncode([
    text(planJson['name']),
    text(planJson['notes']),
    sessions,
  ]);
  return _fnv1a64(canonical);
}

/// 64-bit FNV-1a over the UTF-8 bytes, as 16 hex digits. Not a security
/// hash - it only has to tell "same contents" from "edited".
String _fnv1a64(String input) {
  var hash = 0xcbf29ce484222325;
  const prime = 0x100000001b3;
  for (final byte in utf8.encode(input)) {
    hash ^= byte;
    // Dart's native ints wrap at 64 bits, which is what FNV-1a wants.
    hash *= prime;
  }
  return hash.toUnsigned(64).toRadixString(16).padLeft(16, '0');
}
