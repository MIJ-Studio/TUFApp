import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../app/controllers.dart';
import '../../../core/image_cache_store.dart';
import '../../../core/l10n.dart';
import '../../../core/models/level.dart';
import '../../../core/models/profile.dart';
import '../../widgets/common.dart';
import '../../widgets/embedded_video.dart';
import '../../widgets/hover_tip.dart';
import '../../widgets/motion.dart';
import '../level_viewer_page.dart';
import '../pass_viewer_page.dart';

/// A supporter's bio canvas, drawn like the website's BioCanvasRenderer.
///
/// Blocks are placed freely on a 1000×1200 stage by their x/y/w/h and rotation, may overlap (later blocks on top)
/// and are clipped at the stage edges. The stage is scaled down to fit narrower widths, never up.
class BioCanvas extends StatelessWidget {
  const BioCanvas({super.key, required this.blocks});

  final List<BioBlock> blocks;

  static const _stageWidth = BioLayout.stageWidth * 1.0;
  static const _stageHeight = BioLayout.stageHeight * 1.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = min(1.0, constraints.maxWidth / _stageWidth);
      return Center(
        heightFactor: 1,
        child: SizedBox(
          width: _stageWidth * scale,
          height: _stageHeight * scale,
          child: ClipRect(
            child: FittedBox(
              fit: BoxFit.fill,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: _stageWidth,
                height: _stageHeight,
                child: Stack(clipBehavior: Clip.none, children: [for (final block in blocks) _placed(block)]),
              ),
            ),
          ),
        ),
      );
    },
  );

  static Widget _placed(BioBlock block) {
    final layout = block.layout;
    Widget child = switch (block) {
      BioTextBlock() => _TextBlock(block: block),
      BioLinkBlock() => _LinkBlock(block: block),
      BioSocialBlock() => _SocialBlock(block: block),
      BioImageBlock() => _ImageBlock(block: block),
      BioEmbedBlock() => _EmbedBlock(block: block),
      BioFeaturedBlock() => _FeaturedBlock(block: block),
    };
    if (!block.fixedHeight) {
      child = Container(
        constraints: BoxConstraints(minHeight: layout.h.toDouble()),
        alignment: Alignment.center,
        child: child,
      );
    }
    if (layout.rotation != 0) child = Transform.rotate(angle: layout.rotation * pi / 180, child: child);
    return Positioned(
      left: layout.x.toDouble(),
      top: layout.y.toDouble(),
      width: layout.w.toDouble(),
      height: block.fixedHeight ? layout.h.toDouble() : null,
      child: child,
    );
  }
}

/// The website's colors for canvas blocks.
abstract final class _BioColors {
  static const text = Color(0xFFF9FAFB);
  static const body = Color(0xFFCACACA);
  static const placeholder = Color(0xFF838383);
  static const accent = Color(0xFF643DFF);
  static const surface = Color(0x66090909);
  static const border = Color(0x1AF9FAFB);
  static const hover = Color(0x1A4A90E2);
  static const hoverBorder = Color(0xFF7C5CFF);
}

Color? _parseColor(String? hex) {
  if (hex == null) return null;
  var digits = hex.substring(1);
  if (digits.length == 3) digits = digits.split('').map((c) => '$c$c').join();
  return Color(int.parse('FF$digits', radix: 16));
}

TextAlign _textAlign(String align) => switch (align) {
  'center' => TextAlign.center,
  'right' => TextAlign.right,
  _ => TextAlign.left,
};

/// Opens an external link after confirming, like the website's "Leaving TUF?" dialog.
/// Hosts trusted for this session open right away.
Future<void> _openExternal(BuildContext context, String url) async {
  final app = AppScope.of(context);
  final host = Uri.tryParse(url)?.host ?? url;
  if (_trustedHosts.contains(host)) return app.openLink(url);

  var trust = false;
  final go = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l10n.leavingTUF),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.youAreAboutTo),
              const SizedBox(height: 12),
              Text(host, style: Theme.of(context).textTheme.titleMedium),
              SelectableText(
                Uri.decodeFull(url),
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: trust,
                onChanged: (value) => setState(() => trust = value ?? false),
                title: Text(l10n.trustForThisSession(host)),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.proceed)),
        ],
      ),
    ),
  );
  if (go != true) return;
  if (trust) _trustedHosts.add(host);
  await app.openLink(url);
}

final _trustedHosts = <String>{};

// ───────────────────────── Text ─────────────────────────

/// Heading and body text. If they don't fit the frame, both font sizes shrink (down to 12) like the website's
/// useTextBlockFit; anything still overflowing is clipped.
class _TextBlock extends StatelessWidget {
  const _TextBlock({required this.block});

  final BioTextBlock block;

  static const _minFontSize = 12;

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style;
    final color = _parseColor(block.color);
    final heading = block.heading;
    final empty = block.body.trim().isEmpty;
    final align = _textAlign(block.align);

    TextStyle headingStyle(int size) =>
        base.copyWith(fontSize: size.toDouble(), fontWeight: FontWeight.bold, color: color ?? _BioColors.text);
    TextStyle bodyStyle(int size) => base.copyWith(
      fontSize: size.toDouble(),
      fontWeight: FontWeight.normal,
      fontStyle: empty ? FontStyle.italic : FontStyle.normal,
      color: empty ? _BioColors.placeholder.withValues(alpha: 0.85) : color ?? _BioColors.body,
    );
    final bodyText = empty ? 'Sample text' : block.body;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        double measure(int headingSize, int bodySize) {
          double height(String text, TextStyle style) {
            final painter = TextPainter(
              text: TextSpan(text: text, style: style),
              textDirection: TextDirection.ltr,
              textScaler: TextScaler.noScaling,
            )..layout(maxWidth: width);
            final result = painter.height;
            painter.dispose();
            return result;
          }

          return (heading == null ? 0 : height(heading, headingStyle(headingSize))) +
              height(bodyText, bodyStyle(bodySize));
        }

        var headingSize = block.headingFontSize;
        var bodySize = block.fontSize;
        final maxHeight = constraints.maxHeight;
        var contentHeight = measure(headingSize, bodySize);
        for (var i = 0; i < 48 && contentHeight > maxHeight; i++) {
          final scale = maxHeight / contentHeight;
          headingSize = max(_minFontSize, (block.headingFontSize * scale).floor());
          bodySize = max(_minFontSize, (block.fontSize * scale).floor());
          contentHeight = measure(headingSize, bodySize);
          if (headingSize == _minFontSize && bodySize == _minFontSize) break;
        }

        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            maxHeight: double.infinity,
            child: SizedBox(
              width: width,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (heading != null)
                    Text(heading, style: headingStyle(headingSize), textAlign: align, textScaler: TextScaler.noScaling),
                  Text(bodyText, style: bodyStyle(bodySize), textAlign: align, textScaler: TextScaler.noScaling),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ───────────────────────── Link ─────────────────────────

/// Full-width accent button.
class _LinkBlock extends StatelessWidget {
  const _LinkBlock({required this.block});

  final BioLinkBlock block;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Material(
      color: _BioColors.accent,
      borderRadius: BorderRadius.circular(6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openExternal(context, block.url),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            block.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textScaler: TextScaler.noScaling,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.2, color: Colors.white),
          ),
        ),
      ),
    ),
  );
}

// ───────────────────────── Social ─────────────────────────

/// A row of social icon buttons with the block's size, gap, shape and alignment. Content larger than the frame
/// isn't clipped (as on the website).
class _SocialBlock extends StatelessWidget {
  const _SocialBlock({required this.block});

  final BioSocialBlock block;

  static Widget iconFor(String platform, double size) {
    final brand = switch (platform) {
      'discord' => FontAwesomeIcons.discord,
      'youtube' => FontAwesomeIcons.youtube,
      'twitter' => FontAwesomeIcons.twitter,
      'twitch' => FontAwesomeIcons.twitch,
      'github' => FontAwesomeIcons.github,
      'instagram' => FontAwesomeIcons.instagram,
      'tiktok' => FontAwesomeIcons.tiktok,
      'steam' => FontAwesomeIcons.steam,
      _ => null,
    };
    return brand == null
        ? Icon(Icons.link, size: size, color: _BioColors.text)
        : FaIcon(brand, size: size, color: _BioColors.text);
  }

  @override
  Widget build(BuildContext context) {
    if (block.links.isEmpty) return const SizedBox.shrink();
    return OverflowBox(
      maxHeight: double.infinity,
      child: SizedBox(
        width: block.layout.w.toDouble(),
        child: Wrap(
          alignment: switch (block.align) {
            'left' => WrapAlignment.start,
            'right' => WrapAlignment.end,
            _ => WrapAlignment.center,
          },
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: block.gap.toDouble(),
          runSpacing: block.gap.toDouble(),
          children: [for (final link in block.links) _SocialButton(block: block, link: link)],
        ),
      ),
    );
  }
}

class _SocialButton extends StatefulWidget {
  const _SocialButton({required this.block, required this.link});

  final BioSocialBlock block;
  final ({String platform, String url, String? label}) link;

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final block = widget.block;
    final link = widget.link;
    final size = block.iconSize.toDouble();
    final fontSize = (size * 0.5).roundToDouble();
    final label = link.label?.trim().isNotEmpty == true ? link.label!.trim() : link.platform;
    final radius = switch (block.shape) {
      'rounded' => BorderRadius.circular(8),
      'square' => BorderRadius.zero,
      _ => BorderRadius.circular(size),
    };

    void open() => _openExternal(context, link.url);
    final highlighted = _hovered || _focused;

    return HoverTip(
      message: label,
      // Focusable like the website's links: Tab reaches it, Enter or Space opens it, and focus draws a ring.
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (hovered) => setState(() => _hovered = hovered),
        onShowFocusHighlight: (focused) => setState(() => _focused = focused),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => open()),
          ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(onInvoke: (_) => open()),
        },
        child: GestureDetector(
          onTap: open,
          child: AnimatedContainer(
            duration: Motion.fast,
            curve: Motion.standard,
            width: block.showLabels ? null : size,
            height: size,
            padding: block.showLabels ? EdgeInsets.symmetric(horizontal: fontSize * 0.85) : null,
            decoration: BoxDecoration(
              color: highlighted ? _BioColors.hover : _BioColors.surface,
              border: Border.all(color: highlighted ? _BioColors.hoverBorder : _BioColors.border),
              borderRadius: radius,
            ),
            foregroundDecoration: _focused
                ? BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.secondary,
                      width: 3,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    ),
                    borderRadius: radius,
                  )
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: fontSize * 0.5,
              children: [
                _SocialBlock.iconFor(link.platform, fontSize),
                if (block.showLabels)
                  Text(
                    label,
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(fontSize: fontSize * 0.85, fontWeight: FontWeight.w600, color: _BioColors.text),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Image ─────────────────────────

/// An image filling its frame with CSS object-fit (cover or contain) at the focal point, zoomed around it.
class _ImageBlock extends StatelessWidget {
  const _ImageBlock({required this.block});

  final BioImageBlock block;

  @override
  Widget build(BuildContext context) {
    final crop = block.crop;
    final focal = Alignment(crop.focalX / 50 - 1, crop.focalY / 50 - 1);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final decodeWidth = (max(block.layout.w, block.layout.h) * crop.zoom * dpr).ceil().clamp(64, 2048);

    final image = Transform.scale(
      scale: crop.zoom,
      alignment: focal,
      child: Image(
        image: DiskCachedImage(block.url, maxWidth: decodeWidth),
        fit: crop.contain ? BoxFit.contain : BoxFit.cover,
        alignment: focal,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (context, error, stack) => const SizedBox.shrink(),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: block.alt == null || block.alt!.isEmpty ? image : HoverTip(message: block.alt!, child: image),
    );
  }
}

// ───────────────────────── Video ─────────────────────────

/// Video player with an optional title above it. Links the app can't play become a button that opens them.
class _EmbedBlock extends StatefulWidget {
  const _EmbedBlock({required this.block});

  final BioEmbedBlock block;

  @override
  State<_EmbedBlock> createState() => _EmbedBlockState();
}

class _EmbedBlockState extends State<_EmbedBlock> {
  late bool _playable = EmbeddedVideo.canPlay(widget.block.url);

  @override
  Widget build(BuildContext context) {
    final block = widget.block;
    final title = block.title;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        if (title != null && title.isNotEmpty)
          Text(
            title,
            textScaler: TextScaler.noScaling,
            style: const TextStyle(fontSize: 14, color: _BioColors.body),
          ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ColoredBox(
              color: _BioColors.surface,
              child: _playable
                  ? EmbeddedVideo(videoLink: block.url, onUnavailable: () => setState(() => _playable = false))
                  : Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: () => _openExternal(context, block.url),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0x99090909),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Text(
                                  title != null && title.isNotEmpty ? title : l10n.openVideo,
                                  textScaler: TextScaler.noScaling,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _BioColors.text,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Featured levels / passes ─────────────────────────

/// Up to six levels or passes, fetched by id, in a list that scrolls inside the frame.
class _FeaturedBlock extends StatefulWidget {
  const _FeaturedBlock({required this.block});

  final BioFeaturedBlock block;

  @override
  State<_FeaturedBlock> createState() => _FeaturedBlockState();
}

class _FeaturedBlockState extends State<_FeaturedBlock> {
  /// Results by request, so rebuilding or reopening the profile doesn't fetch again.
  static final _cache = <String, Future<List<Object>>>{};

  Future<List<Object>>? _rows;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final block = widget.block;
    if (_rows != null || block.ids.isEmpty) return;
    final api = AppScope.of(context).api;
    final key = '${block.passes ? 'p' : 'l'}:${block.ids.join(',')}';
    _rows = _cache[key] ??= (block.passes ? api.getPassesByIds(block.ids) : api.getLevelsByIds(block.ids))
        .then<List<Object>>(
          (rows) => rows,
          onError: (Object _) {
            // Not cached, so a later visit tries again.
            _cache.remove(key);
            return const <Object>[];
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    if (rows == null) return const SizedBox.shrink();
    return FutureBuilder(
      future: rows,
      builder: (context, snapshot) {
        final items = snapshot.data;
        if (items == null) {
          return Text(
            widget.block.passes ? l10n.loadingPasses : l10n.loadingLevels,
            textScaler: TextScaler.noScaling,
            style: const TextStyle(fontSize: 14, color: _BioColors.body),
          );
        }
        return Scrollbar(
          thumbVisibility: true,
          child: ListView(
            padding: const EdgeInsets.all(2),
            children: [
              for (final item in items)
                switch (item) {
                  final Level level => _FeaturedLevel(level: level),
                  final PlayerPassEntry entry => _FeaturedPass(entry: entry),
                  _ => const SizedBox.shrink(),
                },
            ],
          ),
        );
      },
    );
  }
}

/// One featured level: difficulty icon, "#id - artist", song, length and tiles, and the creator.
class _FeaturedLevel extends StatelessWidget {
  const _FeaturedLevel({required this.level});

  final Level level;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final difficulty = app.levels.catalog?.byId(level.diffId) ?? level.difficulty;
    final length = level.length;

    return _FeaturedCard(
      onTap: () => LevelViewerPage.open(context, level),
      child: Row(
        spacing: 12,
        children: [
          NetworkIcon(difficulty?.icon, size: 48),
          Expanded(
            flex: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line(
                  ['#${level.id}', if (level.artist.isNotEmpty) level.artist].join(' - '),
                  theme.textTheme.labelSmall,
                  muted,
                ),
                _line(level.song, theme.textTheme.titleSmall, null),
                _line(
                  [
                    if (length != null) formatDuration(length),
                    if (level.tilecount case final tiles? when tiles > 0) '${formatNumber(tiles)} ${l10n.tilesUnit}',
                  ].join('  ·  '),
                  theme.textTheme.labelSmall,
                  muted,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line(l10n.creator, theme.textTheme.labelSmall, muted),
                _line(level.creatorDisplay ?? '-', theme.textTheme.bodySmall, null),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One featured pass: difficulty icon, song and player, score and accuracy.
class _FeaturedPass extends StatelessWidget {
  const _FeaturedPass({required this.entry});

  final PlayerPassEntry entry;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final level = entry.level;
    final pass = entry.pass;
    final difficulty = app.levels.catalog?.byId(level.diffId) ?? level.difficulty;

    return _FeaturedCard(
      onTap: () => PassViewerPage.open(context, level: level, pass: pass),
      child: Row(
        spacing: 12,
        children: [
          NetworkIcon(difficulty?.icon, size: 48),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _line(
                  ['#${level.id}', if (level.artist.isNotEmpty) level.artist].join(' - '),
                  theme.textTheme.labelSmall,
                  muted,
                ),
                _line(level.song, theme.textTheme.titleSmall, null),
                _line(pass.playerName, theme.textTheme.labelSmall, muted),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _line(formatScore(pass.score), theme.textTheme.titleSmall, null),
              _line(formatAccuracy(pass.accuracy), theme.textTheme.labelSmall, muted),
            ],
          ),
        ],
      ),
    );
  }
}

/// The website's featured card: a translucent dark row with a faint border.
class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Material(
      color: const Color(0x33090909),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _BioColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(12), child: child),
      ),
    ),
  );
}

Widget _line(String text, TextStyle? style, Color? color) => Text(
  text,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  textScaler: TextScaler.noScaling,
  style: color == null ? style : style?.copyWith(color: color),
);
