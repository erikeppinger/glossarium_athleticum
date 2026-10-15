import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

final _urlPattern = RegExp(r'https?://[^\s]+');

/// Splits [text] into plain runs and web links, with trailing punctuation
/// ("see https://x.y.") left out of the link.
List<({String text, bool isLink})> splitLinks(String text) {
  final parts = <({String text, bool isLink})>[];
  var start = 0;
  for (final match in _urlPattern.allMatches(text)) {
    var url = match.group(0)!;
    final trimmed = url.replaceFirst(RegExp(r'[.,;:!?)\]]+$'), '');
    url = trimmed.isEmpty ? url : trimmed;
    if (match.start > start) {
      parts.add((text: text.substring(start, match.start), isLink: false));
    }
    parts.add((text: url, isLink: true));
    start = match.start + url.length;
  }
  if (start < text.length) {
    parts.add((text: text.substring(start), isLink: false));
  }
  return parts;
}

/// Plain text in which every web link opens in the browser when tapped -
/// e.g. an exercise description that points to a video or to the
/// exercise's page on wger.de.
class LinkedText extends StatefulWidget {
  const LinkedText(this.text, {super.key});

  final String text;

  @override
  State<LinkedText> createState() => _LinkedTextState();
}

class _LinkedTextState extends State<LinkedText> {
  // One recognizer per link, rebuilt only when the text changes - never in
  // build(), where the previous frame may still be using them.
  late List<({String text, bool isLink})> _parts;
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void initState() {
    super.initState();
    _split();
  }

  @override
  void didUpdateWidget(LinkedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _split();
  }

  void _split() {
    _disposeRecognizers();
    _parts = splitLinks(widget.text);
    for (final part in _parts) {
      if (part.isLink) {
        _recognizers.add(
          TapGestureRecognizer()..onTap = () => _open(part.text),
        );
      }
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    final launched =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't open this link.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
    );
    var link = 0;
    return Text.rich(
      TextSpan(
        children: [
          for (final part in _parts)
            if (part.isLink)
              TextSpan(
                text: part.text,
                style: linkStyle,
                recognizer: _recognizers[link++],
              )
            else
              TextSpan(text: part.text),
        ],
      ),
    );
  }
}
