import 'package:flutter/material.dart';

import '../../app/controllers.dart';
import '../../core/l10n.dart';
import '../../core/models/browse.dart';
import '../../core/profile_stats.dart';
import '../widgets/common.dart';
import '../widgets/hover_tip.dart';
import '../widgets/labels.dart';
import '../widgets/motion.dart';
import '../widgets/slide_overflow.dart';
import 'browse_page.dart';
import 'profile/profile_header.dart';
import 'profile/profile_navigation.dart';

/// Leaderboard page: player rankings (the website's leaderboard).
class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final leaderboard = AppScope.of(context).leaderboard;
    return ListenableBuilder(
      listenable: leaderboard,
      builder: (context, _) => BrowsePage<LeaderboardPlayer>(
        list: leaderboard,
        title: l10n.leaderboard,
        subtitle: l10n.seePlayerRankingsBy,
        toolbar: _Toolbar(leaderboard: leaderboard),
        countText: (total) => l10n.playerCount(total),
        itemKey: (player) => player.id,
        itemBuilder: (context, player, index) => LeaderboardRow(player: player, sort: leaderboard.sort),
        emptyTitle: l10n.noPlayersFound,
        endText: l10n.allPlayersLoaded,
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.leaderboard});

  final LeaderboardController leaderboard;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: BrowseSearchBar(
          initialText: leaderboard.query,
          hint: l10n.searchByPlayerName,
          onChanged: leaderboard.setQuery,
        ),
      ),
      const SizedBox(width: 12),
      DropdownMenu<LeaderboardSort>(
        // The selected label is only filled in on creation, so recreate the menu when the language changes.
        key: ValueKey(appLanguage),
        initialSelection: leaderboard.sort,
        label: Text(l10n.sort),
        width: 220,
        menuHeight: 420,
        onSelected: (value) {
          if (value != null) leaderboard.setSort(value);
        },
        dropdownMenuEntries: [
          for (final sort in LeaderboardSort.values) DropdownMenuEntry(value: sort, label: sort.label),
        ],
      ),
      const SizedBox(width: 8),
      OrderButton(descending: leaderboard.descending, onPressed: leaderboard.toggleOrder),
      const SizedBox(width: 8),
      IconButton(tooltip: l10n.refresh, onPressed: leaderboard.reload, icon: const Icon(Icons.refresh)),
    ],
  );
}

/// One ranking row: rank, avatar, name and country, the sort value (emphasized),
/// two key values, top difficulty. Tapping opens the player page.
class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({super.key, required this.player, required this.sort});

  final LeaderboardPlayer player;
  final LeaderboardSort sort;

  /// Values shown next to the sort key: two of ranked score, average X-acc and total score, as on the website.
  static List<LeaderboardSort> secondaryFor(LeaderboardSort sort) {
    final rest = [
      LeaderboardSort.rankedScore,
      LeaderboardSort.totalScoreV2,
      LeaderboardSort.averageXacc,
    ].where((key) => key != sort).toList();
    if (rest.length > 2) rest.remove(LeaderboardSort.totalScoreV2);
    return rest;
  }

  static String formatValue(LeaderboardSort sort, double value) {
    if (sort == LeaderboardSort.averageXacc) return formatAccuracyRatio(value);
    if (sort.isCount) return formatNumber(value.round());
    return formatPoints(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final rank = player.rank;
    final top = player.topDifficulty;

    return HoverCard(
      onTap: () => ProfileNavigation.openPlayer(context, player.id),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              rank > 0 ? '#${formatNumber(rank)}' : '-',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: medalColor(rank) ?? muted,
                fontWeight: rank <= 3 && rank > 0 ? FontWeight.w800 : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ProfileAvatar(avatar: player.avatar, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: SlideOverflow(child: slidingText(player.name, style: theme.textTheme.titleSmall)),
                    ),
                    if (player.country != null) ...[
                      const SizedBox(width: 6),
                      CountryFlag(country: player.country, height: 12),
                    ],
                  ],
                ),
                Text('ID ${player.id}', style: theme.textTheme.labelSmall?.copyWith(color: muted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 168,
            child: _Stat(player: player, sort: sort, emphasized: true),
          ),
          for (final key in secondaryFor(sort))
            SizedBox(
              width: 132,
              child: _Stat(player: player, sort: key),
            ),
          SizedBox(
            width: 48,
            child: top == null
                ? null
                : HoverTip(
                    message: l10n.topDifficulty(top.name),
                    child: Align(alignment: Alignment.centerRight, child: NetworkIcon(top.icon, size: 32)),
                  ),
          ),
        ],
      ),
    );
  }
}

/// A label and value. The sort key is emphasized like the rank chip on the passes page.
class _Stat extends StatelessWidget {
  const _Stat({required this.player, required this.sort, this.emphasized = false});

  final LeaderboardPlayer player;
  final LeaderboardSort sort;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final valueStyle = emphasized
        ? theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSecondaryContainer)
        : theme.textTheme.bodyMedium;
    final difficulty = player.difficulty(sort);

    final Widget value = sort.isDifficulty
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (difficulty != null) ...[NetworkIcon(difficulty.icon, size: 20), const SizedBox(width: 6)],
              Text(difficulty?.name ?? '-', style: valueStyle),
            ],
          )
        : Text(LeaderboardRow.formatValue(sort, player.value(sort)), maxLines: 1, softWrap: false, style: valueStyle);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          sort.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: emphasized ? theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.8) : muted,
          ),
        ),
        value,
      ],
    );

    if (!emphasized) return Padding(padding: const EdgeInsets.only(left: 12), child: content);
    return ValueBox(child: content);
  }
}
