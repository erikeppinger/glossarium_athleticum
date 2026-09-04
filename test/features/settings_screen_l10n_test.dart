import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/data/app_database.dart';
import 'package:training_app/data/app_database_provider.dart';
import 'package:training_app/features/notifications/reminder_coordinator.dart';
import 'package:training_app/features/settings/settings_screen.dart';
import 'package:training_app/l10n/app_localizations.dart';

import 'fake_notification_service.dart';

// Regression guard: settings_screen.dart's migrated rows call
// AppLocalizations.of(context)! - if a host MaterialApp is ever missing the
// localizationsDelegates/supportedLocales wiring (main.dart has it; a test
// or future screen might not), that throws a null-check error instead of
// falling back to plain text. Pump the real screen through a MaterialApp
// configured the same way main.dart's TrainingApp is, in both supported
// locales, and confirm it renders without throwing.
void main() {
  Future<AppDatabase> seedDb() async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    return db;
  }

  Future<void> pumpSettings(WidgetTester tester, AppDatabase db, Locale locale) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(
            FakeNotificationService(),
          ),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders in English with the localized settings copy', (
    tester,
  ) async {
    final db = await seedDb();
    await pumpSettings(tester, db, const Locale('en'));

    expect(find.text('Settings'), findsOneWidget);
    // "Units & display" is a collapsed ExpansionTile by default (_Section) -
    // its rows aren't in the tree at all until expanded.
    await tester.tap(find.text('Units & display'));
    await tester.pumpAndSettle();

    expect(find.text('Weight unit'), findsOneWidget);
    expect(find.text('Fitness level'), findsOneWidget);
    expect(find.text('Available equipment'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });

  testWidgets('renders in German with the localized settings copy', (
    tester,
  ) async {
    final db = await seedDb();
    await pumpSettings(tester, db, const Locale('de'));

    expect(find.text('Einstellungen'), findsOneWidget);
    await tester.tap(find.text('Einheiten & Anzeige'));
    await tester.pumpAndSettle();

    expect(find.text('Gewichtseinheit'), findsOneWidget);
    expect(find.text('Fitnesslevel'), findsOneWidget);
    expect(find.text('Verfügbare Ausrüstung'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await db.close();
  });
}
