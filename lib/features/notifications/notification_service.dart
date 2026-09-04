import 'dart:async';
import 'dart:typed_data';

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
// "_v2": renaming the channel id forces Android to create a fresh channel
// with these settings - an existing channel's importance/vibration can't be
// changed by shipping new code once a device has already seen the old id,
// only by the user manually editing it in system settings or the app using
// a new id, which is what actually fixed nothing showing/vibrating on a
// real device that had already seen an earlier build of this channel.
const _restTimerChannelId = 'rest_timer_v2';
const _restTimerChannelName = 'Rest timer';
const _restTimerChannelDescription =
    'A live countdown while resting between sets - taps through back to the '
    'workout, with a Skip action, and stays visible even if the app is '
    'closed or backgrounded.';
const _restTimerNotificationId = 2;
const restTimerSkipActionId = 'skip_rest';

// Deliberately a separate channel/notification from the ongoing countdown
// above: that one is meant to stay quiet (Importance.low - no sound, ticking
// silently) so every single rest period doesn't pop up a heads-up alert.
// This one is the opposite - a single, momentary, attention-getting ping
// exactly when rest ends, which is the actual moment someone wants to be
// alerted. Scheduled up front (like a workout reminder) rather than only
// fired from the in-app timer tick, so it still fires - vibration included -
// even if the app is backgrounded or fully killed mid-rest; skip()/finish
// cancel it so an early-ended rest doesn't ring later at its original time.
const _restCompleteChannelId = 'rest_timer_complete';
const _restCompleteChannelName = 'Rest complete';
const _restCompleteChannelDescription =
    'A one-time alert the moment a rest period ends.';
const _restCompleteNotificationId = 3;
final _restCompleteVibrationPattern = Int64List.fromList([
  0,
  400,
  200,
  400,
]);

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

  /// Schedules the one-time "rest's over" alert for [endTime] - see the
  /// channel doc comment above for why this is a separate, higher-importance
  /// notification from the quiet ongoing countdown. Scheduled exactly like a
  /// workout reminder (`schedule` above) so it fires - sound, vibration, and
  /// all - even if the app is backgrounded or killed before the rest period
  /// ends; call [cancelRestCompleteAlert] whenever the rest ends early
  /// (Skip, or the session finishes) so a skipped rest doesn't ring late.
  Future<void> scheduleRestCompleteAlert({
    required int planSessionId,
    required DateTime endTime,
  }) async {
    await init();
    if (!endTime.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: _restCompleteNotificationId,
      title: 'Rest complete',
      body: 'Back to it - tap to return to your workout.',
      scheduledDate: tz.TZDateTime.from(endTime, tz.local),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: buildWorkoutReminderPayload(planSessionId),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _restCompleteChannelId,
          _restCompleteChannelName,
          channelDescription: _restCompleteChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          vibrationPattern: _restCompleteVibrationPattern,
        ),
      ),
    );
  }

  Future<void> cancelRestCompleteAlert() async {
    await init();
    await _plugin.cancel(id: _restCompleteNotificationId);
  }
}
