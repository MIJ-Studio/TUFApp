import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/controllers.dart';
import '../../core/l10n.dart';
import '../../core/library_organizer.dart';
import '../widgets/common.dart';
import '../widgets/hover_tip.dart';
import '../widgets/motion.dart';
import '../widgets/slide_overflow.dart';
import '../widgets/smooth_scroll.dart';
import '../app_shortcuts.dart';

/// Content always fills the width inside the centered max width.
Widget _constrain(Widget child) => Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: pageMaxWidth),
    child: SizedBox(
      width: double.infinity,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: child),
    ),
  ),
);

Widget _section(Widget child) => SliverToBoxAdapter(child: _constrain(child));

/// Manages downloaded levels by folder, like Windows Explorer.
///
/// - Click to select (Ctrl toggles, Shift selects a range), double-click to open
/// - Drag onto a folder or the path to move
/// - Context menu, F2 (rename) / Delete / Backspace (up) / Ctrl+A (select all) / Esc (deselect)
/// - ↑/↓/Home/End select an entry (Shift extends the range), Enter opens it
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final _scroll = SmoothScrollController();
  final _focus = FocusNode(debugLabel: 'library');

  /// Entries already shown; only new ones get the entrance animation.
  final _shownPaths = <String>{};

  @override
  void dispose() {
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(LibraryController library, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final selected = library.selectedEntries;
    final control = HardwareKeyboard.instance.isControlPressed;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
        library.clearSelection();
      case LogicalKeyboardKey.backspace:
        library.goUp();
      case LogicalKeyboardKey.keyA when control:
        library.selectAll();
      case LogicalKeyboardKey.f2 when selected.length == 1:
        _rename(context, library, selected.single);
      case LogicalKeyboardKey.delete when selected.isNotEmpty:
        _deleteMany(context, library, selected);
      case LogicalKeyboardKey.enter when selected.length == 1:
        _open(library, selected.single);
      case LogicalKeyboardKey.arrowUp ||
              LogicalKeyboardKey.arrowDown ||
              LogicalKeyboardKey.home ||
              LogicalKeyboardKey.end
          when !control:
        _moveCursor(library, event.logicalKey);
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  /// Arrow keys and Home/End select the next entry like Explorer; with Shift they extend the range.
  void _moveCursor(LibraryController library, LogicalKeyboardKey key) {
    final entries = library.entries;
    if (entries.isEmpty) return;
    final current = entries.indexWhere((entry) => entry.relativePath == library.selectionCursor);
    final index = switch (key) {
      LogicalKeyboardKey.home => 0,
      LogicalKeyboardKey.end => entries.length - 1,
      LogicalKeyboardKey.arrowUp => current < 0 ? entries.length - 1 : current - 1,
      _ => current + 1,
    }.clamp(0, entries.length - 1);
    library.select(entries[index], range: HardwareKeyboard.instance.isShiftPressed);

    // Rows far away aren't built yet, so they can't scroll themselves into view.
    if (key == LogicalKeyboardKey.home) _scroll.glideTo(0);
    if (key == LogicalKeyboardKey.end && _scroll.hasClients) _scroll.glideTo(_scroll.position.maxScrollExtent);
  }

  /// Scrolls just enough to show a row that became the selection cursor, clear of the floating selection bar.
  void _reveal(BuildContext row) {
    final box = row.findRenderObject();
    final viewport = _scroll.hasClients ? _scroll.position.context.notificationContext?.findRenderObject() : null;
    if (box is! RenderBox || viewport is! RenderBox || !box.attached) return;
    final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
    final bottom = top + box.size.height;
    final visibleBottom = viewport.size.height - _selectionBarSpace;
    if (top < 0) {
      _scroll.glideBy(top - 8);
    } else if (bottom > visibleBottom) {
      _scroll.glideBy(bottom - visibleBottom + 8);
    }
  }

  /// Height the floating selection bar covers at the bottom of the list.
  static const _selectionBarSpace = 88.0;

  void _open(LibraryController library, LibraryEntry entry) {
    if (entry is FolderEntry) {
      library.openPath(entry.relativePath);
    } else {
      library.openFolderPath(entry.relativePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final library = app.library;

    return PageCommandScope(
      commands: () => PageCommands(scroll: _scroll, refresh: library.refreshContents, searchable: false),
      child: ListenableBuilder(
        // app.levels notifies on every search, so it isn't listened to here.
        listenable: Listenable.merge([library, app.installs]),
        builder: (context, _) {
          final entries = library.entries;
          final firstShow = _shownPaths.isEmpty;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _shownPaths
              ..clear()
              ..addAll(entries.map((entry) => entry.relativePath));
          });

          return Focus(
            focusNode: _focus,
            onKeyEvent: (node, event) => _onKey(library, event),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              // Clicking empty space clears the selection and gives this page keyboard focus.
              onTap: () {
                _focus.requestFocus();
                library.clearSelection();
              },
              onSecondaryTapUp: (details) => _showFolderMenu(context, library, details.globalPosition),
              child: Stack(
                children: [
                  SmoothScrollbar(
                    controller: _scroll,
                    builder: (context, behavior) => CustomScrollView(
                      controller: _scroll,
                      scrollBehavior: behavior,
                      slivers: [
                        _section(
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: _Header(library: library),
                          ),
                        ),
                        _section(
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: _Toolbar(library: library),
                          ),
                        ),
                        _section(const SizedBox(height: 12)),
                        _section(
                          Reveal(
                            visible: library.contents?.isEmpty ?? false,
                            child: _EmptyFolder(
                              atRoot: library.currentPath.isEmpty,
                              onBrowse: () => app.setPage(AppPage.levels),
                              onCreateFolder: () => _createFolder(context, library),
                            ),
                          ),
                        ),
                        SliverList.builder(
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            return _constrain(
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Appear(
                                  key: ValueKey(entry.relativePath),
                                  animate: !_shownPaths.contains(entry.relativePath),
                                  delay: firstShow ? Duration(milliseconds: 30 * index.clamp(0, 10)) : Duration.zero,
                                  child: _EntryRow(
                                    entry: entry,
                                    library: library,
                                    focus: _focus,
                                    onOpen: () => _open(library, entry),
                                    onBecameCursor: _reveal,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Leave room so the floating selection bar doesn't cover the last entry.
                        _section(const SizedBox(height: _selectionBarSpace)),
                      ],
                    ),
                  ),
                  // Floats over the list so entries don't shift when it appears or disappears.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 16,
                    child: ValueListenableBuilder(
                      valueListenable: library.selectionRevision,
                      builder: (context, _, _) => _FloatingSelectionBar(
                        visible: library.selection.isNotEmpty,
                        child: _constrain(_SelectionBar(library: library)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ───────────────────────── Entry row ─────────────────────────

/// A row with selection, dragging and a context menu. Folders also accept drops.
class _EntryRow extends StatefulWidget {
  const _EntryRow({
    required this.entry,
    required this.library,
    required this.focus,
    required this.onOpen,
    required this.onBecameCursor,
  });

  final LibraryEntry entry;
  final LibraryController library;
  final FocusNode focus;
  final VoidCallback onOpen;

  /// Called with this row's context when it becomes the selection cursor, to scroll it into view.
  final void Function(BuildContext row) onBecameCursor;

  @override
  State<_EntryRow> createState() => _EntryRowState();
}

class _EntryRowState extends State<_EntryRow> {
  bool _dropTarget = false;

  bool get _selected => widget.library.selection.contains(widget.entry.relativePath);

  /// Selection state at the last build.
  late bool _wasSelected = _selected;

  /// Whether this row was the selection cursor at the last selection change.
  late bool _wasCursor = widget.library.selectionCursor == widget.entry.relativePath;

  @override
  void initState() {
    super.initState();
    widget.library.selectionRevision.addListener(_onSelectionChanged);
  }

  @override
  void didUpdateWidget(_EntryRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.library != widget.library) {
      oldWidget.library.selectionRevision.removeListener(_onSelectionChanged);
      widget.library.selectionRevision.addListener(_onSelectionChanged);
    }
  }

  @override
  void dispose() {
    widget.library.selectionRevision.removeListener(_onSelectionChanged);
    super.dispose();
  }

  /// Rebuilds only rows whose selection changed instead of the whole page.
  /// Selected rows also rebuild because the group they drag changes.
  void _onSelectionChanged() {
    final cursor = widget.library.selectionCursor == widget.entry.relativePath;
    if (cursor && !_wasCursor) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onBecameCursor(context);
      });
    }
    _wasCursor = cursor;

    final selected = _selected;
    if (selected == _wasSelected && !selected) return;
    setState(() {});
  }

  /// When one of several selected entries is pressed and released without dragging, keep only that one.
  bool _collapseOnTap = false;

  void _handleTap() {
    widget.focus.requestFocus();
    widget.library.select(
      widget.entry,
      toggle: HardwareKeyboard.instance.isControlPressed,
      range: HardwareKeyboard.instance.isShiftPressed,
    );
  }

  /// Selects on press, like Explorer
  /// (onTap fires late because it waits to rule out a double tap).
  void _handlePointerDown(PointerDownEvent event) {
    if (event.buttons != kPrimaryButton) return;
    final modified = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isShiftPressed;
    // Pressing inside the selection waits for release so the whole selection can be dragged.
    _collapseOnTap = _selected && !modified;
    if (_collapseOnTap) {
      widget.focus.requestFocus();
      return;
    }
    _handleTap();
  }

  void _handleDelayedTap() {
    if (!_collapseOnTap) return;
    _collapseOnTap = false;
    widget.library.select(widget.entry);
  }

  /// Only folders accept drops, and not the folder itself or entries already inside it.
  bool _accepts(List<LibraryEntry> dragged) {
    final entry = widget.entry;
    if (entry is! FolderEntry) return false;
    return dragged.every(
      (item) =>
          item.relativePath != entry.relativePath &&
          !entry.relativePath.startsWith('${item.relativePath}/') &&
          !item.relativePath.startsWith('${entry.relativePath}/'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _wasSelected = _selected;
    final row = Listener(
      onPointerDown: _handlePointerDown,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleDelayedTap,
        onDoubleTap: () {
          _collapseOnTap = false;
          widget.onOpen();
        },
        onSecondaryTapUp: (details) {
          if (!_selected) _handleTap();
          _showEntryMenu(context, widget.library, widget.entry, details.globalPosition);
        },
        child: _EntryCard(entry: widget.entry, selected: selected, highlighted: _dropTarget, library: widget.library),
      ),
    );

    final draggable = Draggable<List<LibraryEntry>>(
      data: widget.library.dragGroupFor(widget.entry),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: _DragFeedback(entries: widget.library.dragGroupFor(widget.entry)),
      childWhenDragging: Opacity(opacity: 0.4, child: row),
      child: row,
    );

    if (widget.entry is! FolderEntry) return draggable;

    return DragTarget<List<LibraryEntry>>(
      onWillAcceptWithDetails: (details) {
        final ok = _accepts(details.data);
        if (ok && !_dropTarget) setState(() => _dropTarget = true);
        return ok;
      },
      onLeave: (_) => setState(() => _dropTarget = false),
      onAcceptWithDetails: (details) {
        setState(() => _dropTarget = false);
        widget.library.moveEntries(details.data, widget.entry.relativePath);
      },
      builder: (context, candidate, rejected) => draggable,
    );
  }
}

/// Small label that follows the cursor while dragging.
class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.entries});

  final List<LibraryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = entries.length == 1 ? entries.single.name : l10n.itemCount(entries.length);

    return Transform.translate(
      offset: const Offset(12, 12),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.drive_file_move_outline, size: 18, color: theme.colorScheme.onSecondaryContainer),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSecondaryContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The visible card. Selection changes its border and background; drop targets are highlighted.
class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.selected, required this.highlighted, required this.library});

  final LibraryEntry entry;
  final bool selected;
  final bool highlighted;
  final LibraryController library;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final content = switch (entry) {
      FolderEntry() => _FolderContent(folder: entry as FolderEntry),
      LevelEntry() => _LevelContent(entry: entry as LevelEntry),
      ExternalLevelEntry() => _ExternalLevelContent(entry: entry as ExternalLevelEntry),
    };

    return AnimatedContainer(
      duration: Motion.fast,
      curve: Motion.standard,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted
            ? colors.secondaryContainer
            : selected
            ? colors.primaryContainer.withValues(alpha: 0.45)
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted
              ? colors.secondary
              : selected
              ? colors.primary
              : colors.outlineVariant.withValues(alpha: 0),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: content),
          _EntryMenuButton(entry: entry, library: library),
        ],
      ),
    );
  }
}

class _FolderContent extends StatelessWidget {
  const _FolderContent({required this.folder});

  final FolderEntry folder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = folder.isEmpty
        ? l10n.empty
        : [
            if (folder.folderCount > 0) l10n.folderCount(folder.folderCount),
            if (folder.levelCount > 0) l10n.levelCount(folder.levelCount),
          ].join('  ·  ');

    return SizedBox(
      height: 48,
      child: Row(
        children: [
          // Folders downloaded as a pack show the pack's icon.
          if (folder.iconUrl case final icon?)
            SizedBox.square(
              dimension: 36,
              child: ClipRRect(borderRadius: BorderRadius.circular(8), child: NetworkIcon(icon, size: 36)),
            )
          else
            Icon(Icons.folder, size: 36, color: theme.colorScheme.secondary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 22,
                  child: SlideOverflow(child: slidingText(folder.name, style: theme.textTheme.titleMedium)),
                ),
                Text(summary, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExternalLevelContent extends StatelessWidget {
  const _ExternalLevelContent({required this.entry});

  final ExternalLevelEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Icon(Icons.music_note_outlined, size: 36, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 22,
                  child: SlideOverflow(child: slidingText(entry.name, style: theme.textTheme.titleMedium)),
                ),
                Text(
                  l10n.addedManuallyNotIn,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelContent extends StatelessWidget {
  const _LevelContent({required this.entry});

  final LevelEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = AppScope.of(context);
    final item = entry.level;
    final update = app.library.updateFor(item.levelId);
    final job = app.installs.jobFor(item.levelId);
    final difficulty = app.difficultyNamed(item.difficulty);
    final mutedStyle = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Row(
      children: [
        HoverTip(
          message: item.difficulty ?? '?',
          // The difficulty list may not have arrived yet; only the icon rebuilds when it does.
          child: difficulty != null
              ? NetworkIcon(difficulty.icon, size: 44)
              : ListenableBuilder(
                  listenable: app.levels,
                  builder: (context, _) => NetworkIcon(app.difficultyNamed(item.difficulty)?.icon, size: 44),
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: SizedBox(
                      height: 24,
                      child: SlideOverflow(child: slidingText(item.song, style: theme.textTheme.titleMedium)),
                    ),
                  ),
                  AnimatedSize(
                    duration: Motion.medium,
                    curve: Motion.curve,
                    child: update != null
                        ? Appear(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Chip(
                                label: Text(l10n.updateAvailable),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
                child: SlideOverflow(
                  child: slidingText(
                    [
                      item.artist,
                      item.creator,
                      '#${item.levelId}',
                    ].whereType<String>().where((s) => s.isNotEmpty).join('  ·  '),
                    style: mutedStyle,
                  ),
                ),
              ),
              Text(
                l10n.sizeAndDownloadDate(formatBytes(item.sizeBytes), _formatDate(item.installedAt)),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        AnimatedSize(
          duration: Motion.medium,
          curve: Motion.curve,
          child: FadeSwitcher(
            scale: true,
            alignment: Alignment.centerRight,
            child: job != null
                ? SizedBox(
                    key: const ValueKey('job'),
                    width: 160,
                    child: JobProgressIndicator(job: job),
                  )
                : update != null
                ? FilledButton.tonal(
                    key: const ValueKey('update'),
                    onPressed: () => app.installs.install(update),
                    child: Text(l10n.update),
                  )
                : const SizedBox.shrink(key: ValueKey('none')),
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }
}

class _EntryMenuButton extends StatelessWidget {
  const _EntryMenuButton({required this.entry, required this.library});

  final LibraryEntry entry;
  final LibraryController library;

  @override
  Widget build(BuildContext context) => HoverTip(
    message: l10n.more,
    child: Builder(
      builder: (context) => IconButton(
        onPressed: () {
          final box = context.findRenderObject() as RenderBox?;
          final position = box == null ? Offset.zero : box.localToGlobal(box.size.center(Offset.zero));
          _showEntryMenu(context, library, entry, position);
        },
        icon: const Icon(Icons.more_vert),
      ),
    ),
  );
}

// ───────────────────────── Header / toolbar ─────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.library});

  final LibraryController library;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = library.installedCount;
    final checking = library.isCheckingUpdates;
    final summary = count == 0
        ? l10n.organizeYourDownloadedLevels
        : l10n.levelCountAndSize(count, formatBytes(library.totalSize));

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.library, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              FadeSwitcher(
                alignment: Alignment.centerLeft,
                child: Text(
                  summary,
                  key: ValueKey(summary),
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: Motion.medium,
          curve: Motion.curve,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: checking || count == 0 ? null : library.checkUpdates,
                icon: FadeSwitcher(
                  duration: Motion.fast,
                  child: checking
                      ? const SizedBox(
                          key: ValueKey('checking'),
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, key: ValueKey('idle')),
                ),
                label: Text(checking ? l10n.checking : l10n.checkForUpdates),
              ),
              if (library.updateCount > 0) ...[
                const SizedBox(width: 8),
                Appear(
                  child: FilledButton(onPressed: library.updateAll, child: Text(l10n.updateAll(library.updateCount))),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Up, current path, sort and new folder. The path segments also accept drops.
class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.library});

  final LibraryController library;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final crumbs = library.breadcrumb;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Row(
          children: [
            IconButton(
              tooltip: l10n.upBackspace,
              onPressed: library.currentPath.isEmpty ? null : library.goUp,
              icon: const Icon(Icons.arrow_upward),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: SizedBox(
                height: 32,
                child: SlideOverflow(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (index, crumb) in crumbs.indexed) ...[
                        if (index > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        _CrumbTarget(
                          library: library,
                          path: crumb.$2,
                          isCurrent: index == crumbs.length - 1,
                          label: crumb.$1,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            MenuAnchor(
              menuChildren: [
                for (final entry in librarySortLabels.entries)
                  MenuItemButton(
                    leadingIcon: Icon(library.sort == entry.key ? Icons.check : null),
                    onPressed: () => library.setSort(entry.key),
                    child: Text(entry.value),
                  ),
              ],
              builder: (context, controller, _) => OutlinedButton.icon(
                onPressed: () => controller.isOpen ? controller.close() : controller.open(),
                icon: const Icon(Icons.sort),
                label: Text(librarySortLabels[library.sort]!),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _createFolder(context, library),
              icon: const Icon(Icons.create_new_folder_outlined),
              label: Text(l10n.newFolder),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: l10n.openInExplorer,
              onPressed: library.openFolderPath,
              icon: const Icon(Icons.open_in_new),
            ),
            MenuAnchor(
              menuChildren: [
                MenuItemButton(
                  leadingIcon: const Icon(Icons.drive_file_move_outline),
                  onPressed: library.changeFolder,
                  child: Text(l10n.changeLibraryFolder),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.refresh),
                  onPressed: library.refreshContents,
                  child: Text(l10n.refreshLibrary),
                ),
              ],
              builder: (context, controller, _) => IconButton(
                tooltip: l10n.more,
                onPressed: () => controller.isOpen ? controller.close() : controller.open(),
                icon: const Icon(Icons.more_vert),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One path segment. Dropping on it moves entries into that folder.
class _CrumbTarget extends StatefulWidget {
  const _CrumbTarget({required this.library, required this.path, required this.isCurrent, required this.label});

  final LibraryController library;
  final String path;
  final bool isCurrent;
  final String label;

  @override
  State<_CrumbTarget> createState() => _CrumbTargetState();
}

class _CrumbTargetState extends State<_CrumbTarget> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DragTarget<List<LibraryEntry>>(
      onWillAcceptWithDetails: (details) {
        // Reject entries already in that folder.
        final ok = details.data.every((entry) {
          final index = entry.relativePath.lastIndexOf('/');
          final parent = index < 0 ? '' : entry.relativePath.substring(0, index);
          return parent != widget.path && !widget.path.startsWith('${entry.relativePath}/');
        });
        if (ok && !_hovered) setState(() => _hovered = true);
        return ok;
      },
      onLeave: (_) => setState(() => _hovered = false),
      onAcceptWithDetails: (details) {
        setState(() => _hovered = false);
        widget.library.moveEntries(details.data, widget.path);
      },
      builder: (context, candidate, rejected) => AnimatedContainer(
        duration: Motion.fast,
        decoration: BoxDecoration(
          color: _hovered ? theme.colorScheme.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextButton(
          onPressed: widget.isCurrent ? null : () => widget.library.openPath(widget.path),
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            disabledForegroundColor: theme.colorScheme.onSurface,
          ),
          child: Text(widget.label, maxLines: 1, softWrap: false),
        ),
      ),
    );
  }
}

/// Selection bar rising from the bottom, drawn over the list so entries don't move.
class _FloatingSelectionBar extends StatelessWidget {
  const _FloatingSelectionBar({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !visible,
    child: AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 0.5),
      duration: Motion.fast,
      curve: Motion.curve,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: Motion.fast,
        curve: Motion.standard,
        // Keep taps on the bar's empty space from reaching the "click empty space to deselect" handler behind it.
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {}, child: child),
      ),
    ),
  );
}

/// Bar shown when several entries are selected.
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({required this.library});

  final LibraryController library;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = library.selectedEntries;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 8,
      shadowColor: Colors.black,
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: theme.colorScheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.selected(selected.length),
                style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSecondaryContainer),
              ),
            ),
            TextButton.icon(
              onPressed: selected.isEmpty ? null : () => _moveMany(context, library, selected),
              icon: const Icon(Icons.drive_file_move_outline),
              label: Text(l10n.move),
            ),
            const SizedBox(width: 4),
            TextButton.icon(
              onPressed: selected.isEmpty ? null : () => _deleteMany(context, library, selected),
              icon: const Icon(Icons.delete_outline),
              label: Text(l10n.delete),
            ),
            const SizedBox(width: 4),
            TextButton(onPressed: library.clearSelection, child: Text(l10n.deselect)),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Menus ─────────────────────────

Future<void> _showEntryMenu(
  BuildContext context,
  LibraryController library,
  LibraryEntry entry,
  Offset position,
) async {
  final selected = library.selectedEntries;
  final many = selected.length > 1 && library.selection.contains(entry.relativePath);
  final targets = many ? selected : [entry];

  final action = await _showMenuAt(context, position, [
    if (!many)
      PopupMenuItem(
        value: 'open',
        child: ListTile(
          leading: Icon(entry is FolderEntry ? Icons.folder_open : Icons.open_in_new),
          title: Text(entry is FolderEntry ? l10n.open : l10n.openInExplorer),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    if (!many)
      PopupMenuItem(
        value: 'rename',
        child: ListTile(
          leading: const Icon(Icons.drive_file_rename_outline),
          title: Text(l10n.rename),
          subtitle: const Text('F2'),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    PopupMenuItem(
      value: 'move',
      child: ListTile(
        leading: const Icon(Icons.drive_file_move_outline),
        title: Text(l10n.moveToFolder),
        contentPadding: EdgeInsets.zero,
      ),
    ),
    PopupMenuItem(
      value: 'delete',
      child: ListTile(
        leading: const Icon(Icons.delete_outline),
        title: Text(l10n.delete),
        subtitle: const Text('Delete'),
        contentPadding: EdgeInsets.zero,
      ),
    ),
  ]);
  if (action == null || !context.mounted) return;

  switch (action) {
    case 'open':
      entry is FolderEntry ? library.openPath(entry.relativePath) : library.openFolderPath(entry.relativePath);
    case 'rename':
      await _rename(context, library, entry);
    case 'move':
      await _moveMany(context, library, targets);
    case 'delete':
      await _deleteMany(context, library, targets);
  }
}

Future<void> _showFolderMenu(BuildContext context, LibraryController library, Offset position) async {
  final action = await _showMenuAt(context, position, [
    PopupMenuItem(
      value: 'new',
      child: ListTile(
        leading: const Icon(Icons.create_new_folder_outlined),
        title: Text(l10n.newFolder),
        contentPadding: EdgeInsets.zero,
      ),
    ),
    PopupMenuItem(
      value: 'selectAll',
      child: ListTile(
        leading: const Icon(Icons.select_all),
        title: Text(l10n.selectAllItems),
        subtitle: const Text('Ctrl+A'),
        contentPadding: EdgeInsets.zero,
      ),
    ),
    PopupMenuItem(
      value: 'explorer',
      child: ListTile(
        leading: const Icon(Icons.open_in_new),
        title: Text(l10n.openInExplorer),
        contentPadding: EdgeInsets.zero,
      ),
    ),
    PopupMenuItem(
      value: 'refresh',
      child: ListTile(
        leading: const Icon(Icons.refresh),
        title: Text(l10n.refreshLibrary),
        contentPadding: EdgeInsets.zero,
      ),
    ),
  ]);
  if (action == null || !context.mounted) return;

  switch (action) {
    case 'new':
      await _createFolder(context, library);
    case 'selectAll':
      library.selectAll();
    case 'explorer':
      await library.openFolderPath();
    case 'refresh':
      await library.refreshContents();
  }
}

Future<String?> _showMenuAt(BuildContext context, Offset position, List<PopupMenuEntry<String>> items) {
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
  final size = overlay?.size ?? MediaQuery.sizeOf(context);

  return showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(position.dx, position.dy, size.width - position.dx, size.height - position.dy),
    items: items,
  );
}

// ───────────────────────── Dialogs ─────────────────────────

Future<void> _createFolder(BuildContext context, LibraryController library) async {
  final name = await _askName(context, title: l10n.newFolder, label: l10n.folderName, confirm: l10n.create);
  if (name != null) await library.createFolder(name);
}

Future<void> _rename(BuildContext context, LibraryController library, LibraryEntry entry) async {
  final name = await _askName(
    context,
    title: l10n.rename,
    label: l10n.newName,
    confirm: l10n.renameConfirm,
    initial: entry.name,
  );
  if (name != null) await library.renameEntry(entry, name);
}

Future<void> _moveMany(BuildContext context, LibraryController library, List<LibraryEntry> entries) async {
  if (entries.isEmpty) return;

  final target = await showDialog<String>(
    context: context,
    builder: (context) => _MoveDialog(entries: entries, library: library),
  );
  if (target != null) await library.moveEntries(entries, target);
}

Future<void> _deleteMany(BuildContext context, LibraryController library, List<LibraryEntry> entries) async {
  if (entries.isEmpty) return;
  final colors = Theme.of(context).colorScheme;

  final title = entries.length == 1 ? l10n.deleteNamed(entries.single.name) : l10n.deleteItems(entries.length);
  final levelsInside = entries.whereType<FolderEntry>().fold(0, (sum, folder) => sum + folder.levelCount);
  final message = levelsInside > 0 ? l10n.thisDeletesItFrom(levelsInside) : l10n.thisDeletesItFromDisk;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
  if (confirmed == true) await library.deleteEntries(entries);
}

Future<String?> _askName(
  BuildContext context, {
  required String title,
  required String label,
  required String confirm,
  String initial = '',
}) => showDialog<String>(
  context: context,
  builder: (context) => _NameDialog(title: title, label: label, confirm: confirm, initial: initial),
);

/// Dialog asking for a name. The text field is still used during the closing animation,
/// so its controller is disposed only when the dialog is gone (State.dispose).
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, required this.label, required this.confirm, required this.initial});

  final String title;
  final String label;
  final String confirm;
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isNotEmpty) Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SizedBox(
      width: 360,
      child: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: widget.label),
        onSubmitted: (_) => _submit(),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
      FilledButton(onPressed: _submit, child: Text(widget.confirm)),
    ],
  );
}

/// Picks a target folder by browsing into it. The moved folder and its subfolders can't be entered.
class _MoveDialog extends StatefulWidget {
  const _MoveDialog({required this.entries, required this.library});

  final List<LibraryEntry> entries;
  final LibraryController library;

  @override
  State<_MoveDialog> createState() => _MoveDialogState();
}

class _MoveDialogState extends State<_MoveDialog> {
  String _path = '';
  FolderContents? _contents;

  @override
  void initState() {
    super.initState();
    _path = _parentOf(widget.entries.first.relativePath);
    _load();
  }

  static String _parentOf(String path) {
    final index = path.lastIndexOf('/');
    return index < 0 ? '' : path.substring(0, index);
  }

  Future<void> _load() async {
    final contents = await widget.library.browse(_path);
    if (mounted) setState(() => _contents = contents);
  }

  void _enter(String path) {
    setState(() {
      _path = path;
      _contents = null;
    });
    _load();
  }

  bool _isSelfOrInside(String path) =>
      widget.entries.any((entry) => path == entry.relativePath || path.startsWith('${entry.relativePath}/'));

  bool get _canMoveHere =>
      !_isSelfOrInside(_path) && widget.entries.any((entry) => _parentOf(entry.relativePath) != _path);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contents = _contents;
    final title = widget.entries.length == 1
        ? l10n.moveNamed(widget.entries.single.name)
        : l10n.moveItems(widget.entries.length);

    final crumbs = <(String, String)>[(l10n.root, '')];
    var walked = '';
    for (final part in _path.split('/').where((part) => part.isNotEmpty)) {
      walked = walked.isEmpty ? part : '$walked/$part';
      crumbs.add((part, walked));
    }

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 460,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 32,
              child: SlideOverflow(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (index, crumb) in crumbs.indexed) ...[
                      if (index > 0) Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.onSurfaceVariant),
                      TextButton(
                        onPressed: index == crumbs.length - 1 ? null : () => _enter(crumb.$2),
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          disabledForegroundColor: theme.colorScheme.onSurface,
                        ),
                        child: Text(crumb.$1, maxLines: 1, softWrap: false),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: switch (contents) {
                null => const Center(child: CircularProgressIndicator()),
                FolderContents(folders: []) => Center(
                  child: Text(
                    l10n.noSubfolders,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                final value => ListView(
                  children: [
                    for (final folder in value.folders)
                      ListTile(
                        leading: const Icon(Icons.folder_outlined),
                        title: Text(folder.name),
                        enabled: !_isSelfOrInside(folder.relativePath),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _enter(folder.relativePath),
                      ),
                  ],
                ),
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: _canMoveHere ? () => Navigator.of(context).pop(_path) : null,
          child: Text(_path.isEmpty ? l10n.moveToRoot : l10n.moveHere),
        ),
      ],
    );
  }
}

class _EmptyFolder extends StatelessWidget {
  const _EmptyFolder({required this.atRoot, required this.onBrowse, required this.onCreateFolder});

  final bool atRoot;
  final VoidCallback onBrowse;
  final VoidCallback onCreateFolder;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: EmptyState(
          icon: Icon(atRoot ? Icons.download_outlined : Icons.folder_open_outlined),
          title: atRoot ? l10n.noDownloadedLevelsYet : l10n.thisFolderIsEmpty,
          message: atRoot ? l10n.findLevelsYouLike : l10n.dragLevelsHereOr,
          action: atRoot
              ? FilledButton(onPressed: onBrowse, child: Text(l10n.browseLevels))
              : OutlinedButton.icon(
                  onPressed: onCreateFolder,
                  icon: const Icon(Icons.create_new_folder_outlined),
                  label: Text(l10n.newFolder),
                ),
        ),
      ),
    ),
  );
}
