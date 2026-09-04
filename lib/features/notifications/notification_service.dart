import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../logic/notification_schedule.dart';
import '../../logic/reminder_payload.dart';

const _channelId = 'training_reminders';
const _channelName = 'Training reminders';
const _channelDescription =
    'Reminders for scheduled workouts and your weekly training overview.';

// A separate channel from the reminders above - this one is a live, ongoing
// countdown shown for the duration of a single rest period, not a scheduled
// one-off - conflating the two would mean muting reminders also muted this,
// or vice versa, when someone might reasonably want only one of the two.
const _restTimerChannelId = 'rest_timer';
const _restTimerChannelName = 'Rest timer';
const _restTimerChannelDescription =
    'A live countdown while resting between sets - taps through back to the '
    'workout, with a Skip action, and stays visible even if the app is '
    'closed or backgrounded.';
const _restTimerNotificationId = 2;
const restTimerSkipActionId = 'skip_rest';

/// Thin wrapper over flutter_local_notifications. Deliberately kept free of
/// any app logic - what to schedule and when is decided by the pure functions
/// in `lib/logic/notification_schedule.dart`, so that part stays unit-testable
/// without platform channels (same split as `incoming_share_handler.dart`'s
/// dart:io wrapper, see CLAUDE.md).
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  final _tapController = StreamController<String>.broadcast();
  final _actionController = StreamController<String>.broadcast();

  /// Fires with a reminder's `payload` (see `reminder_payload.dart`) whenever
  /// the user taps a notification while the app is already running.
  /// `home_screen.dart` subscribes to this the same way it does for incoming
  /// shared files.
  Stream<String> get onNotificationTap => _tapController.stream;

  /// Fires with an action's id (e.g. [restTimerSkipActionId]) whenever the
  /// user taps a notification action button - distinct from tapping the
  /// notification body itself, which goes through [onNotificationTap]
  /// instead. Only ever fires while the app process is already alive; an
  /// action button tap can't cold-start the app the way a body tap can.
  Stream<String> get onNotificationAction => _actionController.stream;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: _handleResponse,
    );
    _initialized = true;
  }

  void _handleResponse(NotificationResponse details) {
    final actionId = details.actionId;
    if (actionId != null) {
      _actionController.add(actionId);
      return;
    }
    final payload = details.payload;
    if (payload != null) _tapController.add(payload);
  }

  /// The payload of the notification that launched the app from a
  /// cold/terminated state, if any - `onDidReceiveNotificationResponse` above
  /// only fires for a tap while the app process is already alive, so a
  /// cold-start tap has to be picked up this way instead.
  Future<String?> consumeLaunchPayload() async {
    await init();
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return details?.notificationResponse?.payload;
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
      payload: reminder.payload,
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

  /// A live, ongoing "Resting" notification counting down to [endTime] -
  /// this is what makes the rest timer visible outside the app (locked
  /// screen, another app, the app fully closed) without the permission,
  /// native window-management code, and Play Store scrutiny a true
  /// draw-over-other-apps overlay would need. `usesChronometer`/
  /// `chronometerCountDown` hand the actual countdown to Android's own
  /// notification renderer - it keeps ticking correctly with zero Dart code
  /// running, so backgrounding or even killing the app can't desync or
  /// freeze it. Tapping the body reuses the same "open this session"
  /// payload a workout reminder would; the "Skip" action fires
  /// [onNotificationAction] with [restTimerSkipActionId] without opening
  /// the app (`showsUserInterface: false`) - `home_screen.dart` wires that
  /// to the same `RestTimerController.skip()` the in-app Skip button calls.
  Future<void> showRestTimerNotification({
    required int planSessionId,
    required DateTime endTime,
  }) async {
    await init();
    final remaining = endTime.difference(DateTime.now());
    await _plugin.show(
      id: _restTimerNotificationId,
      title: 'Resting',
      body: 'Tap to return to your workout.',
      payload: buildWorkoutReminderPayload(planSessionId),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _restTimerChannelId,
          _restTimerChannelName,
          channelDescription: _restTimerChannelDescription,
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          showWhen: true,
          when: endTime.millisecondsSinceEpoch,
          usesChronometer: true,
          chronometerCountDown: true,
          // Belt-and-suspenders removal: even if the app is killed before
          // it ever calls cancelRestTimerNotification, the OS clears this
          // on its own once the rest period is actually over.
          timeoutAfter: remaining.isNegative ? 0 : remaining.inMilliseconds,
          actions: const [
            AndroidNotificationAction(
              restTimerSkipActionId,
              'Skip',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> cancelRestTimerNotification() async {
    await init();
    await _plugin.cancel(id: _restTimerNotificationId);
  }
}
