import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:training_app/features/execution/rest_timer_controller.dart';
import 'package:training_app/features/notifications/reminder_coordinator.dart';

import 'fake_notification_service.dart';

class _SpyNotificationService extends FakeNotificationService {
  int requestPermissionsCallCount = 0;

  @override
  Future<bool> requestPermissions() async {
    requestPermissionsCallCount++;
    return true;
  }
}

// Regression coverage: reported live that the rest timer's notification and
// vibration never fired on a real device, because POST_NOTIFICATIONS was
// only ever requested from an unrelated Settings toggle (turning on a
// workout/plan reminder) - nothing about starting a rest timer itself ever
// asked. RestTimerController.start() now requests it directly.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // start() now also persists to SharedPreferences (see
    // rest_timer_controller.dart's cold-start-restore feature) - a plain
    // test() has no platform-channel binding set up on its own the way
    // testWidgets() does, so SharedPreferences.getInstance() throws
    // "Binding has not yet been initialized" without this.
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'requests notification permission the first time a rest timer starts, '
    'not on every subsequent set in the same app run',
    () {
      final spy = _SpyNotificationService();
      final container = ProviderContainer(
        overrides: [notificationServiceProvider.overrideWithValue(spy)],
      );
      addTearDown(container.dispose);

      final controller = container.read(restTimerControllerProvider.notifier);
      controller.start(const Duration(seconds: 90), planSessionId: 1);
      expect(spy.requestPermissionsCallCount, 1);

      controller.start(const Duration(seconds: 90), planSessionId: 1);
      controller.start(const Duration(seconds: 90), planSessionId: 1);
      expect(
        spy.requestPermissionsCallCount,
        1,
        reason: 'should not re-request on every subsequent rest period',
      );
    },
  );
}
