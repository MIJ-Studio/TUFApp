import 'package:flutter/material.dart';

import '../../app/controllers.dart';
import '../../core/l10n.dart';
import '../../core/models/pass.dart';
import 'common.dart';
import 'hover_tip.dart';
import 'level_card.dart';
import 'motion.dart';
import 'pass_badges.dart';
import 'slide_overflow.dart';
import 'video_backdrop.dart';

/// Shared layout of a pass row, used by level leaderboards, the passes list and player pages.
///
/// Same size as a level card (padding 12, inner height 72, leading column 72, gaps 16) and the same structure:
/// leading column → three lines (dim top line, title, bottom line with creator/judgements and flags at the right end)
/// → [extra] → score, accuracy and speed → video and date.
/// Score, accuracy and speed are labeled columns like on the website, in the same place on every row.
class PassRow extends StatelessWidget {
  const PassRow({
    super.key,
    required this.pass,
    required this.leading,
    required this.title,
    required this.onTap,
    this.top,
    this.bottomText,
    this.showJudgements = false,
    this.extra,
    this.impact,
    this.potentialImpact,
    this.showDate = true,
    this.videoBackdrop = true,
    this.rank,
  });

  final LevelPass pass;

  /// Leading column (difficulty icon, rank and avatar, ...), as wide as a level card's difficulty column.
  final Widget leading;

  /// Dim top line.
  final String? top;

  /// Middle line (song name, player name, ...).
  final Widget title;

  /// Dim text at the start of the bottom line (level creator, ...).
  final String? bottomText;

  /// Whether the bottom line shows the judgements before the flags (when comparing passes on one level, like
  /// leaderboards).
  final bool showJudgements;

  /// Column between the three lines and the score columns (the player on the passes list).
  final Widget? extra;

  /// Ranked score contribution (player pages).
  final double? impact;

  /// Contribution it could have made but doesn't.
  final double? potentialImpact;
  final bool showDate;

  /// Whether to show the video thumbnail as the background (off for hidden levels).
  final bool videoBackdrop;

  /// Leaderboard rank. If set, a dim card-height "#1" sits behind the left of the row, like on the website.
  final int? rank;
  final VoidCallback onTap;

  /// Same line heights as a level card (top 22, middle 26, gap 4, bottom 20 = 72).
  static const topLine = 22.0;
  static const titleLine = 26.0;
  static const gap = 4.0;
  static const bottomLine = 20.0;

  /// Widths of the number columns on the right,
  /// sized for the longest values (score "67,016.00" with its chip, "100.00%", "1.35x") so the gaps look even.
  static const scoreWidth = 108.0;
  static const accuracyWidth = 84.0;
  static const speedWidth = 52.0;
  static const tailWidth = 112.0;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final video = pass.isAutoSubmitted || !videoBackdrop ? null : pass.videoLink;
    final top = this.top;
    final flags = passFlags(pass);
    final chip = switch ((impact, potentialImpact)) {
      (final value?, _) => ImpactChip(text: '+${formatScore(value)}', positive: true),
      (null, final value?) => ImpactChip(text: '+${formatScore(value)}', positive: false),
      _ => null,
    };

    return HoverCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      background: switch ((videoBackdrop ? pass.videoLink : null, rank)) {
        (null, null) => null,
        (final link, final rank) => (context, hovered) => Stack(
          fit: StackFit.expand,
          children: [
            if (link != null) VideoBackdrop(videoLink: link, hovered: hovered),
            if (rank != null) RankWatermark(rank: rank),
          ],
        ),
      },
      child: SizedBox(
        height: LevelCard.contentHeight,
        child: Row(
          spacing: 16,
          children: [
            SizedBox(width: 72, height: LevelCard.contentHeight, child: leading),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: topLine,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: top == null || top.isEmpty
                          ? const SizedBox.shrink()
                          : SlideOverflow(
                              child: slidingText(top, style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
                            ),
                    ),
                  ),
                  SizedBox(
                    height: titleLine,
                    child: Align(alignment: Alignment.centerLeft, child: title),
                  ),
                  const SizedBox(height: gap),
                  SizedBox(
                    height: bottomLine,
                    // Like a level card's tag line: creator and judgements scroll when they overflow on the left,
                    // and flag chips stick to the right end like time/tiles/BPM.
                    child: LayoutBuilder(
                      builder: (context, constraints) => Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: SlideOverflow(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 6,
                                  children: [
                                    if (bottomText case final text? when text.isNotEmpty)
                                      Text(text, style: theme.textTheme.labelMedium?.copyWith(color: muted)),
                                    if (showJudgements) JudgementStrip(pass: pass),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (flags.isNotEmpty) ...[
                            const SizedBox(width: 16),
                            // In narrow windows, use at most 60% of the line and scroll on overflow.
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.6),
                              child: SlideOverflow(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 6,
                                  children: [
                                    for (final flag in flags)
                                      PassFlagChip(label: flag.label, tip: flag.tip, compact: true),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ?extra,
            SizedBox(
              width: scoreWidth,
              child: _Labeled(
                label: l10n.score,
                value: Text(
                  formatScore(pass.score),
                  maxLines: 1,
                  softWrap: false,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                // On rows with a chip only the score column moves up; accuracy and speed stay aligned with other rows.
                below: chip,
              ),
            ),
            SizedBox(
              width: accuracyWidth,
              child: _Labeled(
                label: l10n.accuracy,
                value: _Accuracy(pass: pass),
              ),
            ),
            SizedBox(
              width: speedWidth,
              child: _Labeled(
                label: l10n.speedMultiplier,
                value: Text('${formatSpeed(pass.speed)}x', style: theme.textTheme.titleMedium),
              ),
            ),
            // Where a level card has its download column: the video button vertically
            // centered like on level cards, the date in the bottom right corner.
            // Both have fixed places, so nothing else moves when there is no video or the date is short.
            SizedBox(
              width: tailWidth,
              height: LevelCard.contentHeight,
              child: Stack(
                children: [
                  if (video != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: HoverTip(
                        message: l10n.watchVideo,
                        child: IconButton(
                          onPressed: () => app.openLink(video),
                          icon: const Icon(Icons.smart_display_outlined),
                        ),
                      ),
                    ),
                  if (showDate && pass.clearedAt != null)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Text(
                        formatDate(pass.clearedAt),
                        maxLines: 1,
                        softWrap: false,
                        style: theme.textTheme.labelSmall?.copyWith(color: muted),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A value with a small label above it (the website's "Score / Accuracy / Speed").
class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.value, this.below});

  final String label;
  final Widget value;

  /// Widget below the value (the score's contribution chip). If set, only this column moves up.
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final raised = below != null;
    // A score with a chip below can exceed the row height (72), so it shrinks slightly only when it overflows.
    return SizedBox(
      height: LevelCard.contentHeight,
      child: Align(
        alignment: raised ? Alignment.topLeft : Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(top: raised ? 4 : 0),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                value,
                if (below case final widget?) Padding(padding: const EdgeInsets.only(top: 2), child: widget),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Accuracy. Perfect passes glow, like on the pass page.
class _Accuracy extends StatelessWidget {
  const _Accuracy({required this.pass});

  final LevelPass pass;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = pass.isPureXPerfect
        ? JudgementColors.platinum
        : pass.isPurePerfect
        ? JudgementColors.perfect
        : null;
    return Text(
      formatAccuracy(pass.accuracy),
      maxLines: 1,
      softWrap: false,
      style: theme.textTheme.titleMedium?.copyWith(
        color: color,
        fontWeight: color == null ? null : FontWeight.w700,
        shadows: color == null ? null : [Shadow(color: color, blurRadius: 8)],
      ),
    );
  }
}

/// Judgement counts in one strip (same order and colors as the website).
/// X-Perfect passes get nine cells including Perfect−/Perfect+, with the center Perfect in white.
class JudgementStrip extends StatelessWidget {
  const JudgementStrip({super.key, required this.pass});

  final LevelPass pass;

  @override
  Widget build(BuildContext context) {
    final judgements = pass.judgements;
    if (judgements == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final xPerfect = pass.showsXPerfect;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          for (final (judgement, value) in judgements.ordered(xPerfect: xPerfect))
            HoverTip(
              message: '${judgement.label}: ${formatNumber(value)}',
              child: Text(
                formatNumber(value),
                maxLines: 1,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: JudgementColors.of(judgement, xPerfect: xPerfect),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Difficulty icon column (player pages and the passes list). Hidden levels show a lock.
class PassDifficultyIcon extends StatelessWidget {
  const PassDifficultyIcon({super.key, required this.icon, this.hidden = false});

  final String? icon;
  final bool hidden;

  @override
  Widget build(BuildContext context) => Center(
    child: hidden
        ? Icon(Icons.lock_outline, size: 32, color: Theme.of(context).colorScheme.onSurfaceVariant)
        : NetworkIcon(icon, size: 48),
  );
}

/// Card-height rank ("#1") behind the left of the row, like the website's leaderboard rows.
/// It is a background, so it doesn't affect layout. 1st–3rd are gold, silver and red (same colors as the website).
class RankWatermark extends StatelessWidget {
  const RankWatermark({super.key, required this.rank});

  final int rank;

  static Color colorOf(int rank, Color fallback) => switch (rank) {
    1 => const Color(0xFFFFD700),
    2 => const Color(0xFFC0C0C0),
    3 => const Color(0xFFFF6666),
    _ => fallback,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medal = rank >= 1 && rank <= 3;
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '#$rank',
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              fontSize: 88,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -2,
              color: colorOf(rank, theme.colorScheme.onSurface).withValues(alpha: medal ? 0.22 : 0.1),
            ),
          ),
        ),
      ),
    );
  }
}
