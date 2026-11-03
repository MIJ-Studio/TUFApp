import 'package:flutter/material.dart';

import '../../app/controllers.dart';
import '../../core/folder_template.dart';
import '../../core/l10n.dart';
import '../../core/models/difficulty.dart';
import '../../core/models/level.dart';
import '../../core/tuf_api_client.dart';
import '../app_shortcuts.dart';
import '../widgets/labels.dart';
import '../widgets/smooth_scroll.dart';

/// App settings: language, UI scale, where and how levels are saved.
/// Every change applies and is saved right away.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  /// The folder name template field (the language and scale menus have text fields too).
  static const folderTemplateKey = ValueKey('folderTemplate');

  static Future<void> open(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsPage()));

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _maxWidth = 760.0;

  final _scroll = SmoothScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return PageCommandScope(
      commands: () => PageCommands(scroll: _scroll, searchable: false),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: l10n.back,
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(l10n.settings),
        ),
        body: SmoothScrollbar(
          controller: _scroll,
          builder: (context, behavior) => ScrollConfiguration(
            behavior: behavior,
            child: ListenableBuilder(
              listenable: Listenable.merge([app, app.library]),
              builder: (context, _) => ListView(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  for (final child in [
                    _SectionTitle(l10n.settingsGeneral),
                    _LanguageSetting(app: app),
                    _ZoomSetting(app: app),
                    const SizedBox(height: 24),
                    _SectionTitle(l10n.settingsDownloads),
                    _LibraryFolderSetting(library: app.library),
                    _FolderTemplateSetting(app: app),
                    _FillChartSetting(app: app),
                    _ApplyToDownloadedSetting(app: app),
                  ])
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: _maxWidth),
                        // Full width, so short items like the section titles start at the left edge too.
                        child: SizedBox(width: double.infinity, child: child),
                      ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(text, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
    );
  }
}

class _LanguageSetting extends StatelessWidget {
  const _LanguageSetting({required this.app});

  final AppController app;

  /// The menu needs a non-null value for "follow the system", so languages are chosen by code ('' = system).
  static const _system = '';

  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.translate),
    title: Text(l10n.language),
    trailing: DropdownMenu<String>(
      // The labels change with the language, so the menu is recreated with it.
      key: ValueKey(appLanguage),
      initialSelection: app.languageChoice?.code ?? _system,
      width: 220,
      onSelected: (code) {
        if (code != null) app.setLanguage(AppLanguage.fromCode(code));
      },
      dropdownMenuEntries: [
        DropdownMenuEntry(value: _system, label: l10n.systemLanguage(AppLanguage.system.nativeName)),
        for (final language in AppLanguage.values) DropdownMenuEntry(value: language.code, label: language.nativeName),
      ],
    ),
  );
}

class _ZoomSetting extends StatelessWidget {
  const _ZoomSetting({required this.app});

  final AppController app;

  static String _percent(double zoom) => '${(zoom * 100).round()}%';

  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.zoom_in),
    title: Text(l10n.uiScale),
    subtitle: Text(l10n.uiScaleHint),
    trailing: DropdownMenu<double>(
      // Shortcuts change the zoom too, so the menu follows it.
      key: ValueKey((app.zoom, appLanguage)),
      initialSelection: app.zoom,
      width: 140,
      onSelected: (zoom) {
        if (zoom != null) app.setZoom(zoom);
      },
      dropdownMenuEntries: [
        for (final zoom in AppController.zoomLevels) DropdownMenuEntry(value: zoom, label: _percent(zoom)),
      ],
    ),
  );
}

class _LibraryFolderSetting extends StatelessWidget {
  const _LibraryFolderSetting({required this.library});

  final LibraryController library;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.folder_outlined),
    title: Text(l10n.libraryFolder),
    subtitle: Text(library.rootPath, maxLines: 2, overflow: TextOverflow.ellipsis),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        IconButton(
          tooltip: l10n.openInExplorer,
          onPressed: library.rootPath.isEmpty ? null : library.openFolderPath,
          icon: const Icon(Icons.open_in_new),
        ),
        OutlinedButton(onPressed: library.changeFolder, child: Text(l10n.change)),
      ],
    ),
  );
}

/// The folder name template with a button per tag and a live example.
class _FolderTemplateSetting extends StatefulWidget {
  const _FolderTemplateSetting({required this.app});

  final AppController app;

  @override
  State<_FolderTemplateSetting> createState() => _FolderTemplateSettingState();
}

class _FolderTemplateSettingState extends State<_FolderTemplateSetting> {
  late final _text = TextEditingController(text: widget.app.levelFolderTemplate);
  final _focus = FocusNode();

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _changed(String template) {
    setState(() {});
    widget.app.setLevelFolderTemplate(template);
  }

  /// Puts the tag where the cursor is (replacing a selection), or at the end.
  void _insert(FolderTag tag) {
    final value = _text.value;
    final selection = value.selection.isValid ? value.selection : TextSelection.collapsed(offset: value.text.length);
    final text = value.text.replaceRange(selection.start, selection.end, tag.token);
    _text.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: selection.start + tag.token.length),
    );
    _focus.requestFocus();
    _changed(text);
  }

  void _reset() {
    _text.text = LevelFolderTemplate.defaultTemplate;
    _changed(_text.text);
  }

  static String _label(FolderTag tag) => switch (tag) {
    FolderTag.id => l10n.folderTagId,
    FolderTag.song => l10n.folderTagSong,
    FolderTag.artist => l10n.folderTagArtist,
    FolderTag.creator => l10n.creator,
    FolderTag.charter => l10n.charters,
    FolderTag.vfxer => l10n.vfx,
    FolderTag.team => l10n.team,
    FolderTag.difficulty => l10n.difficulty,
    FolderTag.bpm => l10n.levelSortBpm,
    FolderTag.tiles => l10n.tileCount,
  };

  /// TUF level #1, the example the template is shown with. Real data reads better than placeholders.
  /// This copy is shown until (or if never) the current data arrives from TUF.
  static const _levelOne = Level(
    id: 1,
    song: 'multi_arm',
    artist: 'Frums',
    credits: [LevelCredit(role: 'charter', creatorName: 'Zagon')],
    difficulty: Difficulty(id: 45, name: 'U5', type: 'PGU'),
    bpm: 110,
    tilecount: 4830,
  );

  Level _example = _levelOne;
  bool _fetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // AppScope can't be read in initState. Fetch only once.
    if (_fetched) return;
    _fetched = true;
    _fetchExample(AppScope.of(context).api);
  }

  Future<void> _fetchExample(TufApiClient api) async {
    try {
      final level = await api.getLevel(_levelOne.id);
      if (mounted) setState(() => _example = level);
    } on TufApiException {
      // The saved copy is a fine example.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final template = _text.text;
    final unknown = LevelFolderTemplate.unknownTags(template);
    final hasId = template.trim().isEmpty || template.toLowerCase().contains(FolderTag.id.token);

    // The editor sits in the subtitle, so it lines up with the other settings' titles.
    return ListTile(
      titleAlignment: ListTileTitleAlignment.top,
      leading: const Icon(Icons.drive_file_rename_outline),
      title: Text(l10n.levelFolderName),
      subtitle: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(l10n.levelFolderNameHint),
            TextField(
              key: SettingsPage.folderTemplateKey,
              controller: _text,
              focusNode: _focus,
              onChanged: _changed,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                hintText: LevelFolderTemplate.defaultTemplate,
                errorText: unknown.isEmpty ? null : l10n.unknownFolderTags(unknown.join(', ')),
                suffixIcon: template == LevelFolderTemplate.defaultTemplate
                    ? null
                    : IconButton(tooltip: l10n.resetToDefault, onPressed: _reset, icon: const Icon(Icons.restart_alt)),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in FolderTag.values)
                  ActionChip(
                    label: Text('${tag.token}  ${_label(tag)}'),
                    // The value in the example; level #1 has no VFX credit, so that one has none.
                    tooltip: switch (tag.valueOf(_example)) {
                      '' => null,
                      final value => value,
                    },
                    onPressed: () => _insert(tag),
                  ),
              ],
            ),
            ValueBox(
              child: Text(
                l10n.folderNameExample(LevelFolderTemplate.format(template, _example)),
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSecondaryContainer),
              ),
            ),
            Text([l10n.levelFolderNameKept, if (!hasId) l10n.folderNameWithoutId(FolderTag.id.token)].join(' ')),
          ],
        ),
      ),
    );
  }
}

/// Whether downloads write TUF's info into level files.
class _FillChartSetting extends StatelessWidget {
  const _FillChartSetting({required this.app});

  final AppController app;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    secondary: const Icon(Icons.auto_fix_high_outlined),
    title: Text(l10n.fillChartMetadata),
    subtitle: Text(l10n.fillChartMetadataHint),
    value: app.fillChartMetadata,
    onChanged: app.setFillChartMetadata,
  );
}

/// The settings page covers the app bar's status text, so results are shown here too.
void _showResult(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

/// Applies the settings above (folder name format, and filling in level info when it is on) to levels already
/// downloaded, after showing what will change.
class _ApplyToDownloadedSetting extends StatefulWidget {
  const _ApplyToDownloadedSetting({required this.app});

  final AppController app;

  @override
  State<_ApplyToDownloadedSetting> createState() => _ApplyToDownloadedSettingState();
}

class _ApplyToDownloadedSettingState extends State<_ApplyToDownloadedSetting> {
  bool _running = false;

  Future<void> _run() async {
    setState(() => _running = true);
    try {
      await _apply();
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _apply() async {
    final app = widget.app;
    final fill = app.fillChartMetadata;
    final plan = await app.library.planApply(app.levelFolderTemplate);
    if (!mounted) return;
    if (plan == null) {
      _showResult(context, app.status);
      return;
    }
    if (plan.renames.isEmpty && !fill) {
      _showResult(context, l10n.noFoldersToRename);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _ApplyPreviewDialog(renames: plan.renames, fillCount: fill ? app.library.installedCount : null),
    );
    if (confirmed != true || !mounted) return;
    await app.library.apply(plan, fill: fill);
    if (mounted) _showResult(context, app.status);
  }

  @override
  Widget build(BuildContext context) {
    final library = widget.app.library;
    final progress = _running ? library.maintenanceProgress : null;
    return ListTile(
      leading: const Icon(Icons.drive_file_move_outline),
      title: Text(l10n.applyToDownloaded),
      subtitle: progress == null
          ? Text(l10n.applyToDownloadedHint)
          : Row(
              spacing: 8,
              children: [
                const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                Flexible(child: Text(progress, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
      trailing: OutlinedButton(
        onPressed: library.isMaintaining || _running || library.installedCount == 0 ? null : _run,
        child: Text(l10n.apply),
      ),
    );
  }
}

/// Everything applying will do, before anything is touched: each folder rename (current → new), and the level
/// files that will be filled in when that setting is on ([fillCount] files, null when off).
class _ApplyPreviewDialog extends StatelessWidget {
  const _ApplyPreviewDialog({required this.renames, required this.fillCount});

  final List<FolderRename> renames;
  final int? fillCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final heading = theme.textTheme.titleSmall;
    return AlertDialog(
      title: Text(l10n.applyToDownloadedTitle),
      content: SizedBox(
        width: 640,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            if (fillCount case final count?) ...[
              Text(l10n.fillChartMetadata, style: heading),
              Text(l10n.fillChartsNote(count)),
            ],
            if (renames.isNotEmpty) ...[
              Text(l10n.renameFoldersHeading(renames.length), style: heading),
              Text(l10n.renameFoldersNote),
              Flexible(
                child: _PreviewList(
                  plans: renames,
                  itemBuilder: (plan) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.from, style: muted, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Row(
                          spacing: 4,
                          children: [
                            Icon(Icons.subdirectory_arrow_right, size: 16, color: theme.colorScheme.primary),
                            Expanded(child: Text(plan.to, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.apply)),
      ],
    );
  }
}

/// A scrolling list inside the dialog, with the app's scrollbar (desktop scrollbars need their own controller).
class _PreviewList extends StatefulWidget {
  const _PreviewList({required this.plans, required this.itemBuilder});

  final List<FolderRename> plans;
  final Widget Function(FolderRename plan) itemBuilder;

  @override
  State<_PreviewList> createState() => _PreviewListState();
}

class _PreviewListState extends State<_PreviewList> {
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
      child: ListView.builder(
        controller: _scroll,
        shrinkWrap: true,
        itemCount: widget.plans.length,
        itemBuilder: (context, index) => widget.itemBuilder(widget.plans[index]),
      ),
    ),
  );
}
