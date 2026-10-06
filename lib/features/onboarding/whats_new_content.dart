import 'package:flutter/material.dart';

/// Bump this whenever [whatsNewItems] gains a new entry worth surfacing to
/// existing users - see `AppPreferences.lastSeenWhatsNewRevision`'s own doc
/// comment for how the comparison works. Not tied to `pubspec.yaml`'s own
/// version/build number - this project ships informally (Dropbox builds,
/// not app-store releases with a disciplined version bump per release), so
/// a separate, hand-maintained counter is the honest thing to gate on
/// rather than pretending a version number means something it doesn't here.
const currentWhatsNewRevision = 3;

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
  WhatsNewItem(
    // Reuses the icon above rather than Icons.minimize - confirmed live
    // that this Flutter SDK's bundled icon font has no glyph for it (a
    // blank circle, not a crash) despite IconData existing for it in code -
    // same gap hit for Icons.compare_arrows/picture_as_pdf_outlined below.
    // Stick to icons already directly `Icon(Icons.x)`-referenced elsewhere
    // in this codebase (confirmed rendering) for any future entry.
    icon: Icons.desktop_windows_outlined,
    title: 'Closing the Windows app keeps it running',
    body:
        "Closing the window now tucks the app into the system tray instead "
        "of quitting - left-click the tray icon to bring it back, or "
        "right-click for Exit. Nothing is lost either way.",
  ),
  WhatsNewItem(
    icon: Icons.directions_walk,
    title: 'Tap into your logged activities',
    body:
        'The Activities/Active time/Distance cards on the Progress tab are '
        "tappable now - see exactly which walks, runs, or rides they're "
        'counting for that period.',
  ),
  WhatsNewItem(
    icon: Icons.date_range,
    title: 'Compare periods, or pick your own',
    body:
        'Progress now shows how this week or month compares to the last '
        'one, and a new Custom option lets you pick any date range for a '
        'summary of exactly that window.',
  ),
  WhatsNewItem(
    icon: Icons.description_outlined,
    title: 'A full training log to share with a coach',
    body:
        'Export a detailed PDF of every session and activity - full '
        'set-by-set detail, not just a summary - for whatever period '
        "you're looking at, alongside the existing summary report.",
  ),
  WhatsNewItem(
    icon: Icons.repeat,
    title: 'Skip, replace, and make it up later',
    body:
        "Machine taken or something hurts? Skipping an exercise now asks "
        'why and lets you swap in another one for that session. Anything '
        'you skip shows up under "Missed recently" on Today, where you can '
        'do it now or add it to your next session.',
  ),
  WhatsNewItem(
    icon: Icons.timer_outlined,
    title: 'Holds and distances, logged properly',
    body:
        'Planks, hangs and other holds now log seconds - with a built-in '
        'timer that buzzes at your target - and carries or sprints log '
        'metres. Bodyweight warm-ups no longer ask for a weight at all.',
  ),
];
