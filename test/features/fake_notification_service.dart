import 'package:training_app/features/notifications/notification_service.dart';
import 'package:training_app/logic/notification_schedule.dart';

/// A real `NotificationService` touches platform channels that don't exist
/// in a widget test - any test whose widget tree can start/skip the rest
/// timer (which posts a live notification, see rest_timer_controller.dart)
/// or that calls `resyncReminders` (cancelAllScheduledReminders/schedule - see
/// reminder_coordinator.dart, called from start_session_helper.dart among
/// others) needs to override `notificationServiceProvider` with this no-op
/// fake, or the test fails on an unhandled platform-channel error unrelated
/// to whatever the test actually checks.
class FakeNotificationService extends NotificationService {
  @override
  Future<void> showRestTimerNotification({
    required int planSessionId,
    required DateTime endTime,
    Duration? total,
  }) async {}

  // Without this override, the real implementation runs unchanged on this
  // host - and since `flutter test` reports the actual host OS (this is a
  // Windows dev machine), `Platform.isWindows` is true even inside a test,
  // so it would attempt a real WinRT toast update via platform channels
  // exactly like the methods above already had to guard against.
  @override
  Future<void> updateRestTimerNotification({
    required Duration remaining,
    required Duration total,
    required bool overdue,
  }) async {}

  @override
  Future<void> cancelRestTimerNotification() async {}

  @override
  Future<void> scheduleRestCompleteAlert({
    required int planSessionId,
    required DateTime endTime,
  }) async {}

  @override
  Future<void> cancelRestCompleteAlert() async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> cancelAllScheduledReminders() async {}

  @override
  Future<void> schedule(ScheduledReminder reminder) async {}

  @override
  Future<bool> requestPermissions() async => false;
}
