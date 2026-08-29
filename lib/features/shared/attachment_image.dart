import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/local_storage.dart';

/// Displays an attachment by its stored *filename*, resolving it to a real
/// path at build time.
///
/// Resolution happens here rather than at save time because the app's sandbox
/// directory changes across reinstalls and OS upgrades - a path stored in the
/// database would silently stop resolving, while a filename keeps working.
///
/// A missing file renders [fallback] rather than throwing: a backup restored
/// onto a different device carries the database but not the image files, and
/// that shouldn't break the screen.
class AttachmentImage extends StatelessWidget {
  final String fileName;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;

  const AttachmentImage({
    super.key,
    required this.fileName,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: resolveAttachmentPath(fileName),
      builder: (context, snapshot) {
        final path = snapshot.data;
        if (path == null) {
          return SizedBox(width: width, height: height);
        }
        final file = File(path);
        if (!file.existsSync()) return _fallbackWidget(context);
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, _, _) => _fallbackWidget(context),
        );
      },
    );
  }

  Widget _fallbackWidget(BuildContext context) =>
      fallback ??
      Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Theme.of(context).colorScheme.outline,
        ),
      );
}
