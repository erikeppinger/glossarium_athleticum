import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show KeyDownEvent, LogicalKeyboardKey;

import 'attachment_image.dart';

/// Full-screen, pinch-zoomable view of one or more attachment photos.
///
/// Reported live: a gallery thumbnail (the exercise detail screen's
/// [AttachmentImage] at a fixed height with the default `BoxFit.cover`)
/// deliberately crops to fill its box, and had no way to see the whole,
/// uncropped photo - tapping it did nothing. Pushed from wherever a gallery
/// thumbnail is shown, landing on whichever photo was actually tapped
/// ([initialIndex]) and letting the user move to the others from there -
/// by swiping, by the on-screen arrows, or (requested live, since a mouse
/// drag is an awkward way to page through photos on desktop) the left/right
/// arrow keys.
class PhotoViewerScreen extends StatefulWidget {
  final List<String> fileNames;
  final int initialIndex;
  final String? title;

  const PhotoViewerScreen({
    super.key,
    required this.fileNames,
    this.initialIndex = 0,
    this.title,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final _controller = PageController(initialPage: widget.initialIndex);
  late int _page = widget.initialIndex;
  final _keyboardFocusNode = FocusNode();

  // One InteractiveViewer per photo, each with its own zoom state - found
  // live (2026-09-14) that a naive InteractiveViewer-per-page inside a
  // PageView swallows the horizontal swipe used to move between photos even
  // at 1x/no zoom: InteractiveViewer's own pan recognizer wins the gesture
  // arena against PageView's drag recognizer regardless of whether panning
  // would actually move anything. Disabling panEnabled while at 1x lets the
  // drag fall through to the PageView instead - the standard fix for this
  // exact InteractiveViewer-inside-a-pager conflict - and it's re-enabled
  // per-photo once that photo is actually zoomed in, so panning around a
  // zoomed photo still works.
  late final _transformControllers = [
    for (var _ in widget.fileNames) TransformationController(),
  ];
  late final _zoomed = List.filled(widget.fileNames.length, false);

  @override
  void dispose() {
    _controller.dispose();
    _keyboardFocusNode.dispose();
    for (final controller in _transformControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onInteractionEnd(int index) {
    final scale = _transformControllers[index].value.getMaxScaleOnAxis();
    final isZoomed = scale > 1.01;
    if (isZoomed != _zoomed[index]) {
      setState(() => _zoomed[index] = isZoomed);
    }
  }

  void _goToPage(int page) {
    if (page < 0 || page >= widget.fileNames.length) return;
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _goToPage(_page - 1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _goToPage(_page + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final multiple = widget.fileNames.length > 1;
    return Scaffold(
      // A black backdrop (rather than the app's own theme background) so a
      // photo with transparent/white edges stays clearly separated from the
      // chrome around it, matching the usual full-screen-photo-viewer look.
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          multiple
              ? '${widget.title ?? 'Photo'} (${_page + 1}/${widget.fileNames.length})'
              : widget.title ?? 'Photo',
        ),
      ),
      body: KeyboardListener(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.fileNames.length,
              onPageChanged: (index) => setState(() => _page = index),
              itemBuilder: (context, index) => InteractiveViewer(
                transformationController: _transformControllers[index],
                panEnabled: _zoomed[index],
                minScale: 1,
                maxScale: 5,
                onInteractionEnd: (_) => _onInteractionEnd(index),
                child: Center(
                  child: AttachmentImage(
                    fileName: widget.fileNames[index],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    semanticLabel: multiple
                        ? 'Photo ${index + 1} of ${widget.fileNames.length}'
                        : 'Photo',
                  ),
                ),
              ),
            ),
            if (multiple) ...[
              _NavArrow(
                alignment: Alignment.centerLeft,
                icon: Icons.chevron_left,
                tooltip: 'Previous photo',
                onPressed: _page > 0 ? () => _goToPage(_page - 1) : null,
              ),
              _NavArrow(
                alignment: Alignment.centerRight,
                icon: Icons.chevron_right,
                tooltip: 'Next photo',
                onPressed: _page < widget.fileNames.length - 1
                    ? () => _goToPage(_page + 1)
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A left/right paging control over the photo, on top of swipe and the
/// arrow keys - requested live specifically for Windows, where dragging
/// with a mouse to page between photos is a lot less natural than an
/// actual click target or a key press.
class _NavArrow extends StatelessWidget {
  final AlignmentGeometry alignment;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _NavArrow({
    required this.alignment,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: IconButton.filled(
          onPressed: onPressed,
          icon: Icon(icon),
          tooltip: tooltip,
          style: IconButton.styleFrom(
            backgroundColor: Colors.black.withValues(alpha: 0.45),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.black.withValues(alpha: 0.2),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}
