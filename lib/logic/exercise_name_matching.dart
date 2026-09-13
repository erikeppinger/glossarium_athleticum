/// Shared exercise-name matching logic, used by both the spreadsheet
/// importer (Phase 1) and the JSON plan/backup importer (Phase 3) so the
/// two don't drift apart with subtly different normalization rules.
library;

/// Maps common accented/ligature Latin letters to a plain ASCII base letter.
/// Deliberately a fixed table, not full Unicode NFKD decomposition (Dart's
/// core `String` has no built-in normalizer) - covers the diacritics/
/// ligatures actually seen in real exercise names (German, French, Spanish,
/// Portuguese, Scandinavian, Polish/Czech) without pulling in a dependency
/// just for this. Keys are lowercase only - callers lowercase first.
const Map<String, String> _diacriticFold = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ā': 'a', 'ą': 'a',
  'ç': 'c', 'ć': 'c', 'č': 'c',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ę': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i',
  'ñ': 'n', 'ń': 'n',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o', 'ō': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u',
  'ý': 'y', 'ÿ': 'y',
  'ß': 'ss',
  'æ': 'ae',
  'œ': 'oe',
  'ł': 'l',
  'ś': 's', 'š': 's',
  'ź': 'z', 'ż': 'z', 'ž': 'z',
};

/// Folds every diacritic/ligature in [_diacriticFold] to its plain-ASCII
/// base form (e.g. `ü` -> `u`, `ß` -> `ss`). [lowercased] is assumed already
/// lowercase - the map only has lowercase keys.
String foldDiacritics(String lowercased) {
  final buffer = StringBuffer();
  for (final rune in lowercased.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(_diacriticFold[ch] ?? ch);
  }
  return buffer.toString();
}

/// Normalizes a name for exact-after-normalization matching: lowercase,
/// diacritics/ligatures folded to their plain-ASCII base form (see
/// [foldDiacritics]) so cosmetic accent differences don't block a match
/// (e.g. "Zancada Búlgara" now matches a plan row spelled "Zancada
/// Bulgara"), apostrophes stripped, remaining punctuation/whitespace
/// collapsed to single spaces. Deliberately not fuzzy/edit-distance matching
/// - this never silently matches the wrong exercise, it only tolerates
/// cosmetic differences in the same name. Note this still won't match a
/// fully phonetic ASCII respelling like "ue" for "ü" (e.g.
/// "Uberkopfdruecken" for "Überkopfdrücken") - that's a different,
/// locale-specific transliteration convention, not a diacritic, and folding
/// for it risked false-positive matches across unrelated words.
String normalizeExerciseName(String name) => foldDiacritics(name.toLowerCase())
    .replaceAll("'", '')
    .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
    .trim();
