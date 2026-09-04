/// Pure equipment-matching logic for the exercise library's "My equipment"
/// filter (Phase 6). Deliberately DB/Flutter-free, matching this project's
/// `lib/logic/` convention.
///
/// `Exercises.equipment` is rich free text, not a normalized tag - e.g.
/// "Barbell & Bench" (needs both), "Kettlebell or Dumbbell" (needs either),
/// "Barbell (Empty)" (one piece of equipment, with a qualifier that isn't
/// itself something to "own"), "None (Bodyweight)" (needs nothing). These
/// two functions parse that shape rather than requiring a rewrite of the
/// underlying data.
library;

final RegExp _orSplit = RegExp(r'\s+or\s+', caseSensitive: false);
final RegExp _parenthetical = RegExp(r'\s*\([^)]*\)');

bool _needsNothing(String raw) =>
    raw.trim().toLowerCase().startsWith('none');

/// One raw equipment string split into its AND-groups, each an OR-group of
/// alternative atomic equipment names - e.g. "Barbell & Kettlebell or
/// Dumbbell" (hypothetical) would be `[["Barbell"], ["Kettlebell", "Dumbbell"]]`.
/// Every equipment string actually in this app's data has all its ANDs before
/// any ORs within a group, so this doesn't need real operator-precedence
/// handling - it just splits on `&` first, then `or` within each piece.
List<List<String>> _andGroups(String raw) {
  return raw.split('&').map((group) {
    final cleaned = group.replaceAll(_parenthetical, '').trim();
    return cleaned
        .split(_orSplit)
        .map((alt) => alt.trim())
        .where((alt) => alt.isNotEmpty)
        .toList();
  }).where((group) => group.isNotEmpty).toList();
}

/// Every distinct atomic equipment name mentioned in [raw], regardless of
/// AND/OR structure - used to build the onboarding equipment picker's list
/// of choices from the library's actual data rather than a hand-maintained
/// duplicate list. Returns nothing for a bodyweight-only exercise, since
/// "no equipment" isn't itself a piece of equipment to select.
List<String> equipmentTags(String raw) {
  if (_needsNothing(raw)) return const [];
  return [for (final group in _andGroups(raw)) ...group];
}

/// Whether an exercise needing [raw] equipment can be done with [owned]
/// (case-insensitive). Every AND-group must have at least one of its
/// alternatives in [owned]; a bodyweight-only exercise is always doable
/// regardless of what's owned.
bool isDoableWithEquipment(String raw, Set<String> owned) {
  if (_needsNothing(raw)) return true;
  final ownedLower = owned.map((e) => e.toLowerCase()).toSet();
  final groups = _andGroups(raw);
  if (groups.isEmpty) return true;
  return groups.every(
    (group) => group.any((alt) => ownedLower.contains(alt.toLowerCase())),
  );
}
