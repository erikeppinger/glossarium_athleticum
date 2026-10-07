/// Whether session labels should name the week. A plan with a single week
/// is usually a rotation (e.g. nine training blocks done one after another
/// over however long it takes), not a week to finish - there "Week 1"
/// carries no information and reads as if every session were due this week.
bool showsWeekNumber(Iterable<int> weekNumbers) =>
    weekNumbers.toSet().length > 1;

/// Joins label parts with " • ", skipping null/empty ones - so a hidden week
/// (or an "Any" day a caller blanks out) leaves no stray separator.
String joinSessionLabel(List<String?> parts) =>
    parts.where((part) => part != null && part.isNotEmpty).join(' • ');
