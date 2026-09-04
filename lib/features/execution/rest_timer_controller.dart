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

  const RestTimerState({
    required this.remaining,
    required this.total,
    this.planSessionId,
  });

  bool get isRunning => remaining != null && remaining! > Duration.zero;

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
  }

  void skip() {
    _ticker?.cancel();
    _endTime = null;
    state = RestTimerState.idle;
    unawaited(_notificationService.cancelRestTimerNotification());
  }

  void _tick() {
    final end = _endTime;
    if (end == null) return;
    final now = DateTime.now();
    final remaining = remainingRestTime(endTime: end, now: now);
    state = RestTimerState(
      remaining: remaining,
      total: state.total,
      planSessionId: state.planSessionId,
    );
    if (isRestTimerFinished(endTime: end, now: now)) {
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
