import 'package:flutter/material.dart';

import '../../app/controllers.dart';
import '../../core/l10n.dart';
import '../../core/models/browse.dart';
import '../../core/models/facet.dart';
import '../../core/models/profile.dart';
import '../../core/profile_stats.dart';
import '../widgets/common.dart';
import '../widgets/labels.dart';
import '../widgets/motion.dart';
import '../widgets/slide_overflow.dart';
import 'browse_page.dart';
import 'profile/creator_profile_page.dart';
import 'profile/profile_header.dart';
import 'profile/profile_navigation.dart';

/// Creators page: people who make levels (the website's /creators).
class CreatorsPage extends StatelessWidget {
  const CreatorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final creators = app.creators;
    return ListenableBuilder(
      listenable: Listenable.merge([creators, app.levels]),
      builder: (context, _) => BrowsePage<CreatorListEntry>(
        list: creators,
        title: l10n.creators,
        subtitle: l10n.findThePeopleWho,
        toolbar: _Toolbar(creators: creators),
        filter: Reveal(
          visible: creators.filterOpen,
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _FilterCard(creators: creators, curations: app.levels.curationCatalog),
          ),
        ),
        countText: (total) => l10n.creatorCount(total),
        itemKey: (creator) => creator.id,
        itemBuilder: (context, creator, index) => CreatorRow(creator: creator, sort: creators.sort),
        emptyTitle: l10n.noCreatorsFound,
        endText: l10n.allCreatorsLoaded,
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.creators});

  final CreatorsController creators;

  @override
  Widget build(BuildContext context) {
    final filterCount = creators.activeFilterCount;
    const filterIcon = Icon(Icons.tune);
    return Row(
      children: [
        Expanded(
          child: BrowseSearchBar(
            initialText: creators.query,
            hint: l10n.searchByCreatorName,
            onChanged: creators.setQuery,
          ),
        ),
        const SizedBox(width: 12),
        DropdownMenu<CreatorSort>(
          // The selected label is only filled in on creation, so recreate the menu when the language changes.
          key: ValueKey(appLanguage),
          initialSelection: creators.sort,
          label: Text(l10n.sort),
          width: 220,
          onSelected: (value) {
            if (value != null) creators.setSort(value);
          },
          dropdownMenuEntries: [
            for (final sort in CreatorSort.values) DropdownMenuEntry(value: sort, label: sort.label),
          ],
        ),
        const SizedBox(width: 8),
        OrderButton(descending: creators.descending, onPressed: creators.toggleOrder),
        const SizedBox(width: 8),
        Badge(
          isLabelVisible: filterCount > 0,
          label: Text('$filterCount'),
          child: FadeSwitcher(
            duration: Motion.fast,
            child: creators.filterOpen
                ? FilledButton.tonalIcon(
                    key: const ValueKey('open'),
                    onPressed: creators.toggleFilterOpen,
                    icon: filterIcon,
                    label: Text(l10n.filter),
                  )
                : OutlinedButton.icon(
                    key: const ValueKey('closed'),
                    onPressed: creators.toggleFilterOpen,
                    icon: filterIcon,
                    label: Text(l10n.filter),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Filters by verification status and curation type.
class _FilterCard extends StatelessWidget {
  const _FilterCard({required this.creators, required this.curations});

  final CreatorsController creators;
  final FacetCatalog? curations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final groups = <String, List<FacetItem>>{};
    for (final type in curations?.all ?? const <FacetItem>[]) {
      groups.putIfAbsent(type.group ?? l10n.other, () => []).add(type);
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.verificationStatus, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<CreatorVerification?>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: null, label: Text(l10n.allStatuses)),
                for (final status in CreatorVerification.values)
                  ButtonSegment(value: status, label: Text(status.label)),
              ],
              selected: {creators.verification},
              onSelectionChanged: (selection) => creators.setVerification(selection.first),
            ),
            if (groups.isNotEmpty) ...[
              const Divider(height: 32),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.curationTypes, style: theme.textTheme.labelLarge),
                        Text(l10n.onlyShowsCreatorsWith, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                      ],
                    ),
                  ),
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: false, label: Text(l10n.matchAny)),
                      ButtonSegment(value: true, label: Text(l10n.matchAll)),
                    ],
                    selected: {creators.curationsMatchAll},
                    onSelectionChanged: (selection) => creators.setCurationsMatchAll(selection.first),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final entry in groups.entries) ...[
                Text(entry.key, style: theme.textTheme.labelMedium?.copyWith(color: muted)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in entry.value)
                      FilterChip(
                        avatar: NetworkIcon(type.icon, size: 18),
                        label: Text(type.name),
                        selected: creators.curationTypeIds.contains(type.id),
                        onSelected: (_) => creators.toggleCuration(type.id),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: creators.resetFilters,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.resetAll),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One creator row (the website's CreatorCard): avatar, name and verification, account, curation icons,
/// the sort value (emphasized) and clear/like counts. Tapping opens the creator page.
class CreatorRow extends StatelessWidget {
  const CreatorRow({super.key, required this.creator, required this.sort});

  final CreatorListEntry creator;
  final CreatorSort sort;

  /// Fixed width for the curation icons so the columns to the right line up regardless of how many there are.
  static const _slotSize = 28.0;
  static const _maxSlots = 5;
  static const _slotsWidth = _maxSlots * (_slotSize + 4) + (_maxSlots - 1) * 6;

  /// Below this inner card width the curation icons are hidden (keeping roughly 200px for the name).
  static const _slotsMinWidth = 960.0;

  /// When sorted by name the name is already visible, so the level count is emphasized (as on the website).
  static CreatorSort primaryFor(CreatorSort sort) => sort == CreatorSort.name ? CreatorSort.chartsTotal : sort;

  /// Values shown next to the emphasized one: clears and likes, minus the emphasized key (as on the website).
  static List<CreatorSort> secondaryFor(CreatorSort sort) =>
      [CreatorSort.totalChartClears, CreatorSort.totalChartLikes].where((key) => key != primaryFor(sort)).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final slots = curationIconSlots(
      creator.curationTypeCounts,
      creator.displayCurationTypeIds,
      AppScope.of(context).levels.curationCatalog,
    ).take(_maxSlots).toList();
    final handle = creator.handle;

    return HoverCard(
      onTap: () => ProfileNavigation.openCreator(context, creator.id),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      // In narrow windows, drop the curation icons so the name column doesn't get too narrow.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showSlots = constraints.maxWidth >= _slotsMinWidth;
          return Row(
            children: [
              ProfileAvatar(avatar: creator.avatar, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: SlideOverflow(child: slidingText(creator.name, style: theme.textTheme.titleSmall)),
                        ),
                        const SizedBox(width: 8),
                        VerificationBadge(
                          label: creator.verification.label,
                          color: CreatorProfilePage.verificationColor(creator.verification),
                        ),
                      ],
                    ),
                    Text(
                      [handle == null ? l10n.noLinkedAccount : '@$handle', 'ID ${creator.id}'].join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
              if (showSlots) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: _slotsWidth,
                  child: Row(
                    spacing: 6,
                    children: [for (final slot in slots) IconSlotView(slot: slot, size: _slotSize)],
                  ),
                ),
              ],
              const SizedBox(width: 12),
              SizedBox(
                width: 168,
                child: _Stat(creator: creator, sort: primaryFor(sort), emphasized: true),
              ),
              for (final key in secondaryFor(sort))
                SizedBox(
                  width: 132,
                  child: _Stat(creator: creator, sort: key),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// A label and value (same look as the leaderboard). The emphasized one is filled like a rank chip.
class _Stat extends StatelessWidget {
  const _Stat({required this.creator, required this.sort, this.emphasized = false});

  final CreatorListEntry creator;
  final CreatorSort sort;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
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
        Text(
          formatNumber(creator.count(sort)),
          maxLines: 1,
          softWrap: false,
          style: emphasized
              ? theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSecondaryContainer)
              : theme.textTheme.bodyMedium,
        ),
      ],
    );

    if (!emphasized) return Padding(padding: const EdgeInsets.only(left: 12), child: content);
    return ValueBox(child: content);
  }
}
