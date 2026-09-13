import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_preferences.dart';
import 'whats_new_content.dart';

/// Shown once to an existing device after an update adds new entries to
/// [whatsNewItems] (see `AppPreferences.lastSeenWhatsNewRevision`'s doc
/// comment for the gating logic), and reachable anytime after that from
/// Settings > About > "What's new" - unlike the first-launch tour
/// (`OnboardingScreen`), this is a plain scrollable list rather than a
/// swipeable walkthrough, since it's a set of independent highlights to
/// skim, not a sequence to step through.
class WhatsNewScreen extends ConsumerWidget {
  const WhatsNewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text("What's new")),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: whatsNewItems.length,
                separatorBuilder: (context, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = whatsNewItems[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: Icon(
                              item.icon,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(item.body),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    ref
                        .read(appPreferencesProvider.notifier)
                        .setLastSeenWhatsNewRevision(currentWhatsNewRevision);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Got it'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
