import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/rest_timer.dart';
import 'execution_screen.dart';
import 'rest_timer_controller.dart';

/// A small floating rest-timer indicator, shown above [HomeScreen]'s bottom
/// nav bar whenever a rest timer is running. Since `restTimerControllerProvider`
/// isn't autoDispose and this widget lives below where `ExecutionScreen` gets
/// pushed on the same Navigator, it's naturally hidden while the execution
/// screen (which has its own inline banner) is on top, and reappears the
/// moment the user navigates back to it - e.g. after checking something on
/// another tab mid-rest.
class RestTimerOverlay extends ConsumerWidget {
  const RestTimerOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(restTimerControllerProvider);
    if (!state.isRunning) return const SizedBox.shrink();

    final remaining = state.remaining ?? Duration.zero;
    final progress = state.total.inMilliseconds == 0
        ? 0.0
        : 1 - (remaining.inMilliseconds / state.total.inMilliseconds);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 8),
        child: Align(
          alignment: Alignment.bottomRight,
          child: Material(
            color: Theme.of(context).colorScheme.primaryContainer,
            elevation: 4,
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () {
                final planSessionId = state.planSessionId;
                if (planSessionId == null) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ExecutionScreen(planSessionId: planSessionId),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        value: progress.clamp(0, 1),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Rest: ${formatRestTime(remaining)}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
