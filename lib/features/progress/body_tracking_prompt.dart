import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_preferences.dart';

/// Asks once, the first time someone starts a session, whether they want to
/// track bodyweight and measurements.
///
/// Deliberately opt-in rather than on-by-default. Weighing yourself is not a
/// neutral act - plenty of people train specifically without tracking weight,
/// and for some it is actively unhelpful. A "no" is remembered permanently so
/// the question is never repeated; it can still be turned on later from
/// Settings if they change their mind.
Future<void> maybeAskAboutBodyTracking(
  BuildContext context,
  WidgetRef ref,
) async {
  final prefs = ref.read(appPreferencesProvider);
  if (prefs.bodyTracking != BodyTracking.notAsked) return;

  final choice = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.straighten),
      title: const Text('Track body measurements?'),
      content: const Text(
        'Alongside your training, the app can optionally track bodyweight '
        'and body measurements over time.\n\n'
        "This is entirely optional - plenty of people train without it, and "
        'everything else works exactly the same either way. You can change '
        'this later in Settings.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('No thanks'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Yes, track it'),
        ),
      ],
    ),
  );

  // A dismissed dialog (tapped outside) is not an answer - leave it unasked
  // so the question can come back next time rather than defaulting to "no".
  if (choice == null) return;

  await ref
      .read(appPreferencesProvider.notifier)
      .setBodyTracking(choice ? BodyTracking.enabled : BodyTracking.declined);
}
