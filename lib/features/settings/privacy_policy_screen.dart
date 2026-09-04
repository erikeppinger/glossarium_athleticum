import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Shows the bundled privacy policy (docs/PRIVACY_POLICY.md) in-app, so
/// there's a copy of it available without needing a network connection or a
/// hosted page. Store listings (Play Console's Data Safety section, App
/// Store Connect's App Privacy page) still need this same content hosted at
/// a public URL - that's a one-time step outside the app itself, not
/// something this screen replaces.
///
/// Rendered with a small hand-rolled parser rather than a markdown package:
/// the source file only ever uses `#`/`##` headings, `**bold**`, and `- `
/// bullets, so a real markdown renderer would be a dependency for three
/// tokens.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: FutureBuilder<String>(
        future: rootBundle.loadString('docs/PRIVACY_POLICY.md'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final lines = snapshot.data!.split('\n');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [for (final line in lines) _renderLine(context, line)],
          );
        },
      ),
    );
  }

  Widget _renderLine(BuildContext context, String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return const SizedBox(height: 12);

    if (trimmed.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(
          trimmed.substring(3),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
    }
    if (trimmed.startsWith('# ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          trimmed.substring(2),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      );
    }

    final isBullet = trimmed.startsWith('- ');
    final content = isBullet ? trimmed.substring(2) : trimmed;

    return Padding(
      padding: EdgeInsets.only(left: isBullet ? 16 : 0, bottom: 2),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            if (isBullet) const TextSpan(text: '• '),
            ..._parseBold(content),
          ],
        ),
      ),
    );
  }

  /// Splits on `**bold**` markers into plain/bold [TextSpan]s.
  List<TextSpan> _parseBold(String text) {
    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(
        TextSpan(
          text: parts[i],
          style: i.isOdd
              ? const TextStyle(fontWeight: FontWeight.bold)
              : null,
        ),
      );
    }
    return spans;
  }
}
