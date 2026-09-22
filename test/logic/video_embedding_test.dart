import 'package:flutter_test/flutter_test.dart';
import 'package:training_app/logic/video_embedding.dart';

void main() {
  group('parseEmbeddingFlag', () {
    test('recognizes yes/y/1/true, case-insensitively and trimmed', () {
      for (final raw in ['yes', 'Yes', ' YES ', 'y', 'Y', '1', 'true', 'TRUE']) {
        expect(parseEmbeddingFlag(raw), isTrue, reason: 'for "$raw"');
      }
    });

    test('empty or unrecognized values are off, not an error', () {
      for (final raw in ['', ' ', 'no', 'n', '0', 'false', 'maybe']) {
        expect(parseEmbeddingFlag(raw), isFalse, reason: 'for "$raw"');
      }
    });
  });

  group('formatEmbeddingFlag', () {
    test('round-trips through parseEmbeddingFlag', () {
      expect(parseEmbeddingFlag(formatEmbeddingFlag(true)), isTrue);
      expect(parseEmbeddingFlag(formatEmbeddingFlag(false)), isFalse);
    });
  });

  group('extractYoutubeVideoId', () {
    test('matches watch, shorts, embed, and youtu.be forms', () {
      expect(
        extractYoutubeVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
      expect(
        extractYoutubeVideoId('https://youtu.be/dQw4w9WgXcQ?t=30'),
        'dQw4w9WgXcQ',
      );
      expect(
        extractYoutubeVideoId('https://www.youtube.com/shorts/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
      expect(
        extractYoutubeVideoId(
          'https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ',
        ),
        'dQw4w9WgXcQ',
      );
    });

    test('returns null for a non-YouTube link', () {
      expect(extractYoutubeVideoId('https://vimeo.com/12345'), isNull);
      expect(extractYoutubeVideoId(''), isNull);
    });
  });

  group('isYoutubeUrl', () {
    test('matches extractYoutubeVideoId', () {
      expect(isYoutubeUrl('https://youtu.be/dQw4w9WgXcQ'), isTrue);
      expect(isYoutubeUrl('https://example.com/video'), isFalse);
    });
  });
}
