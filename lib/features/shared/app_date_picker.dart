import 'package:flutter/material.dart';

import '../settings/app_preferences.dart' show WeekStart;

/// A thin wrapper around [showDatePicker] whose calendar grid actually
/// starts on the day set in Settings > "Week starts on".
///
/// Reported live: the calendar TAB (`calendar_screen.dart`'s `TableCalendar`)
/// already respected [WeekStart], but every native date-picker POPUP (assign
/// a session date, move a session date, record a body measurement) still
/// showed Sunday first regardless of the setting - `showDatePicker` has no
/// `startingDayOfWeek`-style parameter of its own and instead derives the
/// first day of the week from the app's locale, which `main.dart` pins to a
/// plain `Locale('en')` that never changes. Flutter has no public API to
/// override `MaterialLocalizations.firstDayOfWeekIndex` directly, so this
/// overrides the *locale* for just this dialog instead - en_GB starts on
/// Monday, en_US on Sunday - which is the smallest lever that actually works.
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required WeekStart weekStart,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    builder: (context, child) {
      return Localizations.override(
        context: context,
        locale: weekStart == WeekStart.monday
            ? const Locale('en', 'GB')
            : const Locale('en', 'US'),
        child: child,
      );
    },
  );
}
