import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_preferences.dart';

/// The one interactive step in an otherwise static tour - lets the app feed
/// a real experience level into `suggestNextSet` (see
/// `history_screen.dart`) instead of assuming everyone is intermediate.
/// Selecting a level applies it immediately, so skipping the tour via the
/// top-right "Skip" button still leaves the sensible default in place
/// rather than an unset/invalid state.
class _ExperienceLevelPage extends ConsumerWidget {
  const _ExperienceLevelPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(appPreferencesProvider).experienceLevel;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up,
            size: 88,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'How experienced are you?',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'This tunes how quickly weight suggestions increase as you log '
            'sets - you can change it later in Settings.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final level in ExperienceLevel.values)
                ChoiceChip(
                  label: Text(level.label),
                  selected: level == current,
                  onSelected: (_) => ref
                      .read(appPreferencesProvider.notifier)
                      .setExperienceLevel(level),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TourPage {
  final IconData icon;
  final String title;
  final String body;

  const _TourPage({
    required this.icon,
    required this.title,
    required this.body,
  });
}

const _pages = [
  _TourPage(
    icon: Icons.fitness_center,
    title: 'Your exercise library',
    body:
        'Browse the built-in exercises, or tap + to add your own with '
        'descriptions, cues, and a reference video. Filter by category or '
        'by who created them.',
  ),
  _TourPage(
    icon: Icons.list_alt,
    title: 'Build a plan',
    body:
        'Import a plan from a spreadsheet, or add exercises to one straight '
        'from the library. Tap the pencil on a session to change sets, reps, '
        'rest, or the order of its exercises.',
  ),
  _TourPage(
    icon: Icons.calendar_month,
    title: 'Schedule and train',
    body:
        'Assign sessions to days on the calendar, then tap one to start. '
        'While training, each set is logged inline and a rest timer runs '
        'between them - it keeps counting even if you switch tabs.',
  ),
  _TourPage(
    icon: Icons.insights,
    title: 'See your progress',
    body:
        'The Progress tab shows a week or month summary, your recent top set '
        'per exercise, and personal records. You can also track bodyweight '
        'and measurements over time.',
  ),
  _TourPage(
    icon: Icons.lock_outline,
    title: 'Your data stays yours',
    body:
        'Everything is stored on this device. Export an encrypted backup, or '
        'share a single plan with someone, whenever you choose to - nothing '
        'leaves your phone on its own.',
  ),
];

/// A first-launch walkthrough of the app's main areas. Shown once (tracked
/// by [AppPreferences.hasSeenOnboarding]) and re-openable from Settings.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(appPreferencesProvider.notifier).setHasSeenOnboarding(true);
    if (mounted) Navigator.of(context).pop();
  }

  // The interactive experience-level step comes after the static tour pages.
  static final int _totalPages = _pages.length + 1;

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _totalPages - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _totalPages,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) => index < _pages.length
                    ? _TourPageView(page: _pages[index])
                    : const _ExperienceLevelPage(),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _totalPages; i++)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _page
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton(
                onPressed: isLast
                    ? _finish
                    : () => _controller.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text(isLast ? 'Get started' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TourPageView extends StatelessWidget {
  final _TourPage page;

  const _TourPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            page.icon,
            size: 88,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.body,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
