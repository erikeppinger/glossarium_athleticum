import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  void start(Duration duration, {required int planSessionId}) {
    final endTime = DateTime.now().add(duration);
    _endTime = endTime;
    state = RestTimerState(
      remaining: duration,
      total: duration,
      planSessionId: planSessionId,
    );
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
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
  }

  void skip() {
    _ticker?.cancel();
    _endTime = null;
    state = RestTimerState.idle;
    unawaited(_notificationService.cancelRestTimerNotification());
    unawaited(_notificationService.cancelRestCompleteAlert());
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
