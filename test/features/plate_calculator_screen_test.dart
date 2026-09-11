import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/features/settings/app_preferences.dart';
import 'package:training_app/features/tools/plate_calculator_screen.dart';

void main() {
  testWidgets('typing a target and bar weight shows the plates per side', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWith((ref) => AppPreferencesNotifier()),
        ],
        child: const MaterialApp(home: PlateCalculatorScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Enter a target and bar weight to see the plates.'),
      findsOneWidget,
    );
    // The bar weight field is seeded with a default (20kg) automatically.
    expect(find.text('20'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '100');
    await tester.pump();

    expect(find.textContaining('25×1, 15×1'), findsOneWidget);
    expect(find.textContaining('Total: 100'), findsOneWidget);
  });

  testWidgets('shows a shortfall note when the target is not exactly reachable', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWith((ref) => AppPreferencesNotifier()),
        ],
        child: const MaterialApp(home: PlateCalculatorScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '101');
    await tester.pump();

    expect(find.textContaining('short of your target'), findsOneWidget);
  });

  testWidgets(
    'turning off a plate size changes the calculation, and persists via '
    'AppPreferences',
    (tester) async {
      final notifier = AppPreferencesNotifier();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appPreferencesProvider.overrideWith((ref) => notifier)],
          child: const MaterialApp(home: PlateCalculatorScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '100');
      await tester.pump();
      expect(find.textContaining('25×1, 15×1'), findsOneWidget);

      // Reported live: not every gym has 25kg plates.
      await tester.tap(find.widgetWithText(FilterChip, '25kg'));
      await tester.pumpAndSettle();

      expect(
        notifier.state.availablePlatesKg.contains(25.0),
        isFalse,
        reason: 'turning the chip off should remove it from the persisted set',
      );
      expect(find.textContaining('25×1, 15×1'), findsNothing);
      // Without 25kg, 40kg per side (100kg target, 20kg bar) is reached
      // with two 20kg plates instead.
      expect(find.textContaining('20×2'), findsOneWidget);
    },
  );

  testWidgets(
    'adding a custom plate size not already on the common menu makes it '
    'available immediately',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWith((ref) => AppPreferencesNotifier()),
          ],
          child: const MaterialApp(home: PlateCalculatorScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // 37.5kg is deliberately not part of the common menu (unlike 40kg,
      // which already has its own catalogue chip) - exercises the "custom,
      // user-added" chip path specifically.
      await tester.tap(find.widgetWithText(ActionChip, 'Add plate'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        '37.5',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(InputChip, '37.5kg'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '100');
      await tester.pump();
      // 40kg per side: greedy picks one 37.5kg plate, then a 2.5kg plate
      // for the remainder - an exact fit alongside the standard set.
      expect(find.textContaining('37.5×1, 2.5×1'), findsOneWidget);
      expect(find.textContaining('Total: 100'), findsOneWidget);
    },
  );
}
