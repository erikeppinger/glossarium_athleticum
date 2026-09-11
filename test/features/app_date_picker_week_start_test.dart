import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/features/settings/app_preferences.dart';
import 'package:training_app/features/shared/app_date_picker.dart';

// Regression coverage: reported live that every native date-picker popup
// (assign/move a session date, record a body measurement) always showed
// Sunday first regardless of Settings > "Week starts on", because
// showDatePicker has no such parameter of its own and instead follows the
// app's fixed Locale('en') (see main.dart) - only the hand-built calendar
// TAB (TableCalendar) ever read the actual setting. This checks the
// underlying MaterialLocalizations the dialog resolves to, rather than
// screen-scraping the day-header row - its narrow labels are ambiguous
// (Tuesday/Thursday both render "T", Sunday/Saturday both render "S").
Future<int> _firstDayIndexShown(WidgetTester tester, WeekStart weekStart) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showAppDatePicker(
            context: context,
            weekStart: weekStart,
            initialDate: DateTime(2026, 9, 9),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          ),
          child: const Text('Pick'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Pick'));
  await tester.pumpAndSettle();
  final dialogContext = tester.element(find.byType(CalendarDatePicker));
  return MaterialLocalizations.of(dialogContext).firstDayOfWeekIndex;
}

void main() {
  // MaterialLocalizations.firstDayOfWeekIndex: 0 = Sunday, 1 = Monday, ...
  testWidgets('Monday week-start makes the popup start on Monday', (
    tester,
  ) async {
    expect(await _firstDayIndexShown(tester, WeekStart.monday), 1);
  });

  testWidgets('Sunday week-start makes the popup start on Sunday', (
    tester,
  ) async {
    expect(await _firstDayIndexShown(tester, WeekStart.sunday), 0);
  });
}
