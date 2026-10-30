import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/controllers.dart';
import '../../core/l10n.dart';
import '../../core/level_downloader.dart';
import '../../core/models/difficulty.dart';
import '../../core/models/facet.dart';
import '../../core/models/level.dart';
import '../../core/models/search_models.dart';
import '../pages/level_viewer_page.dart';
import '../theme.dart';
import 'common.dart';
import 'hover_tip.dart';
import 'labels.dart';
import 'motion.dart';
import 'raster_snapshot.dart';
import 'slide_overflow.dart';
import 'video_backdrop.dart';

/// One card in the levels list.
class LevelCard extends StatelessWidget {
  const LevelCard({super.key, required this.level, required this.compact, this.openable = true, this.embedded = false});

  final Level level;
  final bool compact;

  /// Tapping opens the level details. Off for the card inside the details page.
  final bool openable;

  /// For narrow places inside other content (a profile's bio): the same card without the clears and likes,
  /// links and download columns.
  final bool embedded;

  /// Gap between columns.
  static const _columnGap = 16.0;
  static const _creatorWidth = 176.0;
  static const _statsWidth = 104.0;

  bool get _hasStats => !embedded && (level.clears > 0 || level.likes > 0);

  /// Inner card height. Every card keeps the same size regardless of content.
  static const contentHeight = 72.0;
  static const compactContentHeight = 40.0;

  @override
  Widget build(BuildContext context) => HoverCard(
    onTap: openable ? () => LevelViewerPage.open(context, level) : null,
    padding: compact ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6) : const EdgeInsets.all(12),
    background: switch (level.videoLink) {
      final link? => (context, hovered) => VideoBackdrop(videoLink: link, hovered: hovered),
      null => null,
    },
    child: SizedBox(
      height: compact ? compactContentHeight : contentHeight,
      // All column gaps are equal.
      child: Row(
        spacing: _columnGap,
        children: [
          _DifficultyIcon(level: level, compact: compact),
          // Time, tiles and BPM only sit on the tag line, so the title and artist lines extend over that space.
          Expanded(
            child: _SongInfo(level: level, compact: compact),
          ),
          SizedBox(
            width: embedded ? _creatorWidth : _creatorWidth + _columnGap + _statsWidth,
            child: Stack(
              children: [
                // If the clears and likes columns are empty, the creator takes their space.
                // It only scrolls sideways if it still overflows.
                SizedBox(
                  width: _hasStats || embedded ? _creatorWidth : _creatorWidth + _columnGap + _statsWidth,
                  height: double.infinity,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _CreatorInfo(level: level, compact: compact),
                  ),
                ),
                if (_hasStats)
                  Positioned(
                    left: _creatorWidth + _columnGap,
                    top: 0,
                    bottom: 0,
                    width: _statsWidth,
                    child: _Stats(level: level),
                  ),
              ],
            ),
          ),
          if (!embedded) ...[
            SizedBox(width: 88, child: _Links(level: level)),
            SizedBox(
              width: 132,
              // Like the website, the download count goes under the download
              // button (left out in compact view for lack of space).
              // The button always stays vertically centered and the count is attached below it,
              // so the button doesn't move whether or not there is a count.
              child: compact || !(level.downloadCount > 0 || LevelDownloader.isTufCdnLink(level.dlLink))
                  ? Center(child: _InstallButton(level: level))
                  : SizedBox(
                      height: contentHeight,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          _InstallButton(level: level),
                          Positioned(
                            left: 0,
                            right: 0,
                            // 4 below the button (40). It may reach slightly into the card's bottom padding.
                            top: contentHeight / 2 + 20 + 4,
                            child: Center(child: _DownloadInfo(level: level)),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Angles (degrees) of the curation icons; 0° is right, 90° is down.
/// Same formula as the website: spread by 90/count around 45°.
@visibleForTesting
List<double> curationArcAngles(int count) {
  const arcCenter = 45.0;
  if (count <= 0) return const [];
  final offset = 90.0 / count;
  return [for (var i = 0; i < count; i++) arcCenter + i * offset - (count - 1) * offset / 2];
}

/// Difficulty icon. Levels with a base score different from the difficulty's default show it above the icon.
class _DifficultyIcon extends StatelessWidget {
  const _DifficultyIcon({required this.level, required this.compact});

  final Level level;
  final bool compact;

  @override
  Widget build(BuildContext context) => SizedBox(
    // Equal column widths keep titles aligned across cards.
    // Curation icons stick out of the circle, so the column is wider than the difficulty icon.
    width: compact ? 56 : 72,
    child: Center(
      child: _CuratedDifficultyIcon(
        level: level,
        size: compact ? 32 : 48,
        compact: compact,
        // Compact view has no room above the icon, so it goes on the artist line instead.
        baseScore: compact ? null : level.baseScoreOverride,
      ),
    ),
  );
}

/// Shadow around the icon like the website (.img-wrapper drop-shadow 0 0 3px black).
/// A round shadow per icon is cheaper than blurring the whole group again (lists hold dozens of these).
class _Shadowed extends StatelessWidget {
  const _Shadowed({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: Color(0xCC000000), blurRadius: 3)],
    ),
    child: child,
  );
}

/// Difficulty icon ringed with curation icons (C2, V1, ...).
class _CuratedDifficultyIcon extends StatelessWidget {
  const _CuratedDifficultyIcon({required this.level, required this.size, required this.compact, this.baseScore});

  /// Maximum icons around one difficulty icon.
  static const _maxIcons = 4;

  /// These values match the website (levelcard.css .curation-icon).
  /// Detailed: difficulty 3rem (48px), icon 1.25rem (20px), radius 1.65rem (26.4px).
  /// Compact: difficulty 2rem (32px), icon 1.1rem (17.6px), radius 1.65rem×0.7 (18.48px).
  /// The radius exceeds the difficulty circle's (24, 16), so the icons sit just outside it.
  static const _curationScale = 20 / 48;
  static const _radiusScale = 26.4 / 48;
  static const _compactCurationScale = 17.6 / 32;
  static const _compactRadiusScale = 18.48 / 32;

  /// Website (levelcard.css .rating-icon): 1.5rem on a 3rem difficulty, offset -11% up and left.
  static const _ratingScale = 0.5;
  static const _ratingOffsetScale = -0.11;

  final Level level;
  final double size;
  final bool compact;

  /// Base score replacing the difficulty's default, drawn over the icon if set.
  final int? baseScore;

  /// Same condition as the website: the difficulty name contains Q and the rating is a PGU difficulty.
  Difficulty? _ratedDifficulty(DifficultyCatalog? catalog) {
    if (!(level.difficulty?.name.contains('Q') ?? false)) return null;
    final rated = catalog?.byId(level.ratedDifficultyId);
    return rated?.type == 'PGU' && rated?.icon != null ? rated : null;
  }

  @override
  Widget build(BuildContext context) {
    final levels = AppScope.of(context).levels;
    final catalog = levels.curationCatalog;
    final rated = _ratedDifficulty(levels.catalog);
    final curations = catalog == null || level.curationTypeIds.isEmpty
        ? const <FacetItem>[]
        : catalog
              .resolve(level.curationTypeIds)
              .where((curation) => !isHiddenCurationArcType(curation))
              .take(_maxIcons)
              .toList();

    // The difficulty icon keeps its size with or without curations.
    final difficulty = HoverTip(
      message: level.difficulty?.name ?? '#${level.diffId}',
      child: _Shadowed(child: NetworkIcon(level.difficulty?.icon, size: size)),
    );
    final baseScore = this.baseScore;
    if (curations.isEmpty && rated == null && baseScore == null) {
      return SizedBox.square(
        dimension: size,
        child: Center(child: difficulty),
      );
    }

    final iconSize = size * (compact ? _compactCurationScale : _curationScale);
    final radius = size * (compact ? _compactRadiusScale : _radiusScale);
    final angles = curationArcAngles(curations.length);

    return SizedBox.square(
      dimension: size,
      child: Stack(
        // Curation icons stick slightly out of the difficulty circle (the column has room).
        clipBehavior: Clip.none,
        children: [
          Center(child: difficulty),
          // For Q levels, the rated PGU difficulty overlaps the top left (website .rating-icon).
          if (rated != null)
            Positioned(
              left: size * _ratingOffsetScale,
              top: size * _ratingOffsetScale,
              width: size * _ratingScale,
              height: size * _ratingScale,
              child: HoverTip(
                message: l10n.expectedDifficulty(rated.name),
                child: _Shadowed(child: NetworkIcon(rated.icon, size: size * _ratingScale)),
              ),
            ),
          for (final (index, curation) in curations.indexed)
            _positioned(
              angle: angles[index],
              radius: radius,
              iconSize: iconSize,
              child: HoverTip(
                message: l10n.curation(curation.name),
                child: _Shadowed(child: NetworkIcon(curation.icon, size: iconSize)),
              ),
            ),
          // Like the website (.base-score-wrapper), only text centered above the icon, raised by 85% of its height.
          if (baseScore != null)
            Positioned(
              left: -size,
              right: -size,
              top: 0,
              child: FractionalTranslation(
                translation: const Offset(0, -0.85),
                child: Center(child: _BaseScoreBadge(score: baseScore)),
              ),
            ),
        ],
      ),
    );
  }

  /// Places [child] at [angle] degrees and [radius] from the center; 0° is right, 90° is down.
  Widget _positioned({required double angle, required double radius, required double iconSize, required Widget child}) {
    final radians = angle * pi / 180;
    return Positioned(
      left: size / 2 + radius * cos(radians) - iconSize / 2,
      top: size / 2 + radius * sin(radians) - iconSize / 2,
      width: iconSize,
      height: iconSize,
      child: child,
    );
  }
}

/// Base score (PP) set for this level instead of the difficulty's default.
class _BaseScoreBadge extends StatelessWidget {
  const _BaseScoreBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Same look as the website: 10px, weight 600, opacity 0.9, 10px black shadow.
    return HoverTip(
      message: l10n.baseScoreOverridePP(score),
      child: Text(
        '$score PP',
        maxLines: 1,
        softWrap: false,
        // Fixed size so a large text scale doesn't cover the icon.
        textScaler: TextScaler.noScaling,
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.white.withValues(alpha: 0.9),
          fontWeight: FontWeight.w600,
          fontSize: 10,
          height: 1.2,
          shadows: const [
            Shadow(color: Colors.black, blurRadius: 10),
            Shadow(color: Colors.black, blurRadius: 4),
          ],
        ),
      ),
    );
  }
}

class _SongInfo extends StatelessWidget {
  const _SongInfo({required this.level, required this.compact});

  /// Fixed line heights keep titles and tags in the same place on every card.
  static const titleLine = 26.0;
  static const subtitleLine = 22.0;
  static const tagLine = 20.0;

  /// Gap between the artist line and the tag line; tag icons are taller than text, so they'd look cramped otherwise.
  static const tagGap = 4.0;

  /// The two lines of compact view, one text line (20) each.
  static const compactLine = 20.0;

  final Level level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Same order as the website: "#id - artist" on top, song below.
    final subtitle = [
      ['#${level.id}', if (level.artist.isNotEmpty) level.artist].join(' - '),
      // Compact view has no room for the badge, so it goes here.
      if (compact && level.baseScoreOverride != null) '${level.baseScoreOverride} PP',
    ].join('  ·  ');

    final title = SlideOverflow(
      child: slidingText(level.song, style: compact ? theme.textTheme.titleSmall : theme.textTheme.titleMedium),
    );
    final subtitleText = SlideOverflow(
      child: slidingText(
        subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: compactLine, child: subtitleText),
          Row(
            children: [
              // The song name takes the free space first; tags and time/tiles/BPM stick to the right.
              Expanded(
                child: SizedBox(height: compactLine, child: title),
              ),
              if (level.tags.isNotEmpty) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  height: tagLine,
                  child: _Tags(tags: level.tags),
                ),
              ],
              const SizedBox(width: 16),
              _Meta(level: level),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: subtitleLine,
          child: Align(alignment: Alignment.centerLeft, child: subtitleText),
        ),
        SizedBox(
          height: titleLine,
          child: Align(alignment: Alignment.centerLeft, child: title),
        ),
        const SizedBox(height: tagGap),
        SizedBox(
          height: tagLine,
          // In narrow cards (inside a bio) the values shrink to the line instead of overflowing it.
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                Expanded(child: level.tags.isEmpty ? const SizedBox.shrink() : _Tags(tags: level.tags)),
                const SizedBox(width: 16),
                _Meta(level: level, maxWidth: min(_Meta.defaultMaxWidth, constraints.maxWidth - 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Time, tile count and BPM, right-aligned on the tag line with equal gaps.
/// Widths follow the values, so long ones like "486.06 BPM" aren't cut off.
class _Meta extends StatelessWidget {
  const _Meta({required this.level, this.maxWidth = defaultMaxWidth});

  /// Same gap as between flag chips.
  static const _gap = 6.0;

  /// Maximum width; values are only shrunk when very long ones would overlap.
  static const defaultMaxWidth = 260.0;

  final Level level;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final length = level.length;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: max(0, maxWidth)),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MetaValue(
              icon: Icons.schedule,
              text: length == null ? null : formatDuration(length),
              tooltip: l10n.length,
            ),
            const SizedBox(width: _gap),
            _MetaValue(
              icon: Icons.linear_scale,
              text: level.tilecount == null ? null : formatNumber(level.tilecount!),
              tooltip: l10n.tileCount,
            ),
            const SizedBox(width: _gap),
            _MetaValue(
              icon: Icons.music_note_outlined,
              text: level.bpm == null ? null : '${formatBpm(level.bpm!)} BPM',
              tooltip: 'BPM',
            ),
          ],
        ),
      ),
    );
  }
}

/// Level tag icons. On overflow they slide sideways like the title and creator.
class _Tags extends StatelessWidget {
  const _Tags({required this.tags});

  final List<LevelTag> tags;

  // Ringed tag icons are expensive to draw, so bake them into one image and draw only that while scrolling.
  @override
  Widget build(BuildContext context) => RasterSnapshot(
    child: SlideOverflow(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final tag in tags)
            // Each tag reserves room for its ring (1 on each side), so a gap of 2 keeps the visible spacing at 4.
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: _TagBadge(tag: tag),
            ),
        ],
      ),
    ),
  );
}

class _TagBadge extends StatelessWidget {
  const _TagBadge({required this.tag});

  static const size = 18.0;

  final LevelTag tag;

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(tag.color) ?? Theme.of(context).colorScheme.onSurfaceVariant;
    final Widget badge = tag.icon != null
        ? NetworkIcon(tag.icon, size: size)
        : CircleAvatar(
            radius: size / 2,
            backgroundColor: color.withValues(alpha: 0.3),
            child: Text(
              tag.name.isEmpty ? '?' : tag.name.substring(0, 1).toUpperCase(),
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
            ),
          );
    final score = tag.isCommunity ? (tag.score ?? 0).clamp(0.0, 1.0) : null;
    // Like the website (communityTagHoverTitle), community tags also show their confidence.
    final message = [
      tag.name,
      if (tag.description case final text? when text.trim().isNotEmpty) text.trim(),
      if (score != null) '${(score * 100).round()}%',
    ].join(' — ');
    // Every tag reserves the ring space, so rings aren't clipped by the row and tag spacing looks even.
    return HoverTip(
      message: message,
      child: score == null
          ? Padding(padding: const EdgeInsets.all(TagConfidenceOutline.stroke), child: badge)
          : TagConfidenceOutline(score: score, size: size, iconUrl: tag.icon, child: badge),
    );
  }
}

/// Confidence ring of a community tag (the website's TagConfidenceBar).
///
/// The website draws a rounded rectangle around the tag, which doesn't match the icon shape. Here a green ring
/// [stroke] wide follows the icon's own outline and is filled up to the confidence. The fill direction matches
/// the website: it ends at the bottom right (135° clockwise) and extends counterclockwise by the confidence.
///
/// The ring is the icon image tinted green and drawn [_copies] times, each nudged outward, then clipped to
/// a sector for the confidence. Each copy is drawn smoothly, so the ring edge is smooth and round too.
/// It paints straight to the canvas without blend layers, so it is cheap and survives when the list bakes
/// this row into one image. Tags without an icon (a letter circle) get an arc around the circle.
/// The widget's size includes the ring ([size] + 2×[stroke]), so it isn't clipped by the row.
class TagConfidenceOutline extends StatefulWidget {
  const TagConfidenceOutline({super.key, required this.score, required this.size, required this.child, this.iconUrl});

  /// 0–1.
  final double score;

  /// Icon size (the size of [child]).
  final double size;

  /// Icon whose outline the ring follows. Without one, the ring goes around a circle.
  final String? iconUrl;
  final Widget child;

  /// Ring width.
  static const stroke = 1.0;

  /// Same color as the website (#0f0).
  static const color = Color(0xFF00FF00);

  @override
  State<TagConfidenceOutline> createState() => _TagConfidenceOutlineState();
}

class _TagConfidenceOutlineState extends State<TagConfidenceOutline> {
  ImageStream? _stream;
  ImageInfo? _image;
  late final _listener = ImageStreamListener((info, _) {
    if (!mounted) return;
    setState(() {
      _image?.dispose();
      _image = info;
    });
  }, onError: (_, _) {});

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(TagConfidenceOutline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.iconUrl != widget.iconUrl || oldWidget.size != widget.size) _resolve();
  }

  /// Loads the same image the icon uses (same cache entry) to take the ring shape from.
  void _resolve() {
    final url = widget.iconUrl;
    final stream = url == null
        ? null
        : NetworkIcon.provider(context, url, widget.size).resolve(createLocalImageConfiguration(context));
    if (stream?.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _stream = stream?..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const stroke = TagConfidenceOutline.stroke;
    final box = widget.size + stroke * 2;
    return SizedBox.square(
      dimension: box,
      child: CustomPaint(
        painter: widget.score <= 0
            ? null
            : _ConfidenceRingPainter(
                score: widget.score.clamp(0.0, 1.0),
                image: widget.iconUrl == null ? null : _image?.image,
                circle: widget.iconUrl == null,
              ),
        child: Padding(padding: const EdgeInsets.all(stroke), child: widget.child),
      ),
    );
  }
}

class _ConfidenceRingPainter extends CustomPainter {
  _ConfidenceRingPainter({required this.score, required this.image, required this.circle});

  final double score;
  final ui.Image? image;
  final bool circle;

  static const _copies = 8;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = TagConfidenceOutline.stroke;
    const color = TagConfidenceOutline.color;
    final center = size.center(Offset.zero);
    // The website's conic-gradient measures clockwise from 12 o'clock; canvas angles start at 3 o'clock.
    // Website: from (135° - score×360°) to 135° → canvas: starting at (45° - score×360°).
    final start = (45 - score * 360) * pi / 180;
    final sweep = score * 2 * pi;

    if (circle) {
      // Arc around the letter circle.
      final radius = size.shortestSide / 2 - stroke / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..isAntiAlias = true,
      );
      return;
    }

    final image = this.image;
    if (image == null) return;

    canvas.save();
    if (score < 1) {
      // Keep only the sector for the confidence, with a radius large enough to cover the box.
      final reach = size.longestSide;
      canvas.clipPath(
        Path()
          ..moveTo(center.dx, center.dy)
          ..arcTo(Rect.fromCircle(center: center, radius: reach), start, sweep, false)
          ..close(),
      );
    }
    final inner = size.width - stroke * 2;
    final source = Offset.zero & Size(image.width.toDouble(), image.height.toDouble());
    final paint = Paint()
      ..colorFilter = const ColorFilter.mode(color, BlendMode.srcIn)
      ..filterQuality = FilterQuality.medium
      ..isAntiAlias = true;
    for (var i = 0; i < _copies; i++) {
      final angle = 2 * pi * i / _copies;
      final topLeft = Offset(stroke + stroke * cos(angle), stroke + stroke * sin(angle));
      // Draw where the icon itself sits (aspect-preserving and centered, like BoxFit.contain).
      final fitted = applyBoxFit(BoxFit.contain, source.size, Size.square(inner));
      final dst = Alignment.center.inscribe(fitted.destination, topLeft & Size.square(inner));
      canvas.drawImageRect(image, source, dst, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ConfidenceRingPainter old) => old.score != score || old.image != image || old.circle != circle;
}

/// One time/tiles/BPM value in a chip, like the website. A '-' holds the place when missing.
class _MetaValue extends StatelessWidget {
  const _MetaValue({required this.icon, required this.text, required this.tooltip});

  final IconData icon;
  final String? text;
  final String tooltip;

  @override
  Widget build(BuildContext context) => InfoChip(icon: icon, label: text ?? '-', tip: tooltip);
}

class _CreatorInfo extends StatelessWidget {
  const _CreatorInfo({required this.level, required this.compact});

  final Level level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final creator = level.creatorDisplay ?? l10n.noCreatorInfo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact)
          Text(l10n.creator, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        SizedBox(
          height: 20,
          child: HoverTip(
            message: creator,
            child: SlideOverflow(child: slidingText(creator, style: theme.textTheme.bodyMedium)),
          ),
        ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.level});

  final Level level;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    // Big counts shrink to the column instead of overflowing it.
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          // Without clears, hide but keep the space (keeps columns aligned).
          Opacity(
            opacity: level.clears > 0 ? 1 : 0,
            child: InfoChip(
              icon: Icons.flag_outlined,
              label: formatNumber(level.uniqueClears),
              tip: l10n.clearedByPlayerTotal(level.uniqueClears, level.clears),
            ),
          ),
          if (level.likes > 0) InfoChip(icon: Icons.favorite_border, label: formatNumber(level.likes), tip: l10n.likes),
        ],
      ),
    ),
  );
}

class _Links extends StatelessWidget {
  const _Links({required this.level});

  final Level level;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final video = level.videoLink;
    final workshop = level.workshopLink;

    // Fixed slots: the video button stays put even without a Workshop link.
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox.square(
          dimension: 44,
          child: video == null
              ? null
              : HoverTip(
                  message: l10n.watchVideo,
                  child: IconButton(
                    onPressed: () => app.openLink(video),
                    icon: const Icon(Icons.smart_display_outlined),
                  ),
                ),
        ),
        SizedBox.square(
          dimension: 44,
          child: workshop == null
              ? null
              : HoverTip(
                  message: l10n.steamWorkshop,
                  child: IconButton(
                    onPressed: () => app.openLink(workshop),
                    icon: const Icon(Icons.sports_esports_outlined),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Small line under the download button: download count on the website and zip size.
/// The size isn't in list responses, so it is asked separately when the card shows; only the count shows meanwhile.
class _DownloadInfo extends StatelessWidget {
  const _DownloadInfo({required this.level});

  final Level level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final style = theme.textTheme.labelSmall?.copyWith(color: muted);
    final sizes = AppScope.of(context).levelSizes;
    final count = level.downloadCount;

    return FutureBuilder<int?>(
      // Known sizes don't wait; only unknown CDN levels are asked.
      future: LevelDownloader.isTufCdnLink(level.dlLink) ? sizes.resolve(level) : null,
      initialData: sizes.peek(level),
      builder: (context, snapshot) {
        final size = snapshot.data;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (count > 0)
              HoverTip(
                message: l10n.downloads,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download_outlined, size: 14, color: muted),
                    const SizedBox(width: 3),
                    Text(formatNumber(count), style: style),
                  ],
                ),
              ),
            if (count > 0 && size != null) Text('  ·  ', style: style),
            if (size != null)
              HoverTip(
                message: l10n.levelFileSize,
                child: Text(formatBytes(size), style: style),
              ),
          ],
        );
      },
    );
  }
}

class _InstallButton extends StatelessWidget {
  const _InstallButton({required this.level});

  final Level level;

  @override
  Widget build(BuildContext context) {
    final installs = AppScope.of(context).installs;

    return ListenableBuilder(
      listenable: installs,
      builder: (context, _) {
        final job = installs.jobFor(level.id);
        final state = installs.stateOf(level);

        // Cross-fades through download → progress → downloaded.
        return FadeSwitcher(
          scale: true,
          child: KeyedSubtree(
            key: ValueKey(job != null ? 'job' : state),
            child: job != null ? JobProgressIndicator(job: job) : _buttonFor(installs, state),
          ),
        );
      },
    );
  }

  Widget _buttonFor(InstallCenter installs, LevelInstallState state) {
    return switch (state) {
      LevelInstallState.notInstalled => HoverTip(
        message: l10n.downloadToLibrary,
        child: FilledButton.icon(
          onPressed: () => installs.install(level),
          icon: const Icon(Icons.download),
          label: Text(l10n.download),
        ),
      ),
      LevelInstallState.updateAvailable => HoverTip(
        message: l10n.updateToTheNew,
        child: FilledButton.tonalIcon(
          onPressed: () => installs.install(level),
          icon: const Icon(Icons.update),
          label: Text(l10n.update),
        ),
      ),
      LevelInstallState.installed => HoverTip(
        message: l10n.alreadyDownloaded,
        child: OutlinedButton.icon(onPressed: null, icon: const Icon(Icons.check), label: Text(l10n.downloaded)),
      ),
      LevelInstallState.notDownloadable => HoverTip(
        message: l10n.noFileToDownload,
        child: TextButton(onPressed: null, child: Text(l10n.noLink)),
      ),
    };
  }
}
