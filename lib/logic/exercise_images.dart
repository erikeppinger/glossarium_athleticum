/// An exercise can carry at most this many photos - a plain bound rather
/// than anything device-specific: images are added at runtime (never
/// bundled into the app itself, see exercises_table.dart's own doc comment
/// on why), so app-size isn't the concern; this is purely about keeping the
/// gallery UI and a single exercise's on-disk footprint from growing
/// unbounded for someone who'd otherwise photograph every session.
const maxExerciseImages = 5;

/// Splits the comma-separated `imagePaths` column back into filenames, in
/// display order. Empty (not an error) for null/blank input.
List<String> parseImagePaths(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  return raw
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

/// The inverse of [parseImagePaths] - null (not an empty string) for an
/// empty list, matching the column's own "no images" representation.
String? joinImagePaths(List<String> paths) =>
    paths.isEmpty ? null : paths.join(',');
