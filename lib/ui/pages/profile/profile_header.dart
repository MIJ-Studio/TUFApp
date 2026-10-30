import 'package:flutter/material.dart';

import '../../../core/image_cache_store.dart';
import '../../../core/l10n.dart';
import '../../../core/models/difficulty.dart';
import '../../../core/models/facet.dart';
import '../../../core/models/pass.dart';
import '../../../core/profile_stats.dart';
import '../../widgets/common.dart';
import '../../widgets/hover_tip.dart';
import '../../widgets/labels.dart';
import '../../widgets/motion.dart';
import '../../widgets/slide_overflow.dart';
import '../../widgets/smooth_scroll.dart';
import 'profile_section.dart';

/// Top card of player and creator pages, a larger version of the person card on the passes page:
/// avatar, name and account, icon slots (top difficulties / curation types), rank, three stats and "All stats".
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    required this.avatar,
    this.aliases = const [],
    this.bannerUrl,
    this.handle,
    this.country,
    this.rank,
    this.highestRank,
    this.profileId,
    this.followerCount,
    this.badge,
    this.iconSlots = const [],
    this.iconPanelTitle,
    this.iconPanel,
    this.stats = const [],
    this.statGroups = const [],
    this.onOpenPass,
    this.actions = const [],
  });

  final String name;
  final AvatarUrls avatar;

  /// Former names, shown when hovering the name.
  final List<String> aliases;

  /// Profile banner, blurred behind the card if present (like video thumbnails on level cards).
  final String? bannerUrl;
  final String? handle;
  final String? country;

  /// Player rank. null hides the rank chip (creators).
  final int? rank;
  final ({int rank, DateTime date})? highestRank;
  final int? profileId;
  final int? followerCount;

  /// Badge next to the name (creator verification status).
  final Widget? badge;
  final List<IconSlot> iconSlots;

  /// Title of the dialog opened from the end of the icon row (all difficulties / all curation types).
  final String? iconPanelTitle;
  final WidgetBuilder? iconPanel;

  /// Key stats shown at the bottom of the card.
  final List<StatRow> stats;

  /// Contents of the "All stats" dialog.
  final List<StatGroup> statGroups;
  final void Function(int passId)? onOpenPass;

  /// Buttons at the top right (other profile, view packs, ...).
  final List<ProfileAction> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final rank = this.rank;
    final banner = bannerUrl;
    final panel = iconPanel;
    final subtitle = [
      if (handle case final h?) '@$h',
      if (followerCount case final count?) l10n.followerCount(count),
      if (profileId case final id?) 'ID $id',
    ].join('  ·  ');

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (banner != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.25,
                child: Image(
                  image: DiskCachedImage(banner, maxWidth: 192, blurSigma: 1.5),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (context, error, stack) => const SizedBox.shrink(),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProfileAvatar(avatar: avatar, size: 88),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: HoverTip(
                                  message: aliases.isEmpty ? '' : l10n.alsoKnownAs(aliases.join(', ')),
                                  child: SlideOverflow(child: slidingText(name, style: theme.textTheme.headlineSmall)),
                                ),
                              ),
                              if (country != null) ...[
                                const SizedBox(width: 10),
                                CountryFlag(country: country, height: 18),
                              ],
                              if (badge case final b?) ...[const SizedBox(width: 10), b],
                            ],
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
                          ],
                          if (iconSlots.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                for (final slot in iconSlots) ...[IconSlotView(slot: slot), const SizedBox(width: 8)],
                                if (panel != null)
                                  IconButton(
                                    tooltip: iconPanelTitle ?? l10n.showAll,
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => showDialog<void>(
                                      context: context,
                                      builder: (context) =>
                                          _PanelDialog(title: iconPanelTitle ?? '', child: panel(context)),
                                    ),
                                    icon: const Icon(Icons.grid_view_rounded),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (rank != null) _RankChip(rank: rank, highest: highestRank),
                        if (actions.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final (index, action) in actions.indexed) ...[
                                if (index > 0) const SizedBox(width: 8),
                                IconButton.filledTonal(
                                  tooltip: action.tooltip,
                                  onPressed: action.onPressed,
                                  icon: Icon(action.icon),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                if (stats.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (final stat in stats) ...[
                        Expanded(
                          child: ProfileTile(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(stat.label, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                                const SizedBox(height: 2),
                                Text(stat.value, style: theme.textTheme.titleMedium),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (statGroups.isNotEmpty)
                        FilledButton.tonalIcon(
                          onPressed: () =>
                              ProfileStatsDialog.show(context, title: name, groups: statGroups, onOpenPass: onOpenPass),
                          icon: const Icon(Icons.query_stats),
                          label: Text(l10n.allStats),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One button at the top right of the header.
class ProfileAction {
  const ProfileAction({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
}

/// Rank colors: gold, silver and bronze for 1–3, otherwise null (default text color).
Color? medalColor(int rank) => switch (rank) {
  1 => const Color(0xFFF2D06B),
  2 => const Color(0xFFDADADA),
  3 => const Color(0xFFF4A259),
  _ => null,
};

/// "#1" rank chip (same look as on the passes page). Medal colors for 1–3; hovering shows the highest rank.
class _RankChip extends StatelessWidget {
  const _RankChip({required this.rank, this.highest});

  final int rank;
  final ({int rank, DateTime date})? highest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final best = highest;
    final tip = best == null
        ? l10n.rankedScoreRank
        : rank > 0 && rank <= best.rank
        ? l10n.atHighestRankRight
        : l10n.highestRank(best.rank, formatDate(best.date));
    return HoverTip(
      message: tip,
      child: ValueBox(
        child: Text(
          rank > 0 ? '#${formatNumber(rank)}' : l10n.unranked,
          style: theme.textTheme.titleLarge?.copyWith(
            color: medalColor(rank) ?? theme.colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Round avatar. Falls back to the Discord picture if the TUF upload fails, then to a person icon.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.avatar, required this.size});

  final AvatarUrls avatar;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final url = avatar.primary ?? avatar.fallback;
    final placeholder = Icon(Icons.person, size: size * 0.6, color: colors.onSurfaceVariant);
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(shape: BoxShape.circle, color: colors.surfaceContainerHighest),
      child: url == null
          ? placeholder
          : Image(
              image: DiskCachedImage(url, maxWidth: (size * 2).ceil()),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
              errorBuilder: (context, error, stack) => switch (avatar.fallback) {
                final fallback? when fallback != url => Image(
                  image: DiskCachedImage(fallback, maxWidth: (size * 2).ceil()),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => placeholder,
                ),
                _ => placeholder,
              },
            ),
    );
  }
}

/// One slot icon with its count (small number at the bottom right).
class IconSlotView extends StatelessWidget {
  const IconSlotView({super.key, required this.slot, this.size = 40});

  final IconSlot slot;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = slot.iconUrl;
    return HoverTip(
      message: slot.tooltip ?? '',
      child: SizedBox(
        width: size + 4,
        height: size + 4,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox.square(
              dimension: size,
              child: icon != null
                  ? NetworkIcon(icon, size: size)
                  : Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        slot.letter,
                        style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${slot.badge}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog opened from the icon row button.
class _PanelDialog extends StatelessWidget {
  const _PanelDialog({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title),
    content: child,
    actions: [FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close))],
  );
}

/// "All stats" dialog, shaped like the "Full info" dialog of the level page.
class ProfileStatsDialog extends StatelessWidget {
  const ProfileStatsDialog({super.key, required this.title, required this.groups, this.onOpenPass});

  final String title;
  final List<StatGroup> groups;
  final void Function(int passId)? onOpenPass;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required List<StatGroup> groups,
    void Function(int passId)? onOpenPass,
  }) => showDialog(
    context: context,
    builder: (context) => ProfileStatsDialog(title: title, groups: groups, onOpenPass: onOpenPass),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(l10n.titleStats(title), style: theme.textTheme.headlineSmall)),
                  IconButton(
                    tooltip: l10n.close,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: _DialogScroll(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const gap = 24.0;
                      final columns = (constraints.maxWidth / 240).floor().clamp(1, 3);
                      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
                      return Wrap(
                        spacing: gap,
                        runSpacing: 20,
                        children: [
                          for (final group in groups)
                            SizedBox(
                              width: width,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(group.label, style: theme.textTheme.titleSmall),
                                  const SizedBox(height: 6),
                                  for (final row in group.rows)
                                    _StatLine(
                                      row: row,
                                      onOpenPass: onOpenPass,
                                      close: () => Navigator.of(context).pop(),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogScroll extends StatefulWidget {
  const _DialogScroll({required this.child});

  final Widget child;

  @override
  State<_DialogScroll> createState() => _DialogScrollState();
}

class _DialogScrollState extends State<_DialogScroll> {
  final _scroll = SmoothScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SmoothScrollbar(
    controller: _scroll,
    builder: (context, behavior) => ScrollConfiguration(
      behavior: behavior,
      // Leave room on the right for the scrollbar.
      child: SingleChildScrollView(controller: _scroll, padding: const EdgeInsets.only(right: 16), child: widget.child),
    ),
  );
}

/// One "Total passes   326" line. Lines tied to a pass get a button to it.
class _StatLine extends StatelessWidget {
  const _StatLine({required this.row, this.onOpenPass, required this.close});

  final StatRow row;
  final void Function(int passId)? onOpenPass;
  final VoidCallback close;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final passId = row.passId;
    final open = onOpenPass;
    final value = Text(row.value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          if (row.tooltip case final tip?) HoverTip(message: tip, child: value) else value,
          if (passId != null && open != null)
            IconButton(
              tooltip: l10n.viewPass,
              // Keep the button small so lines with one are as tall as the others.
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 22),
              iconSize: 16,
              onPressed: () {
                close();
                open(passId);
              },
              icon: const Icon(Icons.open_in_new),
            ),
        ],
      ),
    );
  }
}

/// Every difficulty icon, cleared ones lit (opened from the icon row button).
class DifficultyGridPanel extends StatelessWidget {
  const DifficultyGridPanel({super.key, required this.difficulties, required this.clears});

  final List<Difficulty> difficulties;
  final Map<int, int> clears;

  @override
  Widget build(BuildContext context) {
    final pgu = [
      for (final d in difficulties)
        if (d.type == 'PGU' && d.name != 'Unranked') d,
    ];
    final special = [
      for (final d in difficulties)
        if (d.type == 'SPECIAL' && !const {'Unranked', 'Impossible', 'Qq'}.contains(d.name)) d,
    ];

    Widget grid(List<Difficulty> list) => Wrap(
      children: [
        for (final d in list)
          HoverTip(
            message: l10n.difficultyClearCount(d.name, clears[d.id] ?? 0),
            child: Opacity(
              opacity: (clears[d.id] ?? 0) > 0 ? 1 : 0.22,
              child: Padding(padding: const EdgeInsets.all(3), child: NetworkIcon(d.icon, size: 32)),
            ),
          ),
      ],
    );

    return SizedBox(
      width: 10 * 38,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          grid(pgu),
          if (special.isNotEmpty) ...[const Divider(height: 24), grid(special)],
        ],
      ),
    );
  }
}

/// Curation types by group with level counts (opened from the creator icon row button).
class CurationPanel extends StatelessWidget {
  const CurationPanel({super.key, required this.types, required this.counts});

  final List<FacetItem> types;
  final Map<int, int> counts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = <String, List<FacetItem>>{};
    for (final type in types) {
      if ((counts[type.id] ?? 0) <= 0) continue;
      groups.putIfAbsent(type.group ?? l10n.other, () => []).add(type);
    }
    return SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in groups.entries) ...[
            Text(entry.key, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in entry.value)
                  InfoChip(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [NetworkIcon(type.icon, size: 16), Text('${type.name}  ${counts[type.id]}')],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

/// Creator verification chip (allowed, conditional, pending, declined). Conditions show on hover.
class VerificationBadge extends StatelessWidget {
  const VerificationBadge({super.key, required this.label, required this.color, this.conditions});

  final String label;
  final Color color;
  final String? conditions;

  @override
  Widget build(BuildContext context) {
    final text = conditions;
    final hasConditions = text != null && text.isNotEmpty;
    return InfoChip(
      label: label,
      color: color,
      tip: hasConditions ? l10n.uploadConditions(text) : l10n.levelUploadPermission,
      trailingIcon: hasConditions ? Icons.info_outline : null,
    );
  }
}

/// Small progress indicator used like a button while loading.
class ProfileLoading extends StatelessWidget {
  const ProfileLoading({super.key, this.height = 120});

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: const Center(child: CircularProgressIndicator()),
  );
}

/// Collapsible group row (tournament series or event): chevron, title, count.
class ProfileGroupRow extends StatelessWidget {
  const ProfileGroupRow({
    super.key,
    required this.title,
    required this.count,
    required this.open,
    required this.onTap,
    this.trailing,
    this.leading,
  });

  final String title;
  final int count;
  final bool open;
  final VoidCallback onTap;
  final Widget? trailing;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return HoverCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          AnimatedRotation(
            turns: open ? 0.25 : 0,
            duration: Motion.medium,
            curve: Motion.curve,
            child: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 8),
          if (leading case final l?) ...[l, const SizedBox(width: 10)],
          Expanded(
            child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
          ),
          ?trailing,
          const SizedBox(width: 8),
          InfoChip(label: '$count'),
        ],
      ),
    );
  }
}
