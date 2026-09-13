import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:training_app/features/onboarding/whats_new_content.dart';
import 'package:training_app/features/onboarding/whats_new_screen.dart';
import 'package:training_app/features/settings/app_preferences.dart';

void main() {
  // "Got it" awaits AppPreferencesNotifier.setLastSeenWhatsNewRevision,
  // which touches shared_preferences - without a mock, that call has
  // nothing to respond to and the test hangs instead of failing fast (see
  // app_preferences_test.dart and onboarding_screen_test.dart for the same
  // setUp).
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'shows every whatsNewItems entry and stamps the current revision on "Got it"',
    (tester) async {
      // Seven cards (icon + title + multi-line body each) don't all fit in
      // the default small test viewport - ListView.separated only mounts
      // what's actually visible, so a later item's Text isn't in the tree
      // at all until scrolled into view. Same fix as create_exercise_screen_test.dart's.
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWith(
            (ref) => AppPreferencesNotifier()
              ..state = const AppPreferences(lastSeenWhatsNewRevision: 0),
          ),
        ],
      );
      addTearDown(container.dispose);

      // WhatsNewScreen calls Navigator.of(context).pop() on "Got it" (see
      // home_screen.dart's actual Navigator.push call site) - pumping it
      // directly as MaterialApp.home would make that pop() a no-op on the
      // only route in the stack, matching onboarding_screen_test.dart's own
      // precedent for the same reason.
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Navigator(
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const WhatsNewScreen(),
                        ),
                      ),
                      child: const Text('start'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('start'));
      await tester.pumpAndSettle();

      for (final item in whatsNewItems) {
        expect(find.text(item.title), findsOneWidget);
      }

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      expect(
        container.read(appPreferencesProvider).lastSeenWhatsNewRevision,
        currentWhatsNewRevision,
      );
      // Confirms the pop actually happened - back to the "start" button.
      expect(find.text('start'), findsOneWidget);
    },
  );
}
