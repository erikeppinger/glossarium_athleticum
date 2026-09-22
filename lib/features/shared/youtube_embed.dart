import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Embedded YouTube playback where a maintained Flutter WebView exists
/// (Android only - see pubspec.yaml's own note on this dependency); a
/// thumbnail-plus-play-button that opens the video externally everywhere
/// else, rather than pretending desktop support exists. Only ever shown
/// when the exercise/plan-exercise's own `embeddingAllowed` flag is true and
/// the URL is a recognized YouTube link (see lib/logic/video_embedding.dart) -
/// callers are responsible for that check, this widget just renders.
class YoutubeEmbed extends StatefulWidget {
  final String videoId;

  const YoutubeEmbed({super.key, required this.videoId});

  @override
  State<YoutubeEmbed> createState() => _YoutubeEmbedState();
}

class _YoutubeEmbedState extends State<YoutubeEmbed> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: widget.videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(showFullscreenButton: true),
      );
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: YoutubePlayer(controller: controller),
      );
    }
    return _ThumbnailFallback(videoId: widget.videoId);
  }
}

class _ThumbnailFallback extends StatelessWidget {
  final String videoId;

  const _ThumbnailFallback({required this.videoId});

  Future<void> _open(BuildContext context) async {
    final uri = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the video link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => ColoredBox(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                Material(
                  color: Colors.black38,
                  child: InkWell(
                    onTap: () => _open(context),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Embedded playback isn't available on this platform yet - tap to "
          'open in your browser instead.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
