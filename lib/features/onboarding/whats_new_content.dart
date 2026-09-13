import 'package:flutter/material.dart';

/// Bump this whenever [whatsNewItems] gains a new entry worth surfacing to
/// existing users - see `AppPreferences.lastSeenWhatsNewRevision`'s own doc
/// comment for how the comparison works. Not tied to `pubspec.yaml`'s own
/// version/build number - this project ships informally (Dropbox builds,
/// not app-store releases with a disciplined version bump per release), so
/// a separate, hand-maintained counter is the honest thing to gate on
/// rather than pretending a version number means something it doesn't here.
const currentWhatsNewRevision = 1;

class WhatsNewItem {
  final IconData icon;
  final String title;
  final String body;

  const WhatsNewItem({
    required this.icon,
    required this.title,
    required this.body,
  });
}

/// Kept as a flat, ever-growing list rather than "one list per revision" -
/// a device that's been away for several revisions should see everything
/// it missed in one go, not just the latest bump. Add new items to the end;
/// never remove or reorder existing ones, since older entries are still
/// exactly what a returning device needs to see.
const whatsNewItems = [
  WhatsNewItem(
    icon: Icons.today,
    title: 'A Today tab',
    body:
        "The app now opens on a Today dashboard - your next scheduled "
        "session, this week's summary, and quick actions like Random "
        "workout and Log activity, all in one place.",
  ),
  WhatsNewItem(
    icon: Icons.calculate_outlined,
    title: 'Plate calculator',
    body:
        'Figure out which plates to load for a target weight - available '
        'from the Exercise Library toolbar. Tell it which plates you '
        'actually have in Settings if your gym is missing a size.',
  ),
  WhatsNewItem(
    icon: Icons.percent,
    title: 'Estimated 1RM and percentage prescriptions',
    body:
        'History now shows an estimated one-rep max per exercise. Plans can '
        'prescribe a percentage (like "70%") instead of a flat weight, and '
        'execution mode resolves it against your own numbers automatically.',
  ),
  WhatsNewItem(
    icon: Icons.repeat,
    title: 'Supersets and circuits',
    body:
        'Group exercises in a plan to train them back-to-back, round by '
        'round, with one shared rest after each round - build a plan\'s '
        'session or edit an existing one to set this up.',
  ),
  WhatsNewItem(
    icon: Icons.shuffle,
    title: 'Random workout generator',
    body:
        "No plan for today? Generate one on the spot - pick how many "
        "warm-up, legs, upper-body, and core exercises you want, optionally "
        "limited to equipment you actually have.",
  ),
  WhatsNewItem(
    icon: Icons.visibility_off_outlined,
    title: 'Focus mode',
    body:
        "An opt-in switch (Settings > Focus mode) for anyone who'd rather "
        "just train without seeing progress charts, PRs, or streaks. "
        "Nothing is deleted - it's just not shown while this is on.",
  ),
  WhatsNewItem(
    icon: Icons.desktop_windows_outlined,
    title: 'A Windows desktop app',
    body:
        'Training App now runs on Windows too, with the same rest timer, '
        'notifications, and data as the phone app.',
  ),
];
