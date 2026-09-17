import 'package:flutter/material.dart';

/// A small "what does this mean?" dialog, reused everywhere an info icon
/// explains a feature (e.g. supersets) in plain language.
Future<void> showInfoDialog(
  BuildContext context, {
  required String title,
  required String content,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: Text(content)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

/// One collapsible entry in [showInfoSectionsDialog].
class InfoSection {
  final String title;
  final String content;

  const InfoSection({required this.title, required this.content});
}

/// A single info icon covering several related explanations at once, each
/// collapsed by default - reported live (2026-09-18): a separate info icon
/// per concept (block/superset/exercise order) on the same toolbar reads as
/// UI clutter once there are three of them, even though each one alone is
/// reasonable. One icon, one dialog, expand only what's actually being
/// asked about.
Future<void> showInfoSectionsDialog(
  BuildContext context, {
  required String title,
  required List<InfoSection> sections,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final section in sections)
                ExpansionTile(
                  title: Text(section.title),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(section.content)],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
