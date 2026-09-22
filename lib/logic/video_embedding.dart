// Pure, DB-free helpers for the opt-in YouTube-embedding feature - see
// Exercises.embeddingAllowed's own doc comment for the data-model side.

/// Template/import boolean convention for the "Embedding" column: yes/y/1/true
/// (case-insensitive, trimmed) turn it on; anything else, including an empty
/// cell, is off. Deliberately never defaults to "on" for an unrecognized
/// value - see [embeddingActivationNote] for why an opt-in should never be
/// implicit.
bool parseEmbeddingFlag(String raw) {
  const truthy = {'yes', 'y', '1', 'true'};
  return truthy.contains(raw.trim().toLowerCase());
}

/// The inverse of [parseEmbeddingFlag], for writing a template/export cell.
String formatEmbeddingFlag(bool value) => value ? 'yes' : '';

final _youtubeIdPattern = RegExp(
  r'(?:youtube(?:-nocookie)?\.com/(?:watch\?v=|shorts/|embed/)|youtu\.be/)'
  r'([A-Za-z0-9_-]{6,})',
  caseSensitive: false,
);

/// Extracts the video id from a YouTube watch/shorts/embed/short-link URL,
/// or null if [url] isn't a recognizable YouTube URL. Deliberately narrow -
/// embedding only ever activates for YouTube specifically (per the feature's
/// own scope), never a generic "any video link" embed.
String? extractYoutubeVideoId(String url) {
  final match = _youtubeIdPattern.firstMatch(url.trim());
  return match?.group(1);
}

bool isYoutubeUrl(String url) => extractYoutubeVideoId(url) != null;

/// Shown when a user first turns on embedding for a specific video (exercise
/// creation/edit) - kept short for a confirmation dialog. The full policy
/// lives in docs/DISCLAIMER.md's "Embedded video" section, reachable from
/// Settings > About, which this text points to rather than repeating in full.
const embeddingActivationNote =
    'Embedded playback is for your own personal use - it does not give you '
    'or anyone you share this exercise/plan/library with the right to '
    'redistribute the video itself.\n\n'
    "If you share a plan or library that has embedding turned on, you're "
    'responsible for making sure you have the right to embed that specific '
    "video (or for citing it properly) - this app doesn't review the "
    "content of plans or libraries people create or import, it only "
    'provides the platform.\n\n'
    'See Settings > About > Disclaimer for the full policy.';
