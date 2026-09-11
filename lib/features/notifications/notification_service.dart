import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../logic/notification_schedule.dart';
import '../../logic/reminder_payload.dart';
import '../../logic/rest_timer.dart' show formatRestTime;

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

// Windows only (see showRestTimerNotification/updateRestTimerNotification):
// WindowsNotificationDetails has no chronometer equivalent to Android's
// usesChronometer/chronometerCountDown, but its progress bar *can* be
// updated in place after the toast is shown (FlutterLocalNotificationsWindows
// .updateProgressBar) - reusing that as a plain countdown label is the
// closest available substitute for a live-ticking display.
const _restTimerProgressBarId = 'rest_timer_progress';

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

/// Handles a notification action (currently only [restTimerSkipActionId])
/// tapped while the app has no active Flutter engine to deliver it to via
/// the normal `onDidReceiveNotificationResponse` callback - e.g. the rest
/// timer notification's "Skip" button, tapped while the app is backgrounded
/// or has been killed by the OS, which is the *ordinary* way anyone taps it
/// (mid-workout, phone locked). Reported live (2026-09-10): Skip visibly did
/// nothing. Must be a top-level function, annotated exactly like this, so
/// the plugin's Android side can spin up a throwaway background isolate to
/// run it in - per flutter_local_notifications' own documented requirement
/// for reliably handling `showsUserInterface: false` actions when the app
/// isn't already running in the foreground.
///
/// Runs in its own isolate with no access to the main app's Riverpod state -
/// there's no live `RestTimerController` to call `skip()` on here, but
/// there doesn't need to be: if this handler is even being invoked at all,
/// the plugin has already determined no foreground engine is available to
/// deliver the response to the normal way, which means there's no in-memory
/// timer state to update anyway (a cold start afterward would show idle
/// state regardless). All that's actually needed is making sure both of the
/// rest timer's own notifications go away and the still-pending "rest
/// complete" alert doesn't fire late - a fresh plugin instance can do that
/// without touching the database or any other app state.
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse details) {
  if (details.actionId != restTimerSkipActionId) return;
  final plugin = FlutterLocalNotificationsPlugin();
  unawaited(plugin.cancel(id: _restTimerNotificationId));
  unawaited(plugin.cancel(id: _restCompleteNotificationId));
}

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
        // Required on Windows - `initialize()` throws an ArgumentError if
        // `windows` is null while running on that platform (unlike Android,
        // where the settings object is genuinely optional per-platform).
        windows: WindowsInitializationSettings(
          appName: 'Training App',
          appUserModelId: 'com.trainingapp.training_app',
          guid: '9de9e982-6bf6-4a1b-9aab-b8b4c2f0e3a3',
        ),
      ),
      onDidReceiveNotificationResponse: _handleResponse,
      onDidReceiveBackgroundNotificationResponse:
          onBackgroundNotificationResponse,
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

  /// Cancels every currently *pending* (scheduled but not yet fired)
  /// reminder - workout reminders, the weekly digest, and per-plan report
  /// reminders, all scheduled via [schedule] - without touching a
  /// notification that's already showing right now, like the rest timer's
  /// own countdown or "session in progress". [cancelAll] would wipe those
  /// too, which silently undid the "session in progress" notification
  /// (posted during app startup, just before `resyncReminders` runs from
  /// `home_screen.dart`'s own `initState`) on every single cold start -
  /// confirmed live (2026-09-10) via `adb shell dumpsys notification`: the
  /// notification's channel existed and permission was granted, but no
  /// instance of it was ever actually showing a few seconds after launch.
  /// `pendingNotificationRequests()` only ever returns scheduled-for-later
  /// entries, never something already delivered via `show()`, which is
  /// exactly the distinction needed here.
  Future<void> cancelAllScheduledReminders() async {
    await init();
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      await _plugin.cancel(id: request.id);
    }
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
    Duration? total,
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
        // Reported live (2026-09-11): the Windows toast showed no rest time
        // at all and never changed once shown. A bare title/body has nothing
        // to update in place - the progress bar is the one element this
        // plugin can actually rebind after the toast is posted (see
        // updateRestTimerNotification), so it carries the countdown text
        // instead of a real percentage.
        windows: WindowsNotificationDetails(
          progressBars: [
            WindowsProgressBar(
              id: _restTimerProgressBarId,
              status: 'Time remaining',
              value: 0,
              label: formatRestTime(remaining.isNegative ? Duration.zero : remaining),
            ),
          ],
        ),
      ),
    );
  }

  /// Rebinds the Windows rest-timer toast's progress bar to the current
  /// countdown - see [showRestTimerNotification]'s doc comment for why this
  /// is the only piece of an already-shown Windows toast that can be updated
  /// in place. A no-op on every other platform. Called from
  /// `RestTimerController`'s own ticker, throttled to once per elapsed
  /// second so it isn't hammering a native/WinRT call 4x a second for
  /// nothing a person could actually perceive.
  Future<void> updateRestTimerNotification({
    required Duration remaining,
    required Duration total,
    required bool overdue,
  }) async {
    if (!Platform.isWindows) return;
    final windows = _plugin
        .resolvePlatformSpecificImplementation<FlutterLocalNotificationsWindows>();
    if (windows == null) return;
    final fraction = total.inMilliseconds == 0
        ? 1.0
        : (1 - (remaining.inMilliseconds / total.inMilliseconds)).clamp(
            0.0,
            1.0,
          );
    await windows.updateProgressBar(
      notificationId: _restTimerNotificationId,
      progressBar: WindowsProgressBar(
        id: _restTimerProgressBarId,
        status: overdue ? 'Rest over' : 'Time remaining',
        value: overdue ? 1.0 : fraction,
        label: overdue ? 'Back to it!' : formatRestTime(remaining),
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
    // Exact-alarm scheduling needs its own permission (SCHEDULE_EXACT_ALARM/
    // "Alarms & reminders"), separate from POST_NOTIFICATIONS - unlike that
    // one, many real devices default it to *off* and require a manual visit
    // to system settings rather than just tapping a runtime dialog through,
    // so `requestPermissions()`'s own request for it can easily go unheeded.
    // A rest period lasting minutes doesn't need to-the-second precision the
    // way an alarm clock does - falling back to inexact scheduling here
    // means the alert still fires (a little late is far better than a
    // silent no-show) instead of the request possibly failing outright with
    // no fallback at all, which is the most likely explanation for a real
    // (2026-09-10) report that this alert simply never appeared on a real
    // device while it worked fine on the emulator (whose default AOSP image
    // grants this permission automatically).
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final canScheduleExact =
        await android?.canScheduleExactNotifications() ?? true;
    await _plugin.zonedSchedule(
      id: _restCompleteNotificationId,
      title: 'Rest complete',
      body: 'Back to it - tap to return to your workout.',
      scheduledDate: tz.TZDateTime.from(endTime, tz.local),
      androidScheduleMode: canScheduleExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
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
