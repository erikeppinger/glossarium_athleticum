import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/rest_timer.dart';
import '../shared/pulsing_highlight.dart';
import 'execution_screen.dart';
import 'rest_timer_controller.dart';

/// A small floating chip, shown above [HomeScreen]'s bottom nav bar, that
/// covers two related but distinct cases: a running/just-finished rest
/// timer (with its own countdown/alarming state), or - when no timer is
/// currently running at all - a plain "session in progress" reminder for a
/// session that was left mid-training via [_LeaveChoice.leave] rather than
/// finished or discarded. Before the second case existed, the *only* way
/// back to a left-but-unfinished session was a running rest timer - leaving
/// between sets (nothing resting right then) meant no indicator anywhere
/// pointed back to it at all. Since neither underlying provider is
/// autoDispose and this widget lives below where `ExecutionScreen` gets
/// pushed on the same Navigator, it's naturally hidden while the execution
/// screen (which has its own inline banner) is on top, and reappears the
/// moment the user navigates back to it - e.g. after checking something on
/// another tab mid-rest.
class RestTimerOverlay extends ConsumerWidget {
  const RestTimerOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(restTimerControllerProvider);
    final inProgressSessionId = ref.watch(activeInProgressSessionIdProvider);

    final Widget chip;
    if (state.isVisible) {
      chip = _RestTimerChip(state: state);
    } else if (inProgressSessionId != null) {
      chip = _ResumeSessionChip(planSessionId: inProgressSessionId);
    } else {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Padding(
        // Several tabs (Calendar's "Log activity", Plans' "Import plan")
        // have their own FloatingActionButton in this same bottom-right
        // corner - a plain 8px clearance sat the chip right on top of it,
        // blocking taps to the FAB underneath whenever it was showing.
        // A standard FAB is 56 logical pixels tall with a 16px margin from
        // the screen edge, so 84 clears it with a small gap to spare.
        padding: const EdgeInsets.only(right: 16, bottom: 84),
        child: Align(alignment: Alignment.bottomRight, child: chip),
      ),
    );
  }
}

void _openSession(BuildContext context, int planSessionId) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => ExecutionScreen(planSessionId: planSessionId),
    ),
  );
}

class _RestTimerChip extends StatelessWidget {
  final RestTimerState state;

  const _RestTimerChip({required this.state});

  @override
  Widget build(BuildContext context) {
    final remaining = state.remaining ?? Duration.zero;
    final progress = state.total.inMilliseconds == 0
        ? 0.0
        : 1 - (remaining.inMilliseconds / state.total.inMilliseconds);
    // Alarming (red, pulsing) once there's little rest left or it's already
    // over - a plain static chip was too easy to miss while looking at a
    // different tab, which is exactly when this matters most.
    final alarming = state.overdue || isRestTimerNearEnd(remaining);

    return PulsingHighlight(
      active: alarming,
      child: Material(
        color: alarming
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.primaryContainer,
        elevation: 4,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () {
            final planSessionId = state.planSessionId;
            if (planSessionId != null) _openSession(context, planSessionId);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  // Purely decorative alongside the "Rest: MM:SS" text right
                  // next to it - without this a screen reader announces a
                  // redundant, constantly-updating "26%" progress value on
                  // top of the time that already says the same thing in a
                  // more useful form.
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: state.overdue
                        ? Icon(
                            Icons.notifications_active,
                            size: 20,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          )
                        : CircularProgressIndicator(
                            value: progress.clamp(0, 1),
                            strokeWidth: 3,
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  state.overdue
                      ? 'Rest over - back to it'
                      : 'Rest: ${formatRestTime(remaining)}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown instead of [_RestTimerChip] when a session was left mid-training
/// but no rest timer happens to be running right now - a plain, non-alarming
/// pointer back to it, since there's nothing time-sensitive about it the way
/// a running rest period is.
class _ResumeSessionChip extends StatelessWidget {
  final int planSessionId;

  const _ResumeSessionChip({required this.planSessionId});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      elevation: 4,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => _openSession(context, planSessionId),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fitness_center, size: 20),
              const SizedBox(width: 10),
              Text(
                'Session in progress',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
