/// Why a prescribed exercise was skipped mid-session. Stored as [key] in
/// `SkippedExercises.reason` (null when the trainee didn't pick one), so the
/// enum's own names can change without touching stored data.
enum SkipReason {
  machineBusy('machine_busy', 'Machine busy'),
  painOrInjury('pain_or_injury', 'Pain or injury'),
  noEquipment('no_equipment', 'No equipment'),
  other('other', 'Other');

  const SkipReason(this.key, this.label);

  final String key;
  final String label;

  static SkipReason? fromKey(String? key) {
    for (final reason in values) {
      if (reason.key == key) return reason;
    }
    return null;
  }
}
