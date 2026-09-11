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
