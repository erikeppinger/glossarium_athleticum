import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home_screen.dart' show homeTabIndexProvider, settingsAppBarAction;
import '../../logic/progression.dart' show formatWeight;
import '../../logic/summary_period.dart';
import '../calendar/log_activity_flow.dart';
import '../execution/rest_timer_controller.dart' show activeInProgressSessionIdProvider;
import '../execution/start_session_helper.dart';
import '../plans/random_workout_screen.dart';
import '../progress/progress_providers.dart';
import '../settings/app_preferences.dart';
import 'today_providers.dart';

/// The app's default landing screen - "what do I do right now" rather than
/// making the user pick a tab first. Deliberately reuses existing providers
/// verbatim (streak/week-summary from `progress_providers.dart`, next
/// session from `today_providers.dart`, which itself derives from the
/// Calendar tab's own providers) rather than any new logic of its own, so
/// this screen can never show a different answer than Calendar/Progress do.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextSessionAsync = ref.watch(nextScheduledSessionProvider);
    final prefs = ref.watch(appPreferencesProvider);
    // Skip both provider watches entirely while hidden - there's nothing to
    // show, so there's no reason to pay for the DB read either.
    final hideStreaks = prefs.hideStreaksActive;
    final streakAsync = hideStreaks ? null : ref.watch(currentStreakProvider);
    final weekRange = computeSummaryRange(
      period: SummaryPeriod.week,
      weekStart: prefs.weekStart,
      offset: 0,
      now: DateTime.now(),
    );
    final weekSummaryAsync = hideStreaks
        ? null
        : ref.watch(periodSummaryProvider(weekRange));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [settingsAppBarAction(context)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          nextSessionAsync.when(
            data: (next) => next == null
                ? const _InfoCard(
                    icon: Icons.event_available,
                    title: 'Nothing scheduled',
                    subtitle: 'No upcoming sessions - build or schedule a '
                        'plan to see it here.',
                  )
                : Card(
                    child: ListTile(
                      leading: const Icon(Icons.fitness_center),
                      title: Text(next.session.sessionName),
                      // A non-breaking space between "Week" and its number
                      // keeps the two from splitting across a line break -
                      // reported live (2026-09-11): on a long plan name (a
                      // random workout's auto date-suffixed name plus this
                      // subtitle's own repeated date easily overflows one
                      // line), a plain space there let the number alone wrap
                      // to its own line, reading like a rendering glitch.
                      subtitle: Text(
                        '${next.planName} • Week ${next.session.weekNumber} • '
                        '${MaterialLocalizations.of(context).formatMediumDate(next.date)}',
                      ),
                      trailing: FilledButton(
                        onPressed: () => startSessionWithMoveToTodayPrompt(
                          context,
                          ref,
                          next.session,
                          next.date,
                        ),
                        // Reported live (2026-09-11): this always said
                        // "Start", even for a session already left mid-way
                        // via "Leave" (still resumable - see
                        // activeInProgressSessionIdProvider's own doc
                        // comment) - functionally harmless (tapping it
                        // reopens ExecutionScreen, which already restores
                        // the existing draft on its own), but reads as if
                        // starting fresh would discard what's there.
                        child: Text(
                          ref.watch(activeInProgressSessionIdProvider) ==
                                  next.session.id
                              ? 'Resume'
                              : 'Start',
                        ),
                      ),
                    ),
                  ),
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, _) => _InfoCard(
              icon: Icons.error_outline,
              title: 'Could not load your next session',
              subtitle: '$error',
            ),
          ),
          if (!hideStreaks) ...[
            const SizedBox(height: 12),
            streakAsync!.when(
              data: (streak) => streak <= 0
                  ? const SizedBox.shrink()
                  : Card(
                      child: ListTile(
                        leading: const Text(
                          '🔥',
                          style: TextStyle(fontSize: 24),
                        ),
                        title: Text(
                          '$streak day${streak == 1 ? '' : 's'} streak',
                        ),
                      ),
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            weekSummaryAsync!.when(
              data: (summary) => Card(
                child: InkWell(
                  // The Progress tab already shows this same period-summary
                  // data in full - tapping through there is more useful than
                  // this card being a dead end, since Today otherwise has
                  // very little to actually interact with (reported live).
                  onTap: () =>
                      ref.read(homeTabIndexProvider.notifier).state = 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'This week',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Scheduled: ${summary.sessionsCompleted}/'
                          '${summary.sessionsScheduled}  •  '
                          'Volume: ${formatWeight(summary.totalVolume, prefs.weightUnit)}  •  '
                          'PRs: ${summary.prCount}',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
          const SizedBox(height: 24),
          Text('Quick actions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RandomWorkoutScreen(),
                  ),
                ),
                icon: const Icon(Icons.shuffle),
                label: const Text('Random workout'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    showLogActivityFlow(context, ref, DateTime.now()),
                icon: const Icon(Icons.directions_walk),
                label: const Text('Log activity'),
              ),
              // With nothing scheduled, the only way to actually start a
              // workout used to be switching to the Plans tab yourself -
              // reported live as an easy-to-miss extra step when this screen
              // (the app's own default landing tab) otherwise has nothing to
              // offer on a day with no plan.
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(homeTabIndexProvider.notifier).state = 2,
                icon: const Icon(Icons.list_alt),
                label: const Text('Browse plans'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
