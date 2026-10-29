import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/controllers.dart';
import '../../core/image_cache_store.dart';
import '../../core/l10n.dart';
import '../../core/models/level.dart';
import '../../core/models/pass.dart';
import '../../core/tuf_api_client.dart';
import '../widgets/common.dart';
import '../widgets/embedded_video.dart';
import '../widgets/side_by_side.dart';
import '../widgets/hover_tip.dart';
import '../widgets/level_card.dart';
import '../widgets/level_info_dialog.dart';
import 'pass_viewer_page.dart';
import 'profile/profile_navigation.dart';
import '../widgets/motion.dart';
import '../widgets/pass_row.dart';
import '../widgets/slide_overflow.dart';
import '../widgets/smooth_scroll.dart';
import '../app_shortcuts.dart';

/// Level details: card, pass summary, video and leaderboard.
/// Opens on top when a level card is tapped in a list or pack.
class LevelViewerPage extends StatefulWidget {
  const LevelViewerPage({super.key, required this.level});

  final Level level;

  static Future<void> open(BuildContext context, Level level) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => LevelViewerPage(level: level)));

  @override
  State<LevelViewerPage> createState() => _LevelViewerPageState();
}

class _LevelViewerPageState extends State<LevelViewerPage> {
  static const _maxWidth = pageMaxWidth;

  final _scroll = SmoothScrollController();

  late Level _level = widget.level;
  LevelPassSummary? _summary;
  bool _loading = true;
  String? _error;

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // AppScope can't be read in initState. Load only once.
    if (_started) return;
    _started = true;
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final api = AppScope.of(context).api;
    // Levels from packs carry partial info, so fetch the level again. On failure, keep showing the list info.
    unawaited(_refreshLevel(api));

    try {
      final passes = await api.getLevelPasses(_level.id);
      if (!mounted) return;
      setState(() {
        _summary = LevelPassSummary.of(passes);
        _loading = false;
      });
    } on Object catch (e) {
      // Unexpected errors too, so the leaderboard never stays loading forever.
      if (!mounted) return;
      setState(() {
        _error = e is TufApiException ? e.message : '$e';
        _loading = false;
      });
    }
  }

  Future<void> _refreshLevel(TufApiClient api) async {
    try {
      final full = await api.getLevel(_level.id);
      if (mounted) setState(() => _level = full);
    } on Object {
      // The card already has what it needs.
    }
  }

  Widget _section(Widget child) => SliverToBoxAdapter(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: SizedBox(
          width: double.infinity,
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: child),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return PageCommandScope(
      commands: () => PageCommands(scroll: _scroll, refresh: _load, searchable: false),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: l10n.back,
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text('#${_level.id}'),
        ),
        body: SmoothScrollbar(
          controller: _scroll,
          builder: (context, behavior) => CustomScrollView(
            controller: _scroll,
            scrollBehavior: behavior,
            slivers: [
              _section(
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: LevelCard(level: _level, compact: false, openable: false),
                ),
              ),
              _section(
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _Overview(level: _level, summary: summary),
                ),
              ),
              _section(
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 12),
                  child: Row(
                    children: [
                      Text(l10n.leaderboard, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(width: 12),
                      if (summary != null)
                        Text(
                          l10n.uniquePlayerCount(summary.uniquePlayers) +
                              (summary.totalClears != summary.uniquePlayers
                                  ? l10n.totalClearsSuffix(summary.totalClears)
                                  : ''),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      const Spacer(),
                      IconButton(tooltip: l10n.refresh, onPressed: _load, icon: const Icon(Icons.refresh)),
                    ],
                  ),
                ),
              ),
              if (summary != null)
                SliverList.builder(
                  itemCount: summary.leaderboard.length,
                  itemBuilder: (context, index) => Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: _maxWidth),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                        child: _PassRow(level: _level, rank: index + 1, pass: summary.leaderboard[index]),
                      ),
                    ),
                  ),
                ),
              _section(_Footer(loading: _loading, error: _error, summary: summary, onRetry: _load)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.loading, required this.error, required this.summary, required this.onRetry});

  final bool loading;
  final String? error;
  final LevelPassSummary? summary;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (error case final message?) {
      content = Padding(
        key: const ValueKey('error'),
        padding: const EdgeInsets.only(top: 32),
        child: EmptyState(
          icon: const Icon(Icons.cloud_off),
          title: l10n.couldntLoadPasses,
          message: message,
          action: FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
        ),
      );
    } else if (loading) {
      content = const Padding(
        key: ValueKey('loading'),
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (summary?.passes.isEmpty ?? false) {
      content = Padding(
        key: const ValueKey('empty'),
        padding: const EdgeInsets.only(top: 32),
        child: EmptyState(icon: const Icon(Icons.flag_outlined), title: l10n.noPassesYet),
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

/// Gap between the left column and the video on the right, shared by the detail pages.
const sideGap = 16.0;

/// Key of the video box (found by size tests).
const videoKey = ValueKey('video');

/// Pass summary on the left, video on the right.
class _Overview extends StatelessWidget {
  const _Overview({required this.level, required this.summary});

  final Level level;
  final LevelPassSummary? summary;

  @override
  Widget build(BuildContext context) {
    final video = level.videoLink;
    if (video == null) return _Records(level: level, summary: summary);

    // The video fills the right column and the summary on the left stretches to its height.
    return SideBySide(
      gap: sideGap,
      left: _Records(level: level, summary: summary),
      right: (context, videoHeight) => SizedBox(
        key: videoKey,
        height: videoHeight,
        child: _VideoPreview(videoLink: video, title: level.song),
      ),
    );
  }
}

class _Records extends StatelessWidget {
  const _Records({required this.level, required this.summary});

  final Level level;
  final LevelPassSummary? summary;

  @override
  Widget build(BuildContext context) {
    final summary = this.summary;
    final best = summary?.bestScore;
    final speed = summary?.bestSpeed;
    final accuracy = summary?.bestAccuracy;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          // Spread the rows to fill the column (matching the video's height).
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _RecordRow(
              label: l10n.firstClear,
              who: summary?.firstClear?.playerName,
              value: formatDate(summary?.firstClear?.clearedAt),
              last: true,
            ),
            _RecordRow(
              label: l10n.highestScore,
              who: best?.playerName,
              value: best == null ? null : formatScore(best.score),
              last: true,
            ),
            _RecordRow(
              label: l10n.highestSpeed,
              who: speed?.playerName,
              value: speed == null ? null : '${formatSpeed(speed.speed)}x',
              last: true,
            ),
            _RecordRow(
              label: l10n.highestAccuracy,
              who: accuracy?.playerName,
              value: accuracy == null ? null : formatAccuracy(accuracy.accuracy),
              last: true,
            ),
            _RecordRow(
              label: l10n.totalClears,
              value: summary == null
                  ? null
                  : '${formatNumber(summary.uniquePlayers)}'
                        '${summary.totalClears != summary.uniquePlayers ? ' (${formatNumber(summary.totalClears)})' : ''}',
              last: true,
            ),
            // Like the website, the rest of the info opens in a dialog.
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => LevelInfoDialog.show(context, level),
                icon: const Icon(Icons.info_outline),
                label: Text(l10n.fullInfo),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One "Highest score  [Jipper | 67016.00]" row, left empty while unknown.
class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.label, this.who, this.value, this.last = false});

  final String label;
  final String? who;
  final String? value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final who = this.who;
    final value = this.value;
    final style = theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSecondaryContainer);

    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FadeSwitcher(
                alignment: Alignment.centerRight,
                child: who == null && value == null
                    ? const SizedBox(key: ValueKey('empty'), height: 32)
                    : Container(
                        key: ValueKey('$who|$value'),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Long names scroll on their own; the record (date, score, ...) always stays visible.
                            if (who != null)
                              Flexible(
                                child: SlideOverflow(child: slidingText(who, style: style)),
                              ),
                            if (who != null && value != null) Text('  |  ', style: style),
                            if (value != null) Text(value, maxLines: 1, softWrap: false, style: style),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Video preview. Like the website, the player is embedded right away.
/// If it can't be embedded (no WebView2, or not YouTube/Bilibili/Douyin), a thumbnail opens the video in the browser.
class _VideoPreview extends StatefulWidget {
  const _VideoPreview({required this.videoLink, required this.title});

  final String videoLink;
  final String title;

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    final embed = !_failed && EmbeddedVideo.canPlay(widget.videoLink);

    // Sized by the parent's 16:9 box.
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.expand(
        child: embed
            ? ColoredBox(
                color: Colors.black,
                child: EmbeddedVideo(
                  videoLink: widget.videoLink,
                  onUnavailable: () {
                    if (mounted) setState(() => _failed = true);
                  },
                ),
              )
            : _Thumbnail(videoLink: widget.videoLink, title: widget.title),
      ),
    );
  }
}

/// Thumbnail shown when the player can't be embedded. Tapping opens the browser.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.videoLink, required this.title});

  final String videoLink;
  final String title;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);

    return HoverCard(
      padding: EdgeInsets.zero,
      onTap: () => app.openLink(videoLink),
      child: FutureBuilder<String?>(
        future: app.thumbnails.resolve(videoLink),
        initialData: app.thumbnails.peek(videoLink),
        builder: (context, snapshot) => Stack(
          fit: StackFit.expand,
          children: [
            if (snapshot.data case final url?)
              Image(image: DiskCachedImage(url, maxWidth: 640), fit: BoxFit.cover, gaplessPlayback: true),
            // Darken the bottom so the icon stays visible over the thumbnail.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.1), Colors.black.withValues(alpha: 0.6)],
                ),
              ),
            ),
            Center(child: Icon(Icons.play_circle_fill, size: 56, color: Colors.white.withValues(alpha: 0.9))),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: SlideOverflow(
                child: slidingText(title, style: theme.textTheme.labelLarge?.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One leaderboard row with rank, avatar, name and judgements like the website ([PassRow] layout).
class _PassRow extends StatelessWidget {
  const _PassRow({required this.level, required this.rank, required this.pass});

  final Level level;
  final int rank;
  final LevelPass pass;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final feeling = pass.feelingRating;
    void openPlayer() => ProfileNavigation.openPlayer(context, pass.playerId);

    return PassRow(
      pass: pass,
      onTap: () => PassViewerPage.open(context, level: level, pass: pass),
      // The avatar and name open the player page (the rest of the row opens the pass).
      leading: HoverTip(
        message: l10n.viewPlayerProfile,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: openPlayer,
          child: Center(
            child: _PlayerAvatar(url: pass.playerAvatar, fallback: pass.playerAvatarFallback, size: 48),
          ),
        ),
      ),
      top: feeling == null || feeling.isEmpty ? null : l10n.feeling(feeling),
      title: HoverTip(
        message: l10n.viewPlayerProfile,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: openPlayer,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SlideOverflow(child: slidingText(pass.playerName, style: theme.textTheme.titleMedium)),
              ),
              if (pass.country != null) ...[const SizedBox(width: 8), CountryFlag(country: pass.country, height: 14)],
            ],
          ),
        ),
      ),
      showJudgements: true,
      rank: rank,
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  const _PlayerAvatar({required this.url, required this.size, this.fallback});

  final String? url;
  final String? fallback;
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
            : NetworkIcon(url, size: size, fallback: fallback),
      ),
    );
  }
}
