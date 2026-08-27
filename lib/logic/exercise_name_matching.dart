/// Shared exercise-name matching logic, used by both the spreadsheet
/// importer (Phase 1) and the JSON plan/backup importer (Phase 3) so the
/// two don't drift apart with subtly different normalization rules.
library;

/// Normalizes a name for exact-after-normalization matching: lowercase,
/// apostrophes stripped (so "Farmer's" and "Farmers" match), remaining
/// punctuation/whitespace collapsed to single spaces. Deliberately not
/// fuzzy/edit-distance matching - this never silently matches the wrong
/// exercise, it only tolerates cosmetic differences in the same name.
String normalizeExerciseName(String name) => name
    .toLowerCase()
    .replaceAll("'", '')
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .trim();
