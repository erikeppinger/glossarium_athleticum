import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Shows a bundled markdown doc in-app, so a copy is available without a
/// network connection or a hosted page - used for both the Privacy Policy
/// and the Disclaimer (see `docs/PRIVACY_POLICY.md`/`docs/DISCLAIMER.md`).
///
/// Rendered with a small hand-rolled parser rather than a markdown package:
/// these source files only ever use `#`/`##` headings, `**bold**`, and `- `
/// bullets, so a real markdown renderer would be a dependency for three
/// tokens.
class MarkdownDocScreen extends StatelessWidget {
  final String title;
  final String assetPath;

  const MarkdownDocScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(assetPath),
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
