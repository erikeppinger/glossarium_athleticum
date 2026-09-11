import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../logic/rest_timer.dart';
import '../notifications/notification_service.dart';
import '../notifications/reminder_coordinator.dart' show notificationServiceProvider;

class RestTimerState {
  final Duration? remaining;
  final Duration total;
  final int? planSessionId;

  /// True for one display cycle after the countdown reaches zero, until
  /// skip() or a new start() dismisses it. Without this the banner/overlay
  /// chip just vanished the instant the countdown hit zero - no "time's up"
  /// state was ever actually visible, which made it easy to miss finishing
  /// a rest while looking at another tab.
  final bool overdue;

  const RestTimerState({
    required this.remaining,
    required this.total,
    this.planSessionId,
    this.overdue = false,
  });

  bool get isRunning => remaining != null && remaining! > Duration.zero;

  /// Whether the banner/overlay chip should be shown at all - counting
  /// down, or finished and not yet dismissed.
  bool get isVisible => isRunning || overdue;

  static const idle = RestTimerState(remaining: null, total: Duration.zero);
}

/// Drives the rest-timer UI off a fixed end time (see logic/rest_timer.dart
/// for why) rather than counting down tick-by-tick, so it can't drift or
/// reset if the app is backgrounded mid-rest.
///
/// Deliberately NOT autoDispose: `rest_timer_overlay.dart` watches this from
/// `home_screen.dart` (always mounted) so the timer keeps running and stays
/// visible even after the execution screen that started it is popped.
class RestTimerController extends StateNotifier<RestTimerState> {
  RestTimerController(this._notificationService) : super(RestTimerState.idle);

  final NotificationService _notificationService;

  Timer? _ticker;
  DateTime? _endTime;

  // Throttles updateRestTimerNotification (Windows-only - see its own doc
  // comment) to once per elapsed second rather than every 250ms tick, since
  // a WinRT toast rebind isn't free and nobody can perceive a countdown
  // updating faster than once a second anyway. Reset whenever a countdown
  // (re)starts so the first tick after start()/restoreIfAny() isn't skipped
  // just because it happens to match a stale value from a previous timer.
  int? _lastNotifiedRemainingSeconds;

  // The countdown itself only ever lived in memory - `_endTime` above always
  // starts null on a fresh process, the same gap
  // `activeInProgressSessionIdProvider`'s own cold-start restore (see
  // main.dart's `_startupProvider`) already closed for the *session*-level
  // "is something in progress" marker, but never for the rest timer's own
  // end time specifically. Reported live (2026-09-11): leaving a session via
  // the rest-timer chip's own resume path, then backgrounding the app long
  // enough for Android to kill the process (a real back-then-Recents-switch
  // repro, not a hypothetical), made the floating chip vanish entirely on
  // reopening - the plan was still resumable (that marker did survive), but
  // nothing pointed back to the still-technically-running rest period at
  // all. These three scalars are the minimum needed to recompute
  // remaining/overdue from the wall clock on restore, exactly like `_tick`
  // already does - not a new relational concept, so SharedPreferences (already
  // used for equally simple per-device scalars in app_preferences.dart)
  // rather than a database table.
  static const _sessionIdKey = 'rest_timer_persisted_session_id';
  static const _endTimeKey = 'rest_timer_persisted_end_time_millis';
  static const _totalSecondsKey = 'rest_timer_persisted_total_seconds';

  // Reported live: the rest timer's notification/vibration never fired on a
  // real device, because Android 13+'s POST_NOTIFICATIONS permission was
  // only ever requested from an unrelated Settings toggle (turning on a
  // workout/plan reminder) - nothing about starting a rest timer, the very
  // first thing anyone does in a workout, ever visited that screen. Asking
  // here instead ties the request to the exact feature that needs it. Only
  // an in-memory, per-app-run flag - not persisted - since Android itself
  // remembers the user's actual decision (grant/deny) permanently at the OS
  // level regardless; this only avoids redundant platform-channel calls on
  // every subsequent set within the same run, not a "don't ask again"
  // mechanism (that's already handled for us).
  bool _hasRequestedNotificationPermission = false;

  void start(Duration duration, {required int planSessionId}) {
    final endTime = DateTime.now().add(duration);
    _endTime = endTime;
    _lastNotifiedRemainingSeconds = null;
    state = RestTimerState(
      remaining: duration,
      total: duration,
      planSessionId: planSessionId,
    );
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    if (!_hasRequestedNotificationPermission) {
      _hasRequestedNotificationPermission = true;
      unawaited(_notificationService.requestPermissions());
    }
    // Fire-and-forget: a slow/failed platform call shouldn't block the timer
    // itself starting, and the in-app overlay already shows the countdown
    // regardless of whether the OS notification lands.
    unawaited(
      _notificationService.showRestTimerNotification(
        planSessionId: planSessionId,
        endTime: endTime,
      ),
    );
    // Scheduled up front (not just fired from _tick() below) so the "rest's
    // over" alert - sound and vibration included - still arrives even if the
    // app is backgrounded or killed before the rest period ends.
    unawaited(
      _notificationService.scheduleRestCompleteAlert(
        planSessionId: planSessionId,
        endTime: endTime,
      ),
    );
    unawaited(_persist(planSessionId: planSessionId, endTime: endTime, total: duration));
  }

  void skip() {
    _ticker?.cancel();
    _endTime = null;
    state = RestTimerState.idle;
    unawaited(_notificationService.cancelRestTimerNotification());
    unawaited(_notificationService.cancelRestCompleteAlert());
    unawaited(_clearPersisted());
  }

  Future<void> _persist({
    required int planSessionId,
    required DateTime endTime,
    required Duration total,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionIdKey, planSessionId);
    await prefs.setInt(_endTimeKey, endTime.millisecondsSinceEpoch);
    await prefs.setInt(_totalSecondsKey, total.inSeconds);
  }

  Future<void> _clearPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionIdKey);
    await prefs.remove(_endTimeKey);
    await prefs.remove(_totalSecondsKey);
  }

  /// Restores a still-relevant rest timer after a genuine process kill - see
  /// the doc comment on the persistence keys above for why this exists.
  /// Called once from `main.dart`'s `_startupProvider`, right alongside the
  /// equivalent restore for `activeInProgressSessionIdProvider`. Recomputes
  /// remaining/overdue from the current wall clock against the persisted end
  /// time - never trusts elapsed time as "ticks that should have happened" -
  /// exactly like `_tick` already does for the in-memory case, so a restore
  /// that lands after the rest period already ended correctly shows the same
  /// "Rest over - back to it" state a still-running process would have
  /// reached on its own instead of just not showing anything.
  Future<void> restoreIfAny() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getInt(_sessionIdKey);
    final endMillis = prefs.getInt(_endTimeKey);
    final totalSeconds = prefs.getInt(_totalSecondsKey);
    if (sessionId == null || endMillis == null || totalSeconds == null) {
      return;
    }

    final endTime = DateTime.fromMillisecondsSinceEpoch(endMillis);
    final now = DateTime.now();
    final finished = isRestTimerFinished(endTime: endTime, now: now);

    _ticker?.cancel();
    _endTime = finished ? null : endTime;
    _lastNotifiedRemainingSeconds = null;
    state = RestTimerState(
      remaining: remainingRestTime(endTime: endTime, now: now),
      total: Duration(seconds: totalSeconds),
      planSessionId: sessionId,
      overdue: finished,
    );
    if (!finished) {
      _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    }
  }

  void _tick() {
    final end = _endTime;
    if (end == null) return;
    final now = DateTime.now();
    final remaining = remainingRestTime(endTime: end, now: now);
    final justFinished = isRestTimerFinished(endTime: end, now: now);
    state = RestTimerState(
      remaining: remaining,
      total: state.total,
      planSessionId: state.planSessionId,
      overdue: justFinished,
    );
    final remainingSeconds = remaining.inSeconds;
    if (justFinished || remainingSeconds != _lastNotifiedRemainingSeconds) {
      _lastNotifiedRemainingSeconds = remainingSeconds;
      unawaited(
        _notificationService.updateRestTimerNotification(
          remaining: remaining,
          total: state.total,
          overdue: justFinished,
        ),
      );
    }
    if (justFinished) {
      _ticker?.cancel();
      _endTime = null;
      // A one-time cue that rest is over - important now that the timer can
      // be followed to another tab (rest_timer_overlay.dart) where the
      // countdown itself isn't visible.
      HapticFeedback.vibrate();
      SystemSound.play(SystemSoundType.alert);
      // Belt-and-suspenders alongside the notification's own `timeoutAfter`
      // (see showRestTimerNotification) - whichever fires first is fine,
      // cancelling an already-gone notification is a harmless no-op.
      unawaited(_notificationService.cancelRestTimerNotification());
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final restTimerControllerProvider =
    StateNotifierProvider<RestTimerController, RestTimerState>(
      (ref) => RestTimerController(ref.read(notificationServiceProvider)),
    );

/// The most recently opened execution session that hasn't been finished or
/// discarded yet - null once there is none. Set on entering `ExecutionScreen`
/// and cleared on Discard/Finish, but deliberately left set when choosing
/// "Leave" (see execution_screen.dart's `_confirmDiscard`), so
/// `RestTimerOverlay` can still show a "resume your session" chip on other
/// tabs even when no rest timer happens to be running - previously the only
/// way back to a left-but-unfinished session was a running rest timer, so
/// leaving between sets (nothing resting) made it easy to lose track of it
/// entirely. Not autoDispose, matching `restTimerControllerProvider`, for
/// the same reason: it needs to survive `ExecutionScreen` being popped.
final activeInProgressSessionIdProvider = StateProvider<int?>((ref) => null);

/// True exactly while an `ExecutionScreen` is the visible, topmost route -
/// `RestTimerOverlay` reads this to hide itself (its own inline banner
/// already covers the same information there). Previously relied entirely
/// on `RestTimerOverlay` living inside `HomeScreen`'s own build, one layer
/// below wherever `ExecutionScreen` gets pushed on the same Navigator - which
/// only worked because the overlay was never shown anywhere *else* either
/// (reported live: the floating chip/banner never appeared on Settings, or
/// any other screen reached by pushing a route on top of `HomeScreen`, since
/// that push covers the overlay along with everything else). Now that the
/// overlay lives above the whole app (see `main.dart`'s `MaterialApp.builder`)
/// so it can float over every screen, this explicit flag is what keeps it
/// off specifically while `ExecutionScreen` itself is what's showing.
final executionScreenVisibleProvider = StateProvider<bool>((ref) => false);

/// Lets the app-level "is it safe to close the window right now" check (see
/// `main.dart`'s `AppLifecycleListener` - only Windows actually needs this
/// today, see its own doc comment for why) run `ExecutionScreen`'s own
/// unsaved-sets guard before agreeing to let the OS close the window. Null
/// whenever no `ExecutionScreen` is mounted, in which case there's nothing to
/// guard and closing is always safe - the same shape as
/// [executionScreenVisibleProvider] for the same reason (only ever one
/// `ExecutionScreen` can be on top at a time).
final executionScreenCloseGuardProvider =
    StateProvider<Future<bool> Function()?>((ref) => null);
