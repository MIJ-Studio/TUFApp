import 'package:flutter/material.dart';

import '../../app/controllers.dart';
import '../../core/image_cache_store.dart';
import '../../core/l10n.dart';
import 'hover_tip.dart';
import 'motion.dart';

/// Difficulty or tag icon. Leaves an empty slot if it can't be loaded.
class NetworkIcon extends StatefulWidget {
  const NetworkIcon(this.url, {super.key, required this.size, this.fallback, this.opacity = 1});

  final String? url;
  final double size;

  /// Image to draw if [url] fails (e.g. the Discord picture when a profile picture was deleted).
  final String? fallback;

  /// Image opacity (0–1), applied while painting instead of with a layer.
  final double opacity;

  /// The image [NetworkIcon] draws, defined in one place so precaching ([precache]) hits the same cache entry.
  ///
  /// Sources are 800–1300px but shown small, so they are decoded at display size only.
  /// That keeps them in the memory cache, so scrolling back and forth doesn't reload them.
  /// Decoded at twice the size and scaled down when painted, so cards at fractional offsets stay sharp.
  static ImageProvider provider(BuildContext context, String url, double size) =>
      DiskCachedImage(url, maxWidth: (size * MediaQuery.devicePixelRatioOf(context) * 2).ceil());

  /// Precaches icons; completes when all are ready (failures are skipped).
  /// Appearance animations should start only after this, or empty slots move and the images pop in later.
  static Future<void> precache(BuildContext context, Iterable<String?> urls, double size) => Future.wait([
    for (final url in urls.whereType<String>().toSet())
      precacheImage(provider(context, url, size), context, onError: (_, _) {}),
  ]);

  @override
  State<NetworkIcon> createState() => _NetworkIconState();
}

class _NetworkIconState extends State<NetworkIcon> with SingleTickerProviderStateMixin {
  /// Fades in only on the first load; cached icons are drawn right away.
  /// Opacity is applied while painting. A layer like AnimatedOpacity makes lists with many icons expensive to draw,
  /// and can freeze half-faded inside a baked row ([RasterSnapshot]).
  late final _fade = AnimationController(vsync: this, duration: Durations.short4);
  late final _curve = CurvedAnimation(parent: _fade, curve: Motion.enter);
  bool _shown = false;

  @override
  void dispose() {
    _curve.dispose();
    _fade.dispose();
    super.dispose();
  }

  void _onFrame(bool synchronous) {
    if (_shown) return;
    _shown = true;
    if (synchronous) {
      _fade.value = 1;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fade.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final src = widget.url;
    final size = widget.size;
    if (src == null) return SizedBox.square(dimension: size);

    final opacity = widget.opacity;
    return Image(
      image: NetworkIcon.provider(context, src, size),
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      isAntiAlias: true,
      gaplessPlayback: true,
      opacity: opacity >= 1 ? _curve : _curve.drive(Tween(begin: 0, end: opacity)),
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame != null) _onFrame(wasSynchronouslyLoaded);
        return child;
      },
      errorBuilder: (context, error, stackTrace) => widget.fallback == null
          ? SizedBox.square(dimension: size)
          : NetworkIcon(widget.fallback, size: size, opacity: opacity),
    );
  }
}

/// Shows a country code as a flag image (e.g. "KR").
///
/// Windows renders flag emoji as two letters, so an image is downloaded instead and cached with the icons.
class CountryFlag extends StatelessWidget {
  const CountryFlag({super.key, required this.country, this.height = 14});

  final String? country;
  final double height;

  @override
  Widget build(BuildContext context) {
    final code = country?.trim().toLowerCase();
    if (code == null || code.length != 2) return const SizedBox.shrink();

    return HoverTip(
      message: country!.toUpperCase(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Image(
          image: DiskCachedImage(
            'https://flagcdn.com/w40/$code.png',
            maxWidth: (height * MediaQuery.devicePixelRatioOf(context) * 2).ceil(),
          ),
          height: height,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Progress and cancel button shown in place of the download button while downloading.
class JobProgressIndicator extends StatelessWidget {
  const JobProgressIndicator({super.key, required this.job});

  final InstallJob job;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: job,
    builder: (context, _) => Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress updates every 100 ms, so animate between updates.
              if (job.fraction case final fraction?)
                TweenAnimationBuilder<double>(
                  tween: Tween(end: fraction),
                  duration: Durations.short4,
                  builder: (context, value, _) => LinearProgressIndicator(value: value),
                )
              else
                const LinearProgressIndicator(),
              const SizedBox(height: 4),
              Text(job.shortText, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
        IconButton(
          tooltip: l10n.cancel,
          visualDensity: VisualDensity.compact,
          onPressed: job.cancel,
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );
}

/// Bottom of a list when the next batch failed. Retries only when the user presses the button.
class LoadMoreError extends StatelessWidget {
  const LoadMoreError({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.couldntLoadMore,
            style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text(l10n.retry)),
        ],
      ),
    );
  }
}

/// Placeholder for empty or failed content.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});

  final Widget icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconTheme.merge(
          data: IconThemeData(size: 40, color: theme.colorScheme.onSurfaceVariant),
          child: icon,
        ),
        const SizedBox(height: 12),
        Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
        if (message != null) ...[
          const SizedBox(height: 4),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    );
  }
}

/// Maximum content width of every page (including 24px side padding); content is up to 1152 wide.
const pageMaxWidth = 1200.0;

/// 1234567 → "1,234,567"
String formatNumber(int value) => value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');

/// Same format as the website's formatDuration: "02:15", "1:02:15"
String formatDuration(Duration duration) {
  String two(int n) => n.toString().padLeft(2, '0');
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  return hours > 0 ? '$hours:${two(minutes)}:${two(seconds)}' : '${two(minutes)}:${two(seconds)}';
}

/// 120.0 → "120", 128.5 → "128.5"
String formatBpm(double bpm) =>
    bpm == bpm.roundToDouble() ? bpm.toInt().toString() : bpm.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');

/// 67016.0 → "67,016.00" (two decimals, like the website's leaderboard)
String formatScore(double score) {
  final text = score.toStringAsFixed(2);
  final dot = text.indexOf('.');
  return formatNumber(int.parse(text.substring(0, dot))) + text.substring(dot);
}

/// 0.9883 → "98.83%"
String formatAccuracy(double accuracy) => '${(accuracy * 100).toStringAsFixed(2)}%';

/// 1.0 → "1", 1.25 → "1.25"
String formatSpeed(double speed) => speed == speed.roundToDouble() ? speed.toInt().toString() : speed.toString();

/// 2026-05-05 → "2026년 5월 5일" / "May 5, 2026". Empty if unknown.
String formatDate(DateTime? date) {
  if (date == null) return '';
  final local = date.toLocal();
  return formatLongDate(local);
}
