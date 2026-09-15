import 'package:flutter/material.dart';

Future<String?> promptPassphrase(
  BuildContext context, {
  required String title,
  String? helperText,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) =>
        _PassphraseDialog(title: title, helperText: helperText),
  );
}

// Owns its own controller (disposed in its own State.dispose()) rather than
// one created inline by promptPassphrase() and disposed after showDialog
// resolves - the latter races the dialog's own exit transition, a real,
// reproducible crash this project has hit before (see the dialog-disposal
// convention in CLAUDE.md). Needed here anyway once this became a
// StatefulWidget to hold the show/hide toggle below.
class _PassphraseDialog extends StatefulWidget {
  final String title;
  final String? helperText;

  const _PassphraseDialog({required this.title, this.helperText});

  @override
  State<_PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends State<_PassphraseDialog> {
  final _controller = TextEditingController();
  bool _obscured = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        obscureText: _obscured,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Passphrase',
          helperText: widget.helperText,
          helperMaxLines: 3,
          suffixIcon: IconButton(
            icon: Icon(_obscured ? Icons.visibility : Icons.visibility_off),
            tooltip: _obscured ? 'Show passphrase' : 'Hide passphrase',
            onPressed: () => setState(() => _obscured = !_obscured),
          ),
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

Future<bool> confirmDestructiveAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
