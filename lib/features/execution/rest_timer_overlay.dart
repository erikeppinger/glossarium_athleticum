import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/rest_timer.dart';
import '../../main.dart' show navigatorKey;
import '../shared/pulsing_highlight.dart';
import 'execution_screen.dart';
import 'rest_timer_controller.dart';

/// A small floating chip, shown above every screen (see `main.dart`'s
/// `MaterialApp.builder`), for a running/just-finished rest timer (with its
/// own countdown/alarming state). Previously also covered a "session in
/// progress" case for when a session was left mid-training with no rest
/// timer running - removed (2026-09-11) as reported clutter, since it and
/// the rest timer's own notification could both be showing at once, and the
/// rest timer chip alone was judged enough of an "you're mid-workout"
/// signal; a session left with no timer running is still resumable from
/// Calendar/Plan Detail exactly as it always was.
///
/// Previously lived inside `HomeScreen`'s own build instead of floating over
/// the whole app - which happened to also hide it while `ExecutionScreen`
/// was on top (pushed on the same Navigator, so it covered the overlay
/// along with everything else), but as a side effect also hid it on *every*
/// other pushed screen, including Settings (reported live) and anything
/// else reached from a tab. [executionScreenVisibleProvider] now does that
/// exclusion explicitly.
class RestTimerOverlay extends ConsumerWidget {
  const RestTimerOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(executionScreenVisibleProvider)) {
      return const SizedBox.shrink();
    }
    final state = ref.watch(restTimerControllerProvider);

    if (state.isVisible) {
      return SafeArea(
        child: Padding(
          // Several tabs (Calendar's "Log activity", Plans' "Import plan")
          // have their own FloatingActionButton in this same bottom-right
          // corner - a plain 8px clearance sat the chip right on top of it,
          // blocking taps to the FAB underneath whenever it was showing. A
          // standard FAB is 56 logical pixels tall with a 16px margin from
          // the screen edge, so 84 clears it with a small gap to spare.
          // Since this overlay moved into `MaterialApp.builder` (floating
          // above every route), this Stack's own coordinate space is now the
          // *entire* screen - including `home_screen.dart`'s own bottom
          // `NavigationBar` (Material 3 default height 80) - rather than
          // just a tab's `Scaffold.body`, as it was when the overlay lived
          // inside `HomeScreen`'s own Stack. Without adding that back in,
          // "bottom: 84" now sits inside/behind the nav bar itself,
          // overlapping the FAB again exactly like the original report this
          // was first built to fix (reported live, again, 2026-09-09).
          padding: const EdgeInsets.only(right: 16, bottom: 84 + 80),
          child: Align(
            alignment: Alignment.bottomRight,
            child: _RestTimerChip(state: state),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// Uses main.dart's global navigatorKey rather than Navigator.of(context) -
// the caller (_RestTimerChip) lives inside RestTimerOverlay, itself a
// *sibling* of the app's actual routed content within MaterialApp.builder's
// own Stack (see main.dart), not a descendant of it. Navigator.of(context)
// from the chip's own context has no Navigator ancestor to find - confirmed
// live via a full flutter run log, where it crashed with "Null check
// operator used on a null value" inside Navigator.of on every tap (a release
// APK's own on-device log only showed a terse, unhelpful "Another exception
// was thrown").
void _openSession(int planSessionId) {
  navigatorKey.currentState?.push(
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
            if (planSessionId != null) _openSession(planSessionId);
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
