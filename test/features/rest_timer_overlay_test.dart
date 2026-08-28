import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/features/execution/rest_timer_controller.dart';
import 'package:training_app/features/execution/rest_timer_overlay.dart';

// Mirrors home_screen.dart's structure (a Navigator stacked with
// RestTimerOverlay as a sibling) without dragging in the full HomeScreen/DB
// setup - proves the overlay stays visible and keeps counting down after the
// screen that started the timer is popped, since restTimerControllerProvider
// isn't autoDispose and the overlay itself never unmounts.
class _FakeHome extends StatelessWidget {
  const _FakeHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute(
              builder: (context) => const _FakePlansTab(),
            ),
          ),
          const RestTimerOverlay(),
        ],
      ),
    );
  }
}

class _FakePlansTab extends StatelessWidget {
  const _FakePlansTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => _FakeExecutionScreen()),
          ),
          child: const Text('start session'),
        ),
      ),
    );
  }
}

class _FakeExecutionScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => ref
              .read(restTimerControllerProvider.notifier)
              .start(const Duration(seconds: 90), planSessionId: 42),
          child: const Text('log set'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets(
    'rest timer overlay stays visible and counting after its screen is popped',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: _FakeHome()),
        ),
      );

      expect(find.textContaining('Rest:'), findsNothing);

      await tester.tap(find.text('start session'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('log set'));
      await tester.pump();

      expect(find.textContaining('Rest: 01:30'), findsOneWidget);

      // Pop the fake execution screen (simulating the user backing out to
      // another tab mid-rest) - the button that started the timer is gone.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('log set'), findsNothing);

      // The overlay is a sibling of the Navigator, not inside the popped
      // route, so it should still be showing the running timer.
      expect(find.textContaining('Rest:'), findsOneWidget);

      // Let the 250ms ticker fire at least once.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Rest: 01:2'), findsOneWidget);
    },
  );
}
