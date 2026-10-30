import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/controllers.dart';
import '../../core/l10n.dart';
import '../../core/models/pack.dart';
import '../widgets/common.dart';
import '../widgets/hover_tip.dart';
import '../widgets/labels.dart';
import '../widgets/level_card.dart';
import '../widgets/motion.dart';
import '../widgets/raster_snapshot.dart';
import '../widgets/slide_overflow.dart';
import '../app_shortcuts.dart';
import '../widgets/smooth_scroll.dart';

/// Same centered width as the other pages.
const _maxWidth = pageMaxWidth;
const _gutter = 24.0;

Widget _constrain(Widget child) => Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: _maxWidth),
    child: SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _gutter),
        child: child,
      ),
    ),
  ),
);

Widget _section(Widget child) => SliverToBoxAdapter(child: _constrain(child));

/// Centers a sliver within [_maxWidth] (for slivers like the grid that _constrain can't wrap).
Widget _centeredSliver(Widget sliver) => SliverLayoutBuilder(
  builder: (context, constraints) {
    final side = max(_gutter, (constraints.crossAxisExtent - _maxWidth) / 2 + _gutter);
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: side),
      sliver: sliver,
    );
  },
);

/// Community level packs. Tapping a pack opens its contents on top of the list.
class PacksPage extends StatefulWidget {
  const PacksPage({super.key});

  @override
  State<PacksPage> createState() => _PacksPageState();
}

class _PacksPageState extends State<PacksPage> {
  @override
  Widget build(BuildContext context) {
    final packs = AppScope.of(context).packs;

    return ListenableBuilder(
      listenable: packs,
      builder: (context, _) {
        final opened = packs.openedPack != null;
        return Stack(
          fit: StackFit.expand,
          children: [
            // The list stays alive so its scroll position is kept when coming back.
            Offstage(
              offstage: opened,
              child: TickerMode(
                enabled: !opened,
                child: _PackList(packs: packs),
              ),
            ),
            FadeSwitcher(
              child: opened
                  ? _PackDetailView(key: ValueKey(packs.openedPack!.id), packs: packs)
                  : const SizedBox.shrink(key: ValueKey('none')),
            ),
          ],
        );
      },
    );
  }
}

// ───────────────────────── Pack list ─────────────────────────

class _PackList extends StatefulWidget {
  const _PackList({required this.packs});

  final PacksController packs;

  @override
  State<_PackList> createState() => _PackListState();
}

class _PackListState extends State<_PackList> {
  static const _loadMoreThreshold = 600.0;

  final _scroll = SmoothScrollController();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.text = widget.packs.query;
    _scroll.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (_scroll.hasClients && _scroll.position.extentAfter < _loadMoreThreshold) widget.packs.loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final packs = widget.packs;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && packs.hasMore && !packs.isLoadingMore && !packs.isSearching) _maybeLoadMore();
      // Sync the search box when the query was set elsewhere (a profile's "View user's packs").
      if (mounted && _search.text != packs.query) _search.text = packs.query;
    });

    return PageCommandScope(
      commands: () => PageCommands(scroll: _scroll, refresh: packs.search),
      child: SmoothScrollbar(
        controller: _scroll,
        builder: (context, behavior) => CustomScrollView(
          controller: _scroll,
          scrollBehavior: behavior,
          slivers: [
            _section(const Padding(padding: EdgeInsets.only(top: 24), child: _ListHeader())),
            _section(
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _ListToolbar(packs: packs, searchController: _search),
              ),
            ),
            _section(
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 12),
                child: _ListResultsHeader(packs: packs),
              ),
            ),
            _centeredSliver(
              SliverAnimatedOpacity(
                opacity: packs.isSearching && packs.packs.isNotEmpty ? 0.45 : 1,
                duration: Motion.medium,
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    mainAxisExtent: _PackCard.height,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: packs.packs.length,
                  itemBuilder: (context, index) {
                    final pack = packs.packs[index];
                    return _PackCard(key: ValueKey(pack.id), pack: pack, onOpen: () => packs.open(pack));
                  },
                ),
              ),
            ),
            _section(_ListFooter(packs: packs)),
          ],
        ),
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.levelPacks, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          l10n.browseLevelPacksMade,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ListToolbar extends StatelessWidget {
  const _ListToolbar({required this.packs, required this.searchController});

  final PacksController packs;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: SearchBar(
          controller: searchController,
          focusNode: PageCommandScope.searchFocusOf(context),
          hintText: l10n.searchByPackName,
          leading: const Icon(Icons.search),
          elevation: const WidgetStatePropertyAll(0),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
          onChanged: packs.setQuery,
          onSubmitted: (_) => packs.search(),
          trailing: [
            FadeSwitcher(
              scale: true,
              duration: Motion.fast,
              child: packs.query.isNotEmpty
                  ? IconButton(
                      key: const ValueKey('clear'),
                      tooltip: l10n.clearSearch,
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        searchController.clear();
                        packs.setQuery('');
                        packs.search();
                      },
                    )
                  : const SizedBox.square(key: ValueKey('empty'), dimension: 40),
            ),
          ],
        ),
      ),
      const SizedBox(width: 12),
      DropdownMenu<PackSort>(
        // The selected label is only filled in on creation, so recreate the menu when the language changes.
        key: ValueKey(appLanguage),
        initialSelection: packs.sort,
        label: Text(l10n.sort),
        width: 160,
        onSelected: (value) {
          if (value != null) packs.setSort(value);
        },
        dropdownMenuEntries: [for (final sort in PackSort.values) DropdownMenuEntry(value: sort, label: sort.label)],
      ),
      const SizedBox(width: 8),
      IconButton.filledTonal(
        tooltip: packs.descending ? l10n.descending : l10n.ascending,
        onPressed: packs.toggleOrder,
        icon: AnimatedRotation(
          turns: packs.descending ? 0 : 0.5,
          duration: Motion.medium,
          curve: Motion.curve,
          child: const Icon(Icons.arrow_downward),
        ),
      ),
      const SizedBox(width: 8),
      IconButton(tooltip: l10n.refresh, onPressed: packs.search, icon: const Icon(Icons.refresh)),
    ],
  );
}

class _ListResultsHeader extends StatelessWidget {
  const _ListResultsHeader({required this.packs});

  final PacksController packs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = packs.hasSearched ? l10n.packCount(packs.total) : '';

    return Row(
      children: [
        FadeSwitcher(
          alignment: Alignment.centerLeft,
          child: Text(text, key: ValueKey(text), style: theme.textTheme.titleSmall),
        ),
        AnimatedOpacity(
          opacity: packs.isSearching ? 1 : 0,
          duration: Motion.medium,
          child: TickerMode(
            enabled: packs.isSearching,
            child: const Padding(
              padding: EdgeInsets.only(left: 12),
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.packs});

  final PacksController packs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Widget content;
    if (packs.error case final error?) {
      content = Padding(
        key: const ValueKey('error'),
        padding: const EdgeInsets.only(top: 32),
        child: EmptyState(
          icon: const Icon(Icons.cloud_off),
          title: l10n.couldntLoadPacks,
          message: error,
          action: FilledButton(onPressed: packs.search, child: Text(l10n.retry)),
        ),
      );
    } else if (packs.loadMoreError case final message?) {
      content = LoadMoreError(key: const ValueKey('more-error'), message: message, onRetry: packs.retryLoadMore);
    } else if (packs.isLoadingMore || (!packs.hasSearched && packs.isSearching)) {
      content = const Padding(
        key: ValueKey('loading'),
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (packs.hasSearched && !packs.isSearching && packs.packs.isEmpty) {
      content = Padding(
        key: const ValueKey('empty'),
        padding: const EdgeInsets.only(top: 32),
        child: EmptyState(icon: const Icon(Icons.search_off), title: l10n.noPacksFound, message: l10n.trySearchingForA),
      );
    } else if (!packs.hasMore && packs.packs.isNotEmpty && !packs.isSearching) {
      content = Padding(
        key: const ValueKey('end'),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            l10n.allPacksLoaded,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      );
    } else {
      content = const SizedBox(key: ValueKey('none'), width: double.infinity);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      child: AnimatedSize(
        duration: Motion.medium,
        curve: Motion.curve,
        alignment: Alignment.topCenter,
        child: FadeSwitcher(alignment: Alignment.topCenter, child: content),
      ),
    );
  }
}

/// One pack card: an accent bar on top and a preview of the first few levels.
class _PackCard extends StatelessWidget {
  const _PackCard({super.key, required this.pack, required this.onOpen});

  static const height = 268.0;
  static const _previewCount = 3;

  final LevelPack pack;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catalog = AppScope.of(context).levels.catalog;
    final int more = pack.levelCount - min(pack.preview.length, _previewCount);

    return HoverCard(
      onTap: onOpen,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      background: (context, hovered) => Align(
        alignment: Alignment.topCenter,
        child: _PackCardBar(pack: pack, hovered: hovered),
      ),
      child: SizedBox(
        height: height - 30,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PackIcon(url: pack.iconUrl, size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Keep it to one line and let it scroll when too long (two lines exceed the card height).
                      SizedBox(
                        height: 26,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SlideOverflow(child: slidingText(pack.name, style: theme.textTheme.titleMedium)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      _LevelCountLine(pack: pack),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _Likes(count: pack.favoritesCount),
              ],
            ),
            const SizedBox(height: 10),
            _OwnerLine(owner: pack.owner),
            const SizedBox(height: 10),
            Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 10),
            for (final level in pack.preview.take(_previewCount))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _PreviewRow(song: level.song, icon: catalog?.byId(level.diffId)?.icon),
              ),
            const Spacer(),
            if (more > 0) _MoreLevels(pack: pack, previewCount: _previewCount, more: more),
          ],
        ),
      ),
    );
  }
}

/// Levels after the titled preview: overlapping difficulty icons on one line, followed by "+N more".
///
/// - N counts every level except the titled preview (including those shown as icons).
/// - Icons fill the space up to the "+N more" text. Levels that don't fit are only counted in N.
///
/// List responses only include the first few levels, so the pack contents are fetched when the card is shown.
class _MoreLevels extends StatelessWidget {
  const _MoreLevels({required this.pack, required this.previewCount, required this.more});

  static const _iconSize = 20.0;

  /// Icon spacing, narrower than an icon so they overlap.
  static const _step = 13.0;

  /// Gap between the icons and the text.
  static const _gap = 8.0;

  /// Extra icons drawn past the available space; they fade out at the cut.
  static const _overflowIcons = 3;

  final LevelPack pack;
  final int previewCount;
  final int more;

  @override
  Widget build(BuildContext context) {
    final packs = AppScope.of(context).packs;
    final catalog = AppScope.of(context).levels.catalog;
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return SizedBox(
      height: 24,
      child: FutureBuilder<LevelPackDetail?>(
        initialData: packs.cachedDetail(pack.id),
        future: packs.detailFor(pack.id),
        builder: (context, snapshot) {
          final detail = snapshot.data;
          // Skip levels already in the preview, keeping the pack order.
          final shownIds = {for (final level in pack.preview.take(previewCount)) level.id};
          final icons = [
            if (detail != null)
              for (final entry in detail.allLevels)
                if (!shownIds.contains(entry.level.id)) catalog?.byId(entry.level.diffId)?.icon,
          ];

          final label = l10n.moreCount(more);
          return LayoutBuilder(
            builder: (context, constraints) {
              // Measure the text so the icons end right before it.
              final painter = TextPainter(
                text: TextSpan(text: label, style: textStyle),
                textDirection: TextDirection.ltr,
                textScaler: MediaQuery.textScalerOf(context),
              )..layout();
              final room = constraints.maxWidth - painter.width - _gap;
              painter.dispose();
              final fit = room < _iconSize ? 0 : ((room - _iconSize) / _step).floor() + 1;
              // Draw a little more than fits so the right edge fades out as if continuing.
              final count = min(icons.length, fit + _overflowIcons);

              return Row(
                children: [
                  // Keep the slot even without icons so they can animate in when the contents arrive.
                  _IconStrip(icons: icons.take(count).toList(), size: _iconSize, step: _step, maxWidth: max(0.0, room)),
                  // The text always sits at the right edge.
                  const Spacer(),
                  Text(label, style: textStyle),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Accent bar on top of a pack card. Becomes a progress bar while that pack (or one of its folders) downloads.
class _PackCardBar extends StatelessWidget {
  const _PackCardBar({required this.pack, required this.hovered});

  final LevelPack pack;
  final bool hovered;

  static const _height = 3.0;

  /// Slightly thicker while downloading so it stands out.
  static const _activeHeight = 4.0;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final color = Theme.of(context).colorScheme.primary;
    final download = app.packs.download;

    if (download == null || download.packId != pack.id || download.finished) {
      return AnimatedContainer(
        duration: Motion.fast,
        height: _height,
        color: color.withValues(alpha: hovered ? 1 : 0.55),
      );
    }

    // Listen to the current level's progress again when the current level changes.
    // A level's download job is created after it starts, so also listen to the downloads list.
    return ListenableBuilder(
      listenable: Listenable.merge([download, app.installs]),
      builder: (context, _) {
        final current = download.currentLevelId;
        final job = current == null ? null : app.installs.jobFor(current);
        return ListenableBuilder(
          listenable: job ?? download,
          builder: (context, _) => TweenAnimationBuilder<double>(
            tween: Tween(end: download.progress(job?.fraction ?? 0)),
            duration: Durations.short4,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: _activeHeight,
              color: color,
              backgroundColor: color.withValues(alpha: 0.2),
            ),
          ),
        );
      },
    );
  }
}

/// Overlapping difficulty icons.
///
/// Dozens of overlapping icons are expensive to draw, so they are baked into one image once ([RasterSnapshot]).
/// When the pack contents first arrive, that image wipes in from the left: only the clip
/// changes each frame, so cards appearing together while scrolling stay cheap.
/// Packs fetched earlier show their icons right away without the animation.
/// Beyond [maxWidth], the right edge fades out like other overflowing content (without moving).
class _IconStrip extends StatefulWidget {
  const _IconStrip({required this.icons, required this.size, required this.step, required this.maxWidth});

  final List<String?> icons;
  final double size;
  final double step;
  final double maxWidth;

  @override
  State<_IconStrip> createState() => _IconStripState();
}

class _IconStripState extends State<_IconStrip> with SingleTickerProviderStateMixin {
  /// Starts finished (1) if the icons were there from the start.
  /// It must be created in initState: created lazily (late), it would only be created once icons appear,
  /// wrongly conclude they were there from the start, and skip the animation.
  late final AnimationController _controller;
  late final CurvedAnimation _curved;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Durations.medium4, value: widget.icons.isEmpty ? 0 : 1);
    _curved = CurvedAnimation(parent: _controller, curve: Motion.enter);
  }

  bool _preparing = false;

  @override
  void didUpdateWidget(_IconStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animate once when icons appear after being empty.
    if (widget.icons.isNotEmpty && _controller.value == 0 && !_controller.isAnimating && !_preparing) {
      _appear();
    }
  }

  /// Starts appearing only after every icon image has loaded
  /// (animating earlier grows empty slots and then the images pop in all at once).
  Future<void> _appear() async {
    _preparing = true;
    await NetworkIcon.precache(context, widget.icons, _StackedIcon.iconSize(widget.size));
    _preparing = false;
    if (!mounted) return;
    await _controller.forward().orCancel.catchError((_) {});
  }

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icons = widget.icons;
    if (icons.isEmpty) return const SizedBox.shrink();

    final full = widget.size + (icons.length - 1) * widget.step;

    // The animation lives outside the baked image, so the image is drawn once and only reclipped.
    // (A fade would need an extra layer per card every frame, which costs more than the clip.)
    return ClipRect(
      clipper: _WipeClipper(_curved),
      child: RasterSnapshot(
        child: SizedBox(
          // Takes only what it needs, or the available width when overflowing. FadeEdges fades the overflowing end.
          width: min(full, widget.maxWidth),
          height: widget.size,
          child: FadeEdges(
            child: SizedBox(
              width: full,
              height: widget.size,
              child: Stack(
                children: [
                  for (var i = 0; i < icons.length; i++)
                    Positioned(
                      left: i * widget.step,
                      child: _StackedIcon(url: icons[i], size: widget.size),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the left [progress] fraction of its child.
class _WipeClipper extends CustomClipper<Rect> {
  _WipeClipper(this.progress) : super(reclip: progress);

  final Animation<double> progress;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * progress.value, size.height);

  @override
  bool shouldReclip(_WipeClipper oldClipper) => oldClipper.progress != progress;
}

/// One overlapping icon, ringed in the card color to separate it from the icon behind.
class _StackedIcon extends StatelessWidget {
  const _StackedIcon({required this.url, required this.size});

  /// Icon size without the ring. Precaching must use the same size to hit the same cached image.
  static double iconSize(double size) => size - 3;

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final back = Theme.of(context).colorScheme.surfaceContainerLow;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: back,
        border: Border.all(color: back, width: 1.5),
      ),
      child: NetworkIcon(url, size: iconSize(size)),
    );
  }
}

class _LevelCountLine extends StatelessWidget {
  const _LevelCountLine({required this.pack});

  final LevelPack pack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Text(l10n.levelCount(pack.levelCount), style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
        if (pack.isPinned) ...[
          const SizedBox(width: 6),
          HoverTip(
            message: l10n.pinnedPack,
            child: _PinIcon(Icons.push_pin_outlined, size: 16, color: muted),
          ),
        ],
      ],
    );
  }
}

class _Likes extends StatelessWidget {
  const _Likes({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) =>
      InfoChip(icon: Icons.favorite_border, label: formatNumber(count), tip: l10n.likeCount(count));
}

class _OwnerLine extends StatelessWidget {
  const _OwnerLine({required this.owner});

  final PackOwner? owner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = owner?.name ?? l10n.unknown;
    return Row(
      children: [
        _Avatar(url: owner?.avatarUrl, size: 26),
        const SizedBox(width: 8),
        Expanded(
          child: SlideOverflow(child: slidingText(name, style: theme.textTheme.bodyMedium)),
        ),
      ],
    );
  }
}

/// Preview row: difficulty icon and song name.
class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.song, required this.icon});

  final String song;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          NetworkIcon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: SlideOverflow(child: slidingText(song, style: theme.textTheme.bodySmall)),
          ),
        ],
      ),
    );
  }
}

/// Pack icon, or a box placeholder.
class _PackIcon extends StatelessWidget {
  const _PackIcon({required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size >= 96 ? 16 : 8),
      child: Container(
        width: size,
        height: size,
        color: colors.surfaceContainerHighest,
        child: url == null
            ? Icon(Icons.inventory_2_outlined, size: size * 0.5, color: colors.onSurfaceVariant)
            : NetworkIcon(url, size: size),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: colors.surfaceContainerHighest,
        child: url == null
            ? Icon(Icons.person, size: size * 0.7, color: colors.onSurfaceVariant)
            : NetworkIcon(url, size: size),
      ),
    );
  }
}

// ───────────────────────── Pack contents ─────────────────────────

/// The folder tree flattened into rows.
///
/// Rows of a collapsed folder are only in the list while they animate closed ([closing]); keeping
/// thousands of empty rows would make the list guess its length wrong and the scrollbar jump.
/// Rows of a folder that just opened ([opening]) start hidden for one frame so they animate open.
sealed class _Row {
  const _Row(this.depth, {required this.visible});

  final int depth;
  final bool visible;
}

class _FolderRow extends _Row {
  const _FolderRow(this.folder, super.depth, {required super.visible});

  final PackFolder folder;
}

class _LevelRow extends _Row {
  const _LevelRow(this.entry, super.depth, {required super.visible});

  final PackLevelEntry entry;
}

/// Only the first [_animatedRows] rows inside folders that are opening ([growing]) or closing animate, counted
/// across all of them (Expand all opens dozens at once); the rest are left out until they have opened, and
/// dropped as soon as they start closing. Animating them all would build every one of them in a single frame:
/// rows start at zero height, so the list keeps building rows to fill the screen.
List<_Row> _flatten(
  List<PackNode> nodes, {
  required Set<int> expanded,
  required Set<int> closing,
  required Set<int> opening,
  required Set<int> growing,
}) => _flattenInto(
  [],
  nodes,
  expanded: expanded,
  closing: closing,
  opening: opening,
  growing: growing,
  budget: _AnimatedRows(),
  depth: 0,
  visible: true,
  animating: false,
);

List<_Row> _flattenInto(
  List<_Row> rows,
  List<PackNode> nodes, {
  required Set<int> expanded,
  required Set<int> closing,
  required Set<int> opening,
  required Set<int> growing,
  required _AnimatedRows budget,
  required int depth,
  required bool visible,
  required bool animating,
}) {
  for (final node in nodes) {
    if (animating) {
      if (budget.left == 0) break;
      budget.left--;
    }
    switch (node) {
      case PackLevelEntry():
        rows.add(_LevelRow(node, depth, visible: visible));
      case PackFolder():
        rows.add(_FolderRow(node, depth, visible: visible));
        final open = expanded.contains(node.id);
        final closes = closing.contains(node.id);
        if (!open && !closes) continue;
        _flattenInto(
          rows,
          node.children,
          expanded: expanded,
          closing: closing,
          opening: opening,
          growing: growing,
          budget: budget,
          depth: depth + 1,
          visible: visible && open && !opening.contains(node.id),
          animating: animating || closes || growing.contains(node.id),
        );
    }
  }
  return rows;
}

/// How many rows animate when folders open or close. More than fit on screen.
const _animatedRows = 24;

/// Rows left to animate in the folders being opened or closed.
class _AnimatedRows {
  int left = _animatedRows;
}

class _PackDetailView extends StatefulWidget {
  const _PackDetailView({super.key, required this.packs});

  final PacksController packs;

  @override
  State<_PackDetailView> createState() => _PackDetailViewState();
}

class _PackDetailViewState extends State<_PackDetailView> {
  /// Indent per folder level.
  static const _indent = 28.0;

  final _scroll = SmoothScrollController();

  /// Expanded folders as of the last change, to tell which folders just opened or closed.
  late Set<int> _expanded;

  /// Folders whose rows are still animating closed, folders whose rows wait one frame before animating open,
  /// and folders still animating open.
  final _closing = <int>{};
  final _opening = <int>{};
  final _growing = <int>{};

  @override
  void initState() {
    super.initState();
    // Copied now: a lazy initializer would only run on the first change, after it already happened.
    _expanded = {...widget.packs.expanded};
    widget.packs.addListener(_onPacksChanged);
  }

  @override
  void dispose() {
    widget.packs.removeListener(_onPacksChanged);
    _scroll.dispose();
    super.dispose();
  }

  void _onPacksChanged() {
    final now = widget.packs.expanded;
    final opened = now.difference(_expanded);
    final closed = _expanded.difference(now);
    _expanded = {...now};
    if (opened.isEmpty && closed.isEmpty) return;

    setState(() {
      _opening
        ..addAll(opened)
        ..removeAll(closed);
      _growing
        ..addAll(opened)
        ..removeAll(closed);
      _closing
        ..addAll(closed)
        ..removeAll(opened);
    });
    if (opened.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _opening.removeAll(opened));
      });
    }
    // A little longer than the animation, which starts on the next frame.
    Timer(Motion.medium + const Duration(milliseconds: 50), () {
      if (!mounted) return;
      setState(() {
        // Then the rest of an opened folder's rows join, and a closed folder's rows leave
        // (unless it was toggled again meanwhile).
        _growing.removeAll(opened.intersection(widget.packs.expanded));
        _closing.removeAll(closed.difference(widget.packs.expanded));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final packs = widget.packs;
    final pack = packs.openedPack!;
    final detail = packs.detail;

    return PageCommandScope(
      commands: () => PageCommands(scroll: _scroll, refresh: packs.reloadDetail, searchable: false),
      child: ListenableBuilder(
        // The count on the Download button changes when downloaded levels change.
        listenable: app.installs,
        builder: (context, _) {
          final rows = detail == null
              ? const <_Row>[]
              : _flatten(
                  detail.items,
                  expanded: packs.expanded,
                  closing: _closing,
                  opening: _opening,
                  growing: _growing,
                );

          return ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SmoothScrollbar(
              controller: _scroll,
              builder: (context, behavior) => CustomScrollView(
                controller: _scroll,
                scrollBehavior: behavior,
                slivers: [
                  _section(
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: packs.close,
                          icon: const Icon(Icons.arrow_back),
                          label: Text(l10n.allPacks),
                        ),
                      ),
                    ),
                  ),
                  _section(
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _DetailHeader(packs: packs, pack: pack, detail: detail),
                    ),
                  ),
                  if (detail != null)
                    _section(
                      Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 12),
                        child: _ItemsHeader(packs: packs, detail: detail),
                      ),
                    ),
                  SliverList.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      return Reveal(
                        key: ValueKey(_keyOf(row)),
                        visible: row.visible,
                        duration: Motion.medium,
                        child: _constrain(
                          Padding(
                            padding: EdgeInsets.only(left: row.depth * _indent, bottom: 8),
                            child: switch (row) {
                              _FolderRow(:final folder) => _FolderHeader(packs: packs, pack: pack, folder: folder),
                              _LevelRow(:final entry) => LevelCard(level: entry.level, compact: app.levels.compact),
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  _section(_DetailFooter(packs: packs)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static Object _keyOf(_Row row) => switch (row) {
    _FolderRow(:final folder) => ('folder', folder.id),
    _LevelRow(:final entry) => ('level', entry.id),
  };
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.packs, required this.pack, required this.detail});

  final PacksController packs;
  final LevelPack pack;
  final LevelPackDetail? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final detail = this.detail;
    final toDownload = detail == null ? const <PackDownloadItem>[] : packs.downloadItems(pack, detail.items);

    // A rounded box can't have a border on one side only, so the top accent bar is drawn on top.
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: theme.colorScheme.surfaceContainerLow,
        foregroundDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.colorScheme.primary, width: 3)),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _PackIcon(url: pack.iconUrl, size: 96),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: SlideOverflow(child: slidingText(pack.name, style: theme.textTheme.headlineSmall)),
                      ),
                      if (pack.isPinned) ...[
                        const SizedBox(width: 8),
                        HoverTip(
                          message: l10n.pinnedPack,
                          child: _PinIcon(Icons.push_pin_outlined, color: muted),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _Avatar(url: pack.owner?.avatarUrl, size: 24),
                      const SizedBox(width: 8),
                      Flexible(
                        child: SlideOverflow(
                          child: slidingText(pack.owner?.name ?? l10n.unknown, style: theme.textTheme.bodyMedium),
                        ),
                      ),
                      const SizedBox(width: 16),
                      InfoChip(icon: Icons.library_music_outlined, label: l10n.levelCount(pack.levelCount)),
                      const SizedBox(width: 6),
                      InfoChip(
                        icon: Icons.favorite_border,
                        label: formatNumber(pack.favoritesCount),
                        tip: l10n.likeCount(pack.favoritesCount),
                      ),
                    ],
                  ),
                  if (pack.description case final description? when description.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      description.trim(),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            _PackDownloadButton(
              packs: packs,
              scope: pack.id,
              label: pack.name,
              items: toDownload,
              idleText: detail == null ? l10n.downloadPack : l10n.downloadPackCount(toDownload.length),
              filled: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemsHeader extends StatelessWidget {
  const _ItemsHeader({required this.packs, required this.detail});

  final PacksController packs;
  final LevelPackDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFolders = detail.items.any((node) => node is PackFolder);
    final allExpanded = packs.allExpanded;

    return Row(
      children: [
        Text(l10n.items, style: theme.textTheme.titleLarge),
        const Spacer(),
        if (hasFolders)
          TextButton.icon(
            onPressed: () => packs.setAllExpanded(!allExpanded),
            icon: Icon(allExpanded ? Icons.unfold_less : Icons.unfold_more),
            label: Text(allExpanded ? l10n.collapseAll : l10n.expandAll),
          ),
      ],
    );
  }
}

/// Folder row. Tapping expands or collapses it; the folder can also be downloaded as a whole.
class _FolderHeader extends StatelessWidget {
  const _FolderHeader({required this.packs, required this.pack, required this.folder});

  final PacksController packs;
  final LevelPack pack;
  final PackFolder folder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final open = packs.expanded.contains(folder.id);
    final levelCount = folder.allLevels.length;
    final toDownload = packs.downloadItems(pack, [folder], path: packs.folderPathOf(folder));

    return HoverCard(
      onTap: () => packs.toggleFolder(folder.id),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          AnimatedRotation(
            turns: open ? 0 : -0.25,
            duration: Motion.medium,
            curve: Motion.curve,
            child: Icon(Icons.expand_more, color: muted),
          ),
          const SizedBox(width: 8),
          Icon(open ? Icons.folder_open : Icons.folder, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SlideOverflow(child: slidingText(folder.name, style: theme.textTheme.titleMedium)),
                Text(
                  l10n.itemAndLevelCount(folder.children.length, levelCount),
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _PackDownloadButton(
            packs: packs,
            scope: folder.id,
            label: folder.name,
            items: toDownload,
            idleText: l10n.downloadFolderCount(toDownload.length),
            filled: false,
            doneText: levelCount == 0 ? l10n.emptyFolder : l10n.allDownloaded,
          ),
        ],
      ),
    );
  }
}

/// Before downloading several levels, tells where they go and how many there are.
Future<void> _confirmDownload(
  BuildContext context,
  PacksController packs,
  Object scope,
  String label,
  List<PackDownloadItem> items,
) async {
  final folder = items.first.folder;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.downloadNamed(label)),
      content: Text(l10n.downloadPackExplanation(items.length, folder.split('/').first)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.download)),
      ],
    ),
  );
  if (ok ?? false) await packs.startDownload(scope, label, items);
}

/// Pack/folder download button. While downloading it turns into progress in place, like level download buttons.
class _PackDownloadButton extends StatelessWidget {
  const _PackDownloadButton({
    required this.packs,
    required this.scope,
    required this.label,
    required this.items,
    required this.idleText,
    required this.filled,
    this.doneText,
  });

  /// The button and its progress share a width so neighbors don't shift.
  static const width = 200.0;

  final PacksController packs;
  final Object scope;
  final String label;
  final List<PackDownloadItem> items;
  final String idleText;
  final bool filled;

  /// Text shown when there is nothing to download; "All downloaded" if null.
  final String? doneText;

  @override
  Widget build(BuildContext context) {
    final download = packs.download;
    // While a pack downloads, folder buttons inside it show their own share of the progress.
    final active = download != null && download.isActiveFor(scope);

    return SizedBox(
      width: width,
      child: FadeSwitcher(
        duration: Motion.fast,
        alignment: Alignment.centerRight,
        child: active ? _progress(context, download) : _button(context),
      ),
    );
  }

  Widget _button(BuildContext context) {
    final onPressed = packs.isDownloading || items.isEmpty
        ? null
        : () => _confirmDownload(context, packs, scope, label, items);
    final text = Text(
      items.isEmpty ? doneText ?? l10n.allDownloaded : idleText,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final icon = Icon(items.isEmpty ? Icons.check : Icons.download, size: 18);

    return filled
        ? FilledButton.icon(key: const ValueKey('button'), onPressed: onPressed, icon: icon, label: text)
        : OutlinedButton.icon(key: const ValueKey('button'), onPressed: onPressed, icon: icon, label: text);
  }

  Widget _progress(BuildContext context, PackDownload download) {
    final theme = Theme.of(context);
    final job = download.currentLevelId == null ? null : AppScope.of(context).installs.jobFor(download.currentLevelId!);

    return ListenableBuilder(
      key: const ValueKey('progress'),
      listenable: Listenable.merge([download, ?job]),
      builder: (context, _) {
        // Count only this button's levels (for a folder button, those inside it).
        final ids = download.levelsFor(scope) ?? const <int>[];
        final total = max(1, ids.length);
        final finished = ids.where(download.finishedIds.contains).length;
        final failedCount = ids.where(download.failedIds.contains).length;
        final isCurrent = ids.contains(download.currentLevelId);

        // Include the current level's progress so the bar doesn't jump in steps.
        final current = isCurrent ? (job?.fraction ?? 0) : 0.0;
        final value = ((finished + current) / total).clamp(0.0, 1.0);
        final failed = failedCount > 0 ? l10n.failedCountSuffix(failedCount) : '';
        final state = isCurrent ? job?.shortText ?? l10n.preparing : l10n.waiting;

        return Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: value),
                    duration: Durations.short4,
                    builder: (context, value, _) => LinearProgressIndicator(value: value),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    download.cancelled ? l10n.stopping : '$finished/${ids.length}$failed · $state',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.stop,
              visualDensity: VisualDensity.compact,
              onPressed: download.cancelled ? null : packs.cancelDownload,
              icon: const Icon(Icons.close),
            ),
          ],
        );
      },
    );
  }
}

class _DetailFooter extends StatelessWidget {
  const _DetailFooter({required this.packs});

  final PacksController packs;

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (packs.detailError case final error?) {
      content = Padding(
        key: const ValueKey('error'),
        padding: const EdgeInsets.only(top: 32),
        child: EmptyState(
          icon: const Icon(Icons.cloud_off),
          title: l10n.couldntLoadThePack,
          message: error,
          action: FilledButton(onPressed: packs.reloadDetail, child: Text(l10n.retry)),
        ),
      );
    } else if (packs.isLoadingDetail) {
      content = const Padding(
        key: ValueKey('loading'),
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (packs.detail?.items.isEmpty ?? false) {
      content = Padding(
        key: const ValueKey('empty'),
        padding: const EdgeInsets.only(top: 32),
        child: EmptyState(icon: const Icon(Icons.inventory_2_outlined), title: l10n.thisPackIsEmpty),
      );
    } else {
      content = const SizedBox(key: ValueKey('none'), width: double.infinity);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: FadeSwitcher(alignment: Alignment.topCenter, child: content),
    );
  }
}

/// Pinned pack marker. Upright it reads like a letter at small sizes, so it is tilted like on the website.
class _PinIcon extends StatelessWidget {
  const _PinIcon(this.icon, {this.size, this.color});

  final IconData icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: 0.6,
    child: Icon(icon, size: size, color: color),
  );
}
