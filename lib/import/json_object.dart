import 'dart:convert';

/// Decodes [text] as a single JSON object. Throws a [FormatException] for
/// anything else - text that isn't JSON at all, or valid JSON that isn't an
/// object (a list, a number) - so a caller can treat every unreadable file
/// with one `on FormatException` instead of a cast failing later on.
Map<String, dynamic> decodeJsonObject(String text) {
  final value = jsonDecode(text);
  if (value is Map<String, dynamic>) return value;
  throw const FormatException('Not a JSON object.');
}
