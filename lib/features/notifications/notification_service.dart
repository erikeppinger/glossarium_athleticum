import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../logic/notification_schedule.dart';

const _channelId = 'training_reminders';
const _channelName = 'Training reminders';
const _channelDescription =
    'Reminders for scheduled workouts and your weekly training overview.';

/// Thin wrapper over flutter_local_notifications. Deliberately kept free of
/// any app logic - what to schedule and when is decided by the pure functions
/// in `lib/logic/notification_schedule.dart`, so that part stays unit-testable
/// without platform channels (same split as `incoming_share_handler.dart`'s
/// dart:io wrapper, see CLAUDE.md).
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _initialized = true;
  }

  /// Asks for POST_NOTIFICATIONS (Android 13+) and exact-alarm permission.
  /// Returns whether notifications themselves were granted - exact alarms
  /// failing only downgrades timing precision, so it isn't treated as fatal.
  Future<bool> requestPermissions() async {
    await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return false;
    final granted = await android.requestNotificationsPermission() ?? false;
    if (granted) {
      await android.requestExactAlarmsPermission();
    }
    return granted;
  }

  Future<void> schedule(ScheduledReminder reminder) async {
    await init();
    await _plugin.zonedSchedule(
      id: reminder.id,
      title: reminder.title,
      body: reminder.body,
      scheduledDate: tz.TZDateTime.from(reminder.when, tz.local),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }

  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}
