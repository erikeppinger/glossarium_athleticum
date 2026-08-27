import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/rest_timer.dart';

class RestTimerState {
  final Duration? remaining;
  final Duration total;

  const RestTimerState({required this.remaining, required this.total});

  bool get isRunning => remaining != null && remaining! > Duration.zero;

  static const idle = RestTimerState(remaining: null, total: Duration.zero);
}

/// Drives the rest-timer UI off a fixed end time (see logic/rest_timer.dart
/// for why) rather than counting down tick-by-tick, so it can't drift or
/// reset if the app is backgrounded mid-rest.
class RestTimerController extends StateNotifier<RestTimerState> {
  RestTimerController() : super(RestTimerState.idle);

  Timer? _ticker;
  DateTime? _endTime;

  void start(Duration duration) {
    _endTime = DateTime.now().add(duration);
    state = RestTimerState(remaining: duration, total: duration);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  void skip() {
    _ticker?.cancel();
    _endTime = null;
    state = RestTimerState.idle;
  }

  void _tick() {
    final end = _endTime;
    if (end == null) return;
    final now = DateTime.now();
    final remaining = remainingRestTime(endTime: end, now: now);
    state = RestTimerState(remaining: remaining, total: state.total);
    if (isRestTimerFinished(endTime: end, now: now)) {
      _ticker?.cancel();
      _endTime = null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final restTimerControllerProvider =
    StateNotifierProvider.autoDispose<RestTimerController, RestTimerState>(
      (ref) => RestTimerController(),
    );
