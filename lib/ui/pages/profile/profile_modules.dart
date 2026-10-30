import 'package:flutter/material.dart';

import '../../../app/controllers.dart';
import '../../../core/l10n.dart';
import '../../../core/models/profile.dart';
import '../../../core/profile_stats.dart';
import '../../../core/tuf_api_client.dart';
import '../../widgets/common.dart';
import '../../widgets/hover_tip.dart';
import '../../widgets/level_card.dart';
import '../../widgets/motion.dart';
import '../../widgets/pass_badges.dart';
import '../../widgets/pass_row.dart';
import '../../widgets/slide_overflow.dart';
import 'profile_charts.dart';
import 'bio_canvas.dart';
import 'profile_header.dart';
import 'profile_navigation.dart';
import 'profile_section.dart';

/// App card holding module content, filling the width even when the content is short.
Widget _card(Widget child) => SizedBox(
  width: double.infinity,
  child: Card(
    margin: EdgeInsets.zero,
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

// ───────────────────────── Bio ─────────────────────────

/// Bio. Supporters' composed bios are drawn as a free-form canvas like on the website ([BioCanvas]).
class BioModule extends StatelessWidget {
  const BioModule({super.key, required this.title, required this.bio});

  final String title;
  final ProfileBio bio;

  @override
  Widget build(BuildContext context) => ProfileSection(
    title: title,
    child: _card(
      bio.blocks.isEmpty
          ? SelectableText(bio.text ?? '', style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5))
          : BioCanvas(blocks: bio.blocks),
    ),
  );
}

// ───────────────────────── Tournaments ─────────────────────────

/// Tournament placements, collapsed as series → tournament → placement cards (same order and grouping as the website).
class TournamentsModule extends StatefulWidget {
  const TournamentsModule({super.key, required this.placements, this.orderIds = const []});

  final List<TournamentPlacement> placements;
  final List<int> orderIds;

  /// Placements to show: public ones only, and only the best placement per tournament.
  static List<TournamentPlacement> visible(List<TournamentPlacement> placements, List<int> orderIds) {
    final public = [
      for (final placement in placements)
        if (placement.isPublic) placement,
    ];
    final best = <int, int>{};
    for (final placement in public) {
      final id = placement.tournamentId;
      if (id == null || !placement.showBestTiersOnly) continue;
      final weight = placement.tierRankWeight ?? 1 << 30;
      if (weight < (best[id] ?? 1 << 30)) best[id] = weight;
    }
    final list = [
      for (final placement in public)
        if (placement.tournamentId == null ||
            !placement.showBestTiersOnly ||
            (placement.tierRankWeight ?? 1 << 30) == best[placement.tournamentId])
          placement,
    ];

    int byDefault(TournamentPlacement a, TournamentPlacement b) {
      if (a.seriesSortWeight != b.seriesSortWeight) return a.seriesSortWeight.compareTo(b.seriesSortWeight);
      if (a.tournamentSortWeight != b.tournamentSortWeight) {
        return a.tournamentSortWeight.compareTo(b.tournamentSortWeight);
      }
      final tier = (a.tierRankWeight ?? 0).compareTo(b.tierRankWeight ?? 0);
      if (tier != 0) return tier;
      final year = (b.sortYear ?? 0).compareTo(a.sortYear ?? 0);
      return year != 0 ? year : b.id.compareTo(a.id);
    }

    final order = {for (final (index, id) in orderIds.indexed) id: index};
    return list..sort((a, b) {
      final ao = order[a.id];
      final bo = order[b.id];
      if (ao != null && bo != null) return ao.compareTo(bo);
      if (ao != null) return -1;
      if (bo != null) return 1;
      return byDefault(a, b);
    });
  }

  @override
  State<TournamentsModule> createState() => _TournamentsModuleState();
}

class _TournamentsModuleState extends State<TournamentsModule> {
  final _open = <String>{};

  void _toggle(String key) => setState(() => _open.contains(key) ? _open.remove(key) : _open.add(key));

  @override
  Widget build(BuildContext context) {
    final list = TournamentsModule.visible(widget.placements, widget.orderIds);

    // Group by series, then tournament.
    final series = <String, ({String? name, int weight, Map<String, List<TournamentPlacement>> tournaments})>{};
    for (final placement in list) {
      final key = placement.seriesId == null ? 'none' : 'series-${placement.seriesId}';
      final group = series.putIfAbsent(
        key,
        () => (name: placement.seriesName, weight: placement.seriesSortWeight, tournaments: {}),
      );
      group.tournaments.putIfAbsent('tournament-${placement.tournamentId}', () => []).add(placement);
    }
    final groups = series.entries.toList()..sort((a, b) => a.value.weight.compareTo(b.value.weight));

    Widget tournament(String key, List<TournamentPlacement> credits, {bool indent = true}) {
      final first = credits.first;
      final open = _open.contains(key);
      final pack = first.packRef;
      return Padding(
        padding: EdgeInsets.only(left: indent ? 24 : 0, top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileGroupRow(
              title: first.tournamentName.isEmpty ? l10n.tournaments : first.tournamentName,
              count: credits.length,
              open: open,
              onTap: () => _toggle(key),
              trailing: pack == null
                  ? null
                  : IconButton(
                      tooltip: l10n.openPack,
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      onPressed: () => ProfileNavigation.openPack(context, pack),
                      icon: const Icon(Icons.inventory_2_outlined),
                    ),
            ),
            Reveal(
              visible: open,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 0, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [for (final credit in credits) _PlacementCard(placement: credit)],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ProfileSection(
      title: l10n.tournaments,
      subtitle: l10n.placementCount(list.length),
      child: _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final group in groups)
              if (group.key == 'none')
                // Tournaments without a series are shown directly, ungrouped.
                for (final entry in group.value.tournaments.entries) tournament(entry.key, entry.value, indent: false)
              else
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ProfileGroupRow(
                        title: group.value.name ?? l10n.otherTournaments,
                        count: group.value.tournaments.values.fold(0, (sum, credits) => sum + credits.length),
                        open: _open.contains(group.key),
                        onTap: () => _toggle(group.key),
                      ),
                      Reveal(
                        visible: _open.contains(group.key),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final entry
                                in group.value.tournaments.entries.toList()..sort(
                                  (a, b) =>
                                      a.value.first.tournamentSortWeight.compareTo(b.value.first.tournamentSortWeight),
                                ))
                              tournament(entry.key, entry.value),
                          ],
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

/// Placement card: tournament icon on the left; placement, level, year and team on the right.
class _PlacementCard extends StatelessWidget {
  const _PlacementCard({required this.placement});

  final TournamentPlacement placement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final levelId = placement.levelId;
    final details = [if (placement.sortYear case final year?) '$year', ?placement.teamName].join(' · ');
    return SizedBox(
      width: 240,
      child: HoverCard(
        padding: const EdgeInsets.all(10),
        onTap: levelId == null ? null : () => ProfileNavigation.openLevel(context, levelId),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 40,
              child: placement.iconUrl == null
                  ? Icon(Icons.emoji_events_outlined, color: theme.colorScheme.primary)
                  : NetworkIcon(placement.iconUrl, size: 40),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(placement.tierLabel, style: theme.textTheme.titleSmall),
                  if (placement.levelName case final level?)
                    SlideOverflow(
                      child: slidingText(level, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                    ),
                  if (details.isNotEmpty) Text(details, style: theme.textTheme.labelSmall?.copyWith(color: muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Score breakdown ─────────────────────────

/// The eight scores as tiles. Hovering the (i) next to a name shows its description.
class ScoreBreakdownModule extends StatelessWidget {
  const ScoreBreakdownModule({super.key, required this.player});

  final PlayerProfileDetail player;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return ProfileSection(
      title: l10n.scoreBreakdown,
      child: _card(
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 8.0;
            final columns = ((constraints.maxWidth + gap) / (170 + gap)).floor().clamp(1, 4);
            final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final key in PlayerScoreKey.values)
                  SizedBox(
                    width: width,
                    child: ProfileTile(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            spacing: 4,
                            children: [
                              Flexible(
                                child: Text(
                                  key.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                                ),
                              ),
                              HoverTip(
                                message: key.description,
                                child: Icon(Icons.info_outline, size: 14, color: muted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            key == PlayerScoreKey.averageXacc
                                ? formatAccuracyRatio(player.score(key))
                                : formatPoints(player.score(key)),
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ───────────────────────── Difficulty chart ─────────────────────────

/// Chart of clears (players) or levels (creators) per difficulty.
class DifficultyModule extends StatefulWidget {
  const DifficultyModule({super.key, required this.title, required this.counts, this.countsWithDupes});

  final String title;

  /// Difficulty id → count. For players, reclears are excluded.
  final Map<String, dynamic> counts;

  /// Counts including reclears. When set, an "Include duplicates" chip is shown (players).
  final Map<String, dynamic>? countsWithDupes;

  @override
  State<DifficultyModule> createState() => _DifficultyModuleState();
}

class _DifficultyModuleState extends State<DifficultyModule> {
  bool _includeDupes = false;

  @override
  Widget build(BuildContext context) {
    final catalog = AppScope.of(context).levels.catalog;
    final withDupes = widget.countsWithDupes;
    final levels = withDupes == null;
    final bars = difficultyBars(
      _includeDupes && withDupes != null ? withDupes : widget.counts,
      catalog,
      levels: levels,
    );

    return ProfileSection(
      title: widget.title,
      trailing: [
        if (withDupes != null)
          FilterChip(
            label: Text(l10n.includeDuplicates),
            selected: _includeDupes,
            onSelected: (value) => setState(() => _includeDupes = value),
          ),
      ],
      child: _card(DifficultyBarChart(bars: bars, levels: levels)),
    );
  }
}

// ───────────────────────── Rank history ─────────────────────────

/// How the ranked score (or general score) rank changed over time.
class RankHistoryModule extends StatefulWidget {
  const RankHistoryModule({super.key, required this.playerId});

  final int playerId;

  @override
  State<RankHistoryModule> createState() => _RankHistoryModuleState();
}

enum _RankRange {
  days30(30),
  days90(90),
  days365(365),
  all(null);

  const _RankRange(this.days);

  String get label => switch (this) {
    days30 => l10n.rankRangeDays30,
    days90 => l10n.rankRangeDays90,
    days365 => l10n.rankRangeDays365,
    all => l10n.rankRangeAll,
  };
  final int? days;
}

class _RankHistoryModuleState extends State<RankHistoryModule> {
  bool _general = false;
  _RankRange _range = _RankRange.days365;
  List<RankHistoryPoint>? _points;
  String? _error;
  int _request = 0;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _points = null;
      _error = null;
    });
    final days = _range.days;
    final now = DateTime.now().toUtc();
    try {
      final points = await AppScope.of(context).api.getRankHistory(
        widget.playerId,
        from: days == null ? null : now.subtract(Duration(days: days)),
        to: days == null ? null : now,
      );
      if (mounted && request == _request) setState(() => _points = points);
    } on Object catch (e) {
      // Unexpected errors too, so the chart never stays loading forever.
      if (mounted && request == _request) setState(() => _error = e is TufApiException ? e.message : '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = _points;
    final series = [
      for (final point in points ?? const <RankHistoryPoint>[])
        (date: point.date, rank: _general ? point.generalRank : point.rankedRank),
    ];
    final status = _error != null
        ? l10n.couldntLoadRankHistory
        : points == null
        ? null
        : series.isEmpty
        ? l10n.noRankHistoryStored
        : null;

    return ProfileSection(
      title: l10n.rankOverTime,
      child: _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 8,
              children: [
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: false, label: Text(l10n.rankedScoreLine)),
                    ButtonSegment(value: true, label: Text(l10n.generalScore)),
                  ],
                  selected: {_general},
                  onSelectionChanged: (value) => setState(() => _general = value.first),
                ),
                SegmentedButton<_RankRange>(
                  showSelectedIcon: false,
                  segments: [
                    for (final range in _RankRange.values) ButtonSegment(value: range, label: Text(range.label)),
                  ],
                  selected: {_range},
                  onSelectionChanged: (value) {
                    setState(() => _range = value.first);
                    _load();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            FadeSwitcher(
              child: points == null && _error == null
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      height: RankHistoryChart.height,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : status != null
                  ? SizedBox(
                      key: ValueKey(status),
                      height: 120,
                      child: Center(
                        child: Text(
                          status,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    )
                  : RankHistoryChart(key: ValueKey((_range, _general)), points: series),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Pass row ─────────────────────────

/// One of a player's passes ([PassRow] layout, the size of a level card).
/// Like the website's score card, shows the song and, under the score, what it adds to the ranked score.
class ProfileScoreCard extends StatelessWidget {
  const ProfileScoreCard({
    super.key,
    required this.entry,
    this.impact,
    this.potentialImpact,
    this.featured = false,
    this.embedded = false,
  });

  final PlayerPassEntry entry;

  /// Score added to the ranked score (top passes).
  final double? impact;

  /// Score it could have added if the level file weren't missing.
  final double? potentialImpact;

  /// Row inside a favorites module: the top line shows who made the pass.
  final bool featured;

  /// Narrow row inside a bio ([PassRow.embedded]).
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final pass = entry.pass;
    final level = entry.level;
    final hidden = entry.levelHidden;
    final difficulty = app.levels.catalog?.byId(level.diffId) ?? level.difficulty;

    return PassRow(
      pass: pass,
      onTap: () => ProfileNavigation.openPass(context, pass.id),
      videoBackdrop: !hidden,
      leading: PassDifficultyIcon(icon: difficulty?.icon, hidden: hidden),
      // Same order as level cards: "#id - artist" on top, song in the middle.
      top: featured
          ? pass.playerName
          : hidden
          ? null
          : ['#${level.id}', if (level.artist.isNotEmpty) level.artist].join(' - '),
      title: SlideOverflow(
        child: slidingText(hidden ? l10n.hiddenLevel : level.song, style: theme.textTheme.titleMedium),
      ),
      bottomText: hidden ? null : level.creatorDisplay,
      impact: impact,
      potentialImpact: impact == null ? potentialImpact : null,
      showDate: !featured,
      embedded: embedded,
    );
  }
}

/// Note below the last pass that counts toward the ranked score.
class RankedCutoffNote extends StatelessWidget {
  const RankedCutoffNote({super.key, required this.score});

  /// Score of that last pass; a pass must score higher to count.
  final double score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Text(
                  l10n.passesAboveCountToward,
                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                ImpactChip(text: l10n.scoreOrMore(formatPoints(score + 0.01)), positive: true),
              ],
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

// ───────────────────────── Favorites ─────────────────────────

/// Passes, levels, packs, players and creators picked by the user.
class FavoritesModule extends StatelessWidget {
  const FavoritesModule({super.key, required this.items});

  final List<FavoriteItem> items;

  @override
  Widget build(BuildContext context) => ProfileSection(
    title: l10n.favorites,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        for (final item in items)
          switch (item) {
            FavoritePass(:final entry) => ProfileScoreCard(entry: entry, featured: true),
            FavoriteLevel(:final level) => LevelCard(level: level, compact: false),
            FavoritePack(:final pack) => _SimpleTile(
              leading: NetworkIcon(pack.iconUrl, size: 40),
              title: pack.name,
              subtitle: l10n.pack,
              onTap: () => ProfileNavigation.openPack(context, pack.id),
            ),
            FavoritePlayer(:final id, :final name, :final country, :final avatar, :final rankedScore, :final rank) =>
              _SimpleTile(
                leading: ProfileAvatar(avatar: avatar, size: 40),
                title: name,
                titleTrailing: country == null ? null : CountryFlag(country: country, height: 12),
                subtitle: [
                  if (rank case final r? when r > 0) '#$r',
                  if (rankedScore case final score?) l10n.rankedScoreValue(formatPoints(score)),
                ].join(' · '),
                onTap: () => ProfileNavigation.openPlayer(context, id),
              ),
            FavoriteCreator(:final id, :final name, :final avatar, :final chartsTotal) => _SimpleTile(
              leading: ProfileAvatar(avatar: avatar, size: 40),
              title: name,
              subtitle: chartsTotal == null ? l10n.creator : l10n.chartLevelCount(chartsTotal),
              onTap: () => ProfileNavigation.openCreator(context, id),
            ),
          },
      ],
    ),
  );
}

class _SimpleTile extends StatelessWidget {
  const _SimpleTile({
    required this.leading,
    required this.title,
    this.titleTrailing,
    required this.subtitle,
    required this.onTap,
  });

  final Widget leading;
  final String title;
  final Widget? titleTrailing;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return HoverCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        spacing: 12,
        children: [
          leading,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  spacing: 6,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    ?titleTrailing,
                  ],
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
