import 'package:flutter/material.dart';

import '../../app/controllers.dart';
import '../../core/image_cache_store.dart';
import 'motion.dart';

/// Video thumbnail behind a card, slightly blurred and at 25% opacity so the text stays readable.
class VideoBackdrop extends StatelessWidget {
  const VideoBackdrop({super.key, required this.videoLink, required this.hovered});

  static const _opacity = 0.25;
  static const _hoveredOpacity = 0.35;

  /// The backdrop is decoded at this width and blurred once in advance.
  /// Blurring while painting would composite a layer per card every frame.
  /// It is about 1/6 of the card width, so on screen it spreads about 6× this value — just enough to recognize shapes.
  /// A blurred image can stay small without showing when stretched. Small images stay in the memory cache,
  /// so scrolling back doesn't decode and blur again (320px would be about 300 KB each).
  static const _decodeWidth = 192;
  static const _blurSigma = 1.5;

  final String videoLink;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    final thumbnails = AppScope.of(context).thumbnails;

    // Resolved URLs draw right away without a FutureBuilder (so scrolling doesn't create a Future per card).
    if (thumbnails.isResolved(videoLink)) {
      final url = thumbnails.peek(videoLink);
      return url == null ? const SizedBox.shrink() : _image(url);
    }

    return FutureBuilder<String?>(
      future: thumbnails.resolve(videoLink),
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url == null) return const SizedBox.shrink();

        return _image(url);
      },
    );
  }

  Widget _image(String url) => AnimatedOpacity(
    opacity: hovered ? _hoveredOpacity : _opacity,
    duration: Motion.medium,
    curve: Motion.standard,
    child: Image(
      image: DiskCachedImage(url, maxWidth: _decodeWidth, blurSigma: _blurSigma),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      // Stretch the small image smoothly for a blurred look.
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) => wasSynchronouslyLoaded
          ? child
          : AnimatedOpacity(opacity: frame == null ? 0 : 1, duration: Motion.slow, curve: Motion.enter, child: child),
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    ),
  );
}
