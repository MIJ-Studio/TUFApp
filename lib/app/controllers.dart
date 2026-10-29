import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/frame_log.dart';
import '../core/l10n.dart';
import '../core/level_downloader.dart';
import '../core/level_library.dart';
import '../core/level_manager.dart';
import '../core/level_sizes.dart';
import '../core/library_organizer.dart';
import '../core/models/difficulty.dart';
import '../core/models/facet.dart';
import '../core/models/level.dart';
import '../core/models/search_models.dart';
import '../core/tuf_api_client.dart';
import '../core/video_links.dart';
import '../core/video_thumbnails.dart';
import 'browse_controllers.dart';
import 'navigation_history.dart';
import 'packs_controller.dart';

export 'browse_controllers.dart';
export 'navigation_history.dart';
export 'packs_controller.dart';

enum AppPage { levels, packs, clears, leaderboard, creators, library }

enum LevelInstallState { notInstalled, installed, updateAvailable, notDownloadable }

/// Exposes [AppController] to the widget tree.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.controller, required super.child});

  final AppController controller;

  static AppController of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.controller;

  @override
  bool updateShouldNotify(AppScope oldWidget) => controller != oldWidget.controller;
}

/// App-wide state: current page, status message, startup and the page controllers.
class AppController extends ChangeNotifier {
  /// [api] is only passed by tests to plug in a fake server.
  AppController({TufApiClient? api}) : api = api ?? TufApiClient() {
    installs = InstallCenter(onStatus: setStatus);
    levels = LevelsController(api: this.api, onStatus: setStatus);
    library = LibraryController(api: this.api, installs: installs, onStatus: setStatus);
    packs = PacksController(api: this.api, levels: levels, installs: installs, onStatus: setStatus);
    clears = ClearsController(this.api, catalog: () => levels.catalog);
    leaderboard = LeaderboardController(this.api);
    creators = CreatorsController(this.api);
    installs.addListener(library.onInstallsChanged);
    packs.history = history;
    library.history = history;
  }

  /// Forward history for back/forward navigation (keyboard shortcuts and mouse side buttons).
  final history = NavigationHistory();

  final TufApiClient api;
  late final VideoThumbnails thumbnails = VideoThumbnails(api);
  late final LevelSizes levelSizes = LevelSizes(api);
  late final InstallCenter installs;
  late final LevelsController levels;
  late final LibraryController library;
  late final PacksController packs;
  late final ClearsController clears;
  late final LeaderboardController leaderboard;
  late final CreatorsController creators;

  AppPage page = AppPage.levels;
  String status = l10n.loading;
  String? startupError;

  void setPage(AppPage value) {
    if (page == value) return;
    page = value;
    history.clearForward();
    // Lists other than levels are loaded the first time their page is shown.
    switch (value) {
      case AppPage.packs:
        packs.ensureLoaded();
      case AppPage.clears:
        clears.ensureLoaded();
      case AppPage.leaderboard:
        leaderboard.ensureLoaded();
      case AppPage.creators:
        creators.ensureLoaded();
      case AppPage.levels || AppPage.library:
        break;
    }
    notifyListeners();
  }

  void setStatus(String message) {
    status = message;
    notifyListeners();
  }

  /// The chosen UI language. null follows the system language.
  AppLanguage? languageChoice;

  /// Changes the UI language and saves it to the settings file. null follows the system language.
  /// [TufApp] listens and rebuilds the whole tree.
  Future<void> setLanguage(AppLanguage? choice) async {
    final wasReady = status == _readyText;
    languageChoice = choice;
    appLanguage = choice ?? AppLanguage.system;
    if (wasReady) status = _readyText;
    notifyListeners();
    await _saveSettings((settings) => settings.language = choice);
  }

  /// UI zoom factor (1 = 100%). The whole UI is scaled, like zooming a web page.
  double zoom = 1;

  /// Zoom steps, the same as browsers use.
  static const zoomLevels = [0.5, 0.67, 0.75, 0.8, 0.9, 1.0, 1.1, 1.25, 1.5, 1.75, 2.0];

  void zoomIn() => setZoom(zoomLevels.firstWhere((level) => level > zoom + 0.001, orElse: () => zoomLevels.last));

  void zoomOut() => setZoom(zoomLevels.lastWhere((level) => level < zoom - 0.001, orElse: () => zoomLevels.first));

  void resetZoom() => setZoom(1);

  Future<void> setZoom(double value) async {
    final clamped = value.clamp(zoomLevels.first, zoomLevels.last);
    if (clamped == zoom) return;
    zoom = clamped;
    setStatus(l10n.zoomPercent((zoom * 100).round()));
    await _saveSettings((settings) => settings.zoom = zoom == 1 ? null : zoom);
  }

  /// Steps back within the current tab: closes the open pack, or goes up one library folder.
  /// Returns false if there is nothing to go back to.
  bool goBackInPage() {
    switch (page) {
      case AppPage.packs when packs.openedPack != null:
        packs.close();
        return true;
      case AppPage.library when library.currentPath.isNotEmpty:
        library.goUp();
        return true;
      default:
        return false;
    }
  }

  Future<void> _saveSettings(void Function(AppSettings settings) change) async {
    final settings = library.settings;
    if (settings == null) return;
    change(settings);
    try {
      await settings.save();
    } on FileSystemException catch (e) {
      setStatus(l10n.couldNotSaveSettings(e.message));
    }
  }

  static String get _readyText => l10n.ready;

  /// [settings] are the settings main() already read to pick the language early (read here if null).
  Future<void> initialize({AppSettings? settings}) async {
    startupError = null;
    setStatus(l10n.loading);

    try {
      settings ??= await AppSettings.load();
      settings
        ..language = languageChoice
        ..zoom = zoom == 1 ? null : zoom;
      library.settings = settings;
      final tags = _tryList(api.getTags());
      final curations = _tryList(api.getCurationTypes());
      // Wait for both together; awaiting them one by one would leave the second failure unhandled if the first throws.
      final ready = await Future.wait([library.open(settings.libraryPath), api.getDifficulties()]);
      final catalog = DifficultyCatalog(ready[1] as List<Difficulty>);

      setStatus(library.recovery ?? _readyText);
      await levels.initialize(catalog, tags: FacetCatalog(await tags), curationTypes: FacetCatalog(await curations));
    } on TufApiException catch (e) {
      _failStartup(e.message);
    } on FileSystemException catch (e) {
      _failStartup(e.message);
    } on StateError catch (e) {
      _failStartup(e.message);
    } on Object catch (e) {
      // Unexpected errors must not leave the app stuck on "Loading"; the user can retry.
      _failStartup('$e');
    }
  }

  /// The rest of the app works without tags and curation types, so failures are swallowed.
  static Future<List<FacetItem>> _tryList(Future<List<FacetItem>> request) async {
    try {
      return await request;
    } on TufApiException {
      return const [];
    }
  }

  void _failStartup(String message) {
    startupError = message;
    setStatus(l10n.couldNotStart(message));
  }

  Difficulty? difficultyNamed(String? name) => levels.catalog?.named(name);

  /// Opens only http/https links in the browser.
  /// When several links are joined with spaces (like the video field), opens the first one.
  Future<void> openLink(String? url) async {
    final first = VideoLinks.primary(url);
    final uri = first == null ? null : Uri.tryParse(first);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) return;
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        setStatus(l10n.couldNotOpenLink(url ?? ''));
      }
    } on PlatformException {
      setStatus(l10n.couldNotOpenLink(url ?? ''));
    }
  }

  @override
  void dispose() {
    installs.removeListener(library.onInstallsChanged);
    levels.dispose();
    library.dispose();
    packs.dispose();
    clears.dispose();
    leaderboard.dispose();
    creators.dispose();
    installs.dispose();
    api.close();
    super.dispose();
  }
}

// ───────────────────────── Downloads ─────────────────────────

/// Progress of downloading a single level.
class InstallJob extends ChangeNotifier {
  InstallJob(this.levelId);

  final int levelId;
  final CancelToken cancelToken = CancelToken();

  /// null when progress is unknown (preparing or extracting).
  double? fraction;

  /// Short status for the narrow button, e.g. "42%" or "Extracting".
  String shortText = l10n.preparing;

  void report(InstallProgress progress) {
    switch (progress.stage) {
      case InstallStage.fetchingInfo:
        fraction = null;
        shortText = l10n.preparing;
      case InstallStage.downloading:
        final download = progress.download;
        fraction = download?.fraction;
        shortText = fraction != null ? '${(fraction! * 100).round()}%' : formatBytes(download?.bytesReceived ?? 0);
      case InstallStage.extracting:
        fraction = null;
        shortText = l10n.extracting;
      case InstallStage.completed:
        fraction = 1;
        shortText = l10n.done;
    }
    notifyListeners();
  }

  void cancel() {
    cancelToken.cancel();
    shortText = l10n.cancelling;
    notifyListeners();
  }
}

/// Running downloads. A level is never downloaded twice at once, and every page shows the same progress.
class InstallCenter extends ChangeNotifier {
  InstallCenter({required this.onStatus});

  final void Function(String message) onStatus;
  LevelManager? manager;

  final Map<int, InstallJob> _jobs = {};

  InstallJob? jobFor(int levelId) => _jobs[levelId];

  int get activeCount => _jobs.length;

  /// Redraws download buttons after the library changes (delete, folder change).
  void refresh() => notifyListeners();

  LevelInstallState stateOf(Level level) {
    final installed = manager?.library.get(level.id);
    if (installed != null) {
      final remoteFileId = level.fileId;
      final isLatest = remoteFileId == null || remoteFileId.toLowerCase() == installed.fileId.toLowerCase();
      return isLatest ? LevelInstallState.installed : LevelInstallState.updateAvailable;
    }
    return LevelDownloader.isTufCdnLink(level.dlLink)
        ? LevelInstallState.notInstalled
        : LevelInstallState.notDownloadable;
  }

  /// Downloads a level, into [parentFolder] of the library if given ('/'-separated).
  /// Returns true on success.
  Future<bool> install(Level level, {String? parentFolder}) async {
    final current = manager;
    if (current == null || _jobs.containsKey(level.id)) return false;

    final job = InstallJob(level.id);
    _jobs[level.id] = job;
    notifyListeners();

    try {
      await current.install(level, onProgress: job.report, cancelToken: job.cancelToken, parentFolder: parentFolder);
      onStatus(l10n.downloadedSong(level.song));
      return true;
    } on OperationCancelledException {
      onStatus(l10n.downloadCancelled(level.song));
    } on LevelNotDownloadableException catch (e) {
      final link = e.alternativeLink;
      onStatus(link == null ? e.toString() : l10n.tryThisLinkInstead(e, link));
    } on TufApiException catch (e) {
      onStatus(l10n.downloadFailed(level.song, e.message));
    } on FileSystemException catch (e) {
      onStatus(l10n.downloadFailed(level.song, e.message));
    } on FormatException catch (e) {
      onStatus(l10n.downloadFailed(level.song, e.message));
    } finally {
      _jobs.remove(level.id);
      notifyListeners();
    }
    return false;
  }
}

// ───────────────────────── Levels ─────────────────────────

class SortOption {
  const SortOption(this.key);

  final LevelSortKey key;

  String get label => switch (key) {
    LevelSortKey.recent => l10n.levelSortRecent,
    LevelSortKey.diff => l10n.levelSortDiff,
    LevelSortKey.clears => l10n.levelSortClears,
    LevelSortKey.totalClears => l10n.levelSortTotalClears,
    LevelSortKey.likes => l10n.levelSortLikes,
    LevelSortKey.baseScore => l10n.levelSortBaseScore,
    LevelSortKey.bpm => l10n.levelSortBpm,
    LevelSortKey.tiles => l10n.levelSortTiles,
    LevelSortKey.time => l10n.levelSortTime,
    LevelSortKey.random => l10n.levelSortRandom,
  };
}

const sortOptions = [
  SortOption(LevelSortKey.recent),
  SortOption(LevelSortKey.diff),
  SortOption(LevelSortKey.clears),
  SortOption(LevelSortKey.totalClears),
  SortOption(LevelSortKey.likes),
  SortOption(LevelSortKey.baseScore),
  SortOption(LevelSortKey.bpm),
  SortOption(LevelSortKey.tiles),
  SortOption(LevelSortKey.time),
  SortOption(LevelSortKey.random),
];

class SpecialDifficultyGroup {
  const SpecialDifficultyGroup({required this.hidden, required this.items});

  /// true for the hidden group, false for the extra group.
  final bool hidden;

  String get title => hidden ? l10n.hidden : l10n.extra;
  final List<Difficulty> items;
}

/// Search text, filters, sort and the infinite level list.
class LevelsController extends ChangeNotifier {
  LevelsController({required this.api, required this.onStatus});

  static const pageSize = 30;
  static const _searchDebounce = Duration(milliseconds: 500);

  /// Difficulties the website's TagSelector puts in the "Hidden" group.
  static const _hiddenSpecialNames = {'Unranked', 'Impossible', 'Censored', 'P0'};

  final TufApiClient api;
  final void Function(String message) onStatus;

  DifficultyCatalog? catalog;

  // Search
  String _searchText = '';
  String _committedQuery = '';
  Timer? _debounceTimer;

  String get searchText => _searchText;
  bool get isSearchPending => _searchText.trim() != _committedQuery;

  bool filterOpen = true;

  // Difficulty
  int pguLower = 0;
  int pguUpper = 0;
  int qLower = 0;
  int qUpper = 0;
  bool includeQ = false;
  final Set<String> selectedSpecials = {};
  List<SpecialDifficultyGroup> specialGroups = const [];

  // Filters / sort / view
  FilterState clearedFilter = FilterState.show;
  FilterState availableDlFilter = FilterState.show;
  SortOption sort = sortOptions.first;
  bool ascending = false;
  bool compact = false;

  // Results
  final List<Level> levels = [];
  bool isSearching = false;
  bool isLoadingMore = false;
  bool hasMore = false;
  bool hasSearched = false;

  /// Why loading the next page failed. While set, the next page is not requested again until [retryLoadMore].
  String? loadMoreError;
  int total = 0;

  /// Notifies search box text changes alone (without rebuilding the list).
  final ValueNotifier<String> searchTextNotifier = ValueNotifier('');

  /// Incremented on every new search; the page scrolls back to the top when it changes.
  int searchGeneration = 0;
  int _nextOffset = 0;
  int? _seed;

  String? get qIconUrl => (catalog?.q.where((d) => d.name == 'Qq').firstOrNull ?? catalog?.q.firstOrNull)?.icon;

  int get activeFilterCount {
    final current = catalog;
    if (current == null) return 0;
    return [
      pguLower != 0 || pguUpper != current.pgu.length - 1,
      includeQ,
      selectedSpecials.isNotEmpty,
      selectedTagIds.isNotEmpty,
      selectedCurationIds.isNotEmpty,
      clearedFilter != FilterState.show,
      availableDlFilter != FilterState.show,
    ].where((changed) => changed).length;
  }

  /// Selected tags and curation types. Each can match any (default) or all.
  final Set<int> selectedTagIds = {};
  bool tagsMatchAll = false;
  final Set<int> selectedCurationIds = {};
  bool curationsMatchAll = false;

  FacetCatalog? tagCatalog;
  FacetCatalog? curationCatalog;

  void toggleTag(int id) {
    selectedTagIds.contains(id) ? selectedTagIds.remove(id) : selectedTagIds.add(id);
    search();
  }

  void clearTags() {
    if (selectedTagIds.isEmpty) return;
    selectedTagIds.clear();
    search();
  }

  void setTagsMatchAll(bool value) {
    if (tagsMatchAll == value) return;
    tagsMatchAll = value;
    selectedTagIds.length > 1 ? search() : notifyListeners();
  }

  void toggleCuration(int id) {
    selectedCurationIds.contains(id) ? selectedCurationIds.remove(id) : selectedCurationIds.add(id);
    search();
  }

  void clearCurations() {
    if (selectedCurationIds.isEmpty) return;
    selectedCurationIds.clear();
    search();
  }

  void setCurationsMatchAll(bool value) {
    if (curationsMatchAll == value) return;
    curationsMatchAll = value;
    selectedCurationIds.length > 1 ? search() : notifyListeners();
  }

  Future<void> initialize(DifficultyCatalog value, {FacetCatalog? tags, FacetCatalog? curationTypes}) {
    catalog = value;
    tagCatalog = tags;
    curationCatalog = curationTypes;
    specialGroups = [
      SpecialDifficultyGroup(
        hidden: false,
        items: value.special.where((d) => !_hiddenSpecialNames.contains(d.name)).toList(),
      ),
      SpecialDifficultyGroup(
        hidden: true,
        items: value.special.where((d) => _hiddenSpecialNames.contains(d.name)).toList(),
      ),
    ].where((g) => g.items.isNotEmpty).toList();
    _applyDefaultRange();
    return search();
  }

  /// Does not notify on every keystroke: rebuilding the whole list makes typing lag.
  /// Widgets that only care about the text (like the clear button) listen to [searchTextNotifier].
  void setSearchText(String value) {
    if (value == _searchText) return;
    _searchText = value;
    searchTextNotifier.value = value;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_searchDebounce, search);
  }

  void submitSearch() => search();

  void clearSearch() {
    _searchText = '';
    searchTextNotifier.value = '';
    search();
  }

  void toggleFilterOpen() {
    filterOpen = !filterOpen;
    notifyListeners();
  }

  void setPguRange(int lower, int upper) {
    pguLower = lower;
    pguUpper = upper;
    _filtersChanged();
  }

  void setQRange(int lower, int upper) {
    qLower = lower;
    qUpper = upper;
    _filtersChanged();
  }

  void setIncludeQ(bool value) {
    includeQ = value;
    _filtersChanged();
  }

  void toggleSpecial(String name) {
    if (!selectedSpecials.remove(name)) selectedSpecials.add(name);
    _filtersChanged();
  }

  /// Clears all if any is selected, otherwise selects all.
  void toggleAllSpecials() {
    if (selectedSpecials.isNotEmpty) {
      selectedSpecials.clear();
    } else {
      selectedSpecials.addAll(specialGroups.expand((g) => g.items).map((d) => d.name));
    }
    _filtersChanged();
  }

  void setClearedFilter(FilterState value) {
    clearedFilter = value;
    _filtersChanged();
  }

  void setAvailableDlFilter(FilterState value) {
    availableDlFilter = value;
    _filtersChanged();
  }

  void setSort(SortOption value) {
    sort = value;
    _filtersChanged();
  }

  void toggleOrder() {
    ascending = !ascending;
    _filtersChanged();
  }

  void setCompact(bool value) {
    compact = value;
    notifyListeners();
  }

  /// Resets search text, sort, difficulty range, special difficulties and filters.
  void resetAll() {
    _searchText = '';
    searchTextNotifier.value = '';
    sort = sortOptions.first;
    ascending = false;
    _applyDefaultRange();
    includeQ = false;
    selectedSpecials.clear();
    selectedTagIds.clear();
    selectedCurationIds.clear();
    tagsMatchAll = false;
    curationsMatchAll = false;
    clearedFilter = FilterState.show;
    availableDlFilter = FilterState.show;
    search();
  }

  void _applyDefaultRange() {
    final current = catalog;
    if (current == null) return;
    pguLower = 0;
    pguUpper = current.pgu.length - 1;
    qLower = 0;
    qUpper = max(0, current.q.length - 1);
  }

  void _filtersChanged() {
    notifyListeners();
    search();
  }

  /// Searches again from the first page. Late responses from earlier searches are ignored.
  Future<void> search() async {
    if (catalog == null) return;
    _debounceTimer?.cancel();

    _committedQuery = _searchText.trim();
    _seed = sort.key == LevelSortKey.random ? Random().nextInt(0x7FFFFFFE) + 1 : null;
    final generation = ++searchGeneration;
    isSearching = true;
    isLoadingMore = false;
    loadMoreError = null;
    notifyListeners();

    try {
      final page = await api.searchLevels(_buildQuery(0));
      if (generation != searchGeneration) return;

      levels
        ..clear()
        ..addAll(page.results);
      _nextOffset = page.results.length;
      hasMore = page.hasMore;
      total = page.total;
      hasSearched = true;
    } on TufApiException catch (e) {
      if (generation == searchGeneration) onStatus(l10n.searchFailed(e.message));
    } finally {
      if (generation == searchGeneration) {
        isSearching = false;
        notifyListeners();
      }
    }
  }

  /// Called by the page near the end of the list; appends the next page.
  Future<void> loadMore() async {
    if (catalog == null || !hasMore || isSearching || isLoadingMore || loadMoreError != null) return;

    final generation = searchGeneration;
    isLoadingMore = true;
    notifyListeners();

    try {
      final page = await api.searchLevels(_buildQuery(_nextOffset));
      if (generation != searchGeneration) return;

      levels.addAll(page.results);
      _nextOffset += page.results.length;
      hasMore = page.hasMore;
    } on TufApiException catch (e) {
      if (generation == searchGeneration) loadMoreError = e.message;
    } finally {
      if (generation == searchGeneration) {
        isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  /// Retries a failed next page ("Retry" at the bottom of the list).
  Future<void> retryLoadMore() {
    loadMoreError = null;
    return loadMore();
  }

  LevelSearchQuery _buildQuery(int offset) => LevelSearchQuery(
    query: _committedQuery.isEmpty ? null : _committedQuery,
    sort: LevelSort(sort.key, ascending ? SortDirection.asc : SortDirection.desc),
    difficultyFilter: catalog!.createFilter(
      pguLower: pguLower,
      pguUpper: pguUpper,
      qLower: qLower,
      qUpper: qUpper,
      includeQ: includeQ,
    ),
    specialDifficulties: selectedSpecials.toList(),
    facetQuery: buildFacetQuery(
      tags: FacetSelection(ids: selectedTagIds, matchAll: tagsMatchAll),
      curationTypes: FacetSelection(ids: selectedCurationIds, matchAll: curationsMatchAll),
    ),
    clearedFilter: clearedFilter,
    availableDlFilter: availableDlFilter,
    offset: offset,
    limit: pageSize,
    seed: _seed,
  );

  @override
  void dispose() {
    _debounceTimer?.cancel();
    searchTextNotifier.dispose();
    super.dispose();
  }
}

/// Sort order of the library list.
enum LibrarySort { name, size, recent }

Map<LibrarySort, String> get librarySortLabels => {
  LibrarySort.name: l10n.sortByName,
  LibrarySort.size: l10n.sortBySize,
  LibrarySort.recent: l10n.sortByRecent,
};

// ───────────────────────── Library ─────────────────────────

class LibraryController extends ChangeNotifier {
  LibraryController({required this.api, required this.installs, required this.onStatus});

  final TufApiClient api;
  final InstallCenter installs;
  final void Function(String message) onStatus;

  AppSettings? settings;
  LevelLibrary? library;
  LibraryOrganizer? organizer;

  /// Records folders left by going up so "forward" can return to them.
  NavigationHistory? history;

  /// What was repaired when the library index was found broken (null if nothing).
  String? recovery;

  /// The folder being viewed, relative to the library root (empty for the root).
  String currentPath = '';
  FolderContents? contents;

  /// Paths of the selected entries. Ctrl/Shift multi-select works like Explorer.
  final Set<String> selection = {};

  /// Notifies selection changes alone; rebuilding the whole list makes clicks feel sluggish.
  final ValueNotifier<int> selectionRevision = ValueNotifier(0);

  void _selectionChanged() => selectionRevision.value++;

  /// Anchor entry for Shift range selection.
  String? _selectionAnchor;

  /// The entry selected last (the moving end of a Shift range); arrow keys move from here.
  String? get selectionCursor => _selectionCursor;
  String? _selectionCursor;

  LibrarySort sort = LibrarySort.name;

  /// Entries in the chosen sort order, folders first.
  List<LibraryEntry> get entries {
    final current = contents;
    if (current == null) return const [];
    return [..._sorted(current.folders), ..._sorted(current.levels)];
  }

  List<LibraryEntry> get selectedEntries => [
    for (final entry in entries)
      if (selection.contains(entry.relativePath)) entry,
  ];

  List<LibraryEntry> _sorted(List<LibraryEntry> items) {
    final sorted = [...items];
    switch (sort) {
      case LibrarySort.name:
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case LibrarySort.size:
        sorted.sort((a, b) => _sizeOf(b).compareTo(_sizeOf(a)));
      case LibrarySort.recent:
        sorted.sort((a, b) => _installedAt(b).compareTo(_installedAt(a)));
    }
    return sorted;
  }

  static int _sizeOf(LibraryEntry entry) => entry is LevelEntry ? entry.level.sizeBytes : 0;

  static DateTime _installedAt(LibraryEntry entry) =>
      entry is LevelEntry ? entry.level.installedAt : DateTime.fromMillisecondsSinceEpoch(0);

  void setSort(LibrarySort value) {
    if (sort == value) return;
    sort = value;
    notifyListeners();
  }

  /// Explorer-style selection: click selects one, Ctrl toggles, Shift selects a range.
  void select(LibraryEntry entry, {bool toggle = false, bool range = false}) {
    _selectionCursor = entry.relativePath;
    final all = entries;
    if (range && _selectionAnchor != null) {
      final from = all.indexWhere((item) => item.relativePath == _selectionAnchor);
      final to = all.indexWhere((item) => item.relativePath == entry.relativePath);
      if (from >= 0 && to >= 0) {
        selection
          ..clear()
          ..addAll(all.sublist(min(from, to), max(from, to) + 1).map((item) => item.relativePath));
        _selectionChanged();
        return;
      }
    }

    if (toggle) {
      selection.contains(entry.relativePath) ? selection.remove(entry.relativePath) : selection.add(entry.relativePath);
    } else {
      selection
        ..clear()
        ..add(entry.relativePath);
    }
    _selectionAnchor = entry.relativePath;
    _selectionChanged();
  }

  void selectAll() {
    selection
      ..clear()
      ..addAll(entries.map((entry) => entry.relativePath));
    _selectionChanged();
  }

  void clearSelection() {
    if (selection.isEmpty) return;
    selection.clear();
    _selectionAnchor = _selectionCursor = null;
    _selectionChanged();
  }

  /// Dragging a selected entry moves the whole selection; otherwise just that entry.
  List<LibraryEntry> dragGroupFor(LibraryEntry entry) =>
      selection.contains(entry.relativePath) && selection.length > 1 ? selectedEntries : [entry];

  Future<void> goUp() {
    final index = currentPath.lastIndexOf('/');
    return openPath(index < 0 ? '' : currentPath.substring(0, index));
  }

  /// Path segments up to the current folder: [('Root', ''), ('Camellia', 'Camellia'), ...]
  List<(String name, String path)> get breadcrumb {
    final parts = currentPath.split('/').where((part) => part.isNotEmpty).toList();
    final crumbs = <(String, String)>[(l10n.root, '')];
    var path = '';
    for (final part in parts) {
      path = path.isEmpty ? part : '$path/$part';
      crumbs.add((part, path));
    }
    return crumbs;
  }

  /// Result of the last update check (level ID → newer level from the server).
  final Map<int, Level> _pendingUpdates = {};
  bool isCheckingUpdates = false;

  List<InstalledLevel> get installed => library?.getAll() ?? const [];
  int get installedCount => installed.length;
  int get totalSize => installed.fold(0, (sum, level) => sum + level.sizeBytes);
  int get updateCount => _pendingUpdates.length;
  String get rootPath => library?.rootPath ?? '';

  Level? updateFor(int levelId) => _pendingUpdates[levelId];

  Future<void> open(String path) async {
    final opened = await LevelLibrary.open(path);
    recovery = opened.recovery;
    await opened.pruneMissing();
    library = opened;
    organizer = LibraryOrganizer(opened);
    installs.manager = LevelManager(api, opened);
    _pendingUpdates.clear();
    currentPath = '';

    // Renames folders the game cannot load (names with '+'), including ones added by hand.
    final renamed = await organizer!.fixUnloadableNames();
    if (renamed > 0) {
      onStatus(l10n.replacedPlusInFolders(renamed));
    }

    await refreshContents();
  }

  /// Reloads the current folder; goes back to the root if it no longer exists.
  Future<void> refreshContents() async {
    final current = organizer;
    if (current == null) return;

    final watch = Stopwatch()..start();
    try {
      if (currentPath.isNotEmpty && !await Directory(current.fullPath(currentPath)).exists()) currentPath = '';
      contents = await current.list(currentPath);
      FrameLog.note('read folder', watch.elapsed, detail: currentPath.isEmpty ? '(root)' : currentPath);
      final alive = {for (final entry in contents!.all) entry.relativePath};
      selection.removeWhere((path) => !alive.contains(path));
      _selectionChanged();
    } on LibraryOperationException catch (e) {
      onStatus(e.message);
    } on FileSystemException catch (e) {
      onStatus(l10n.couldNotReadFolder(e.message));
    }
    notifyListeners();
  }

  Future<void> openPath(String relativePath) async {
    final from = currentPath;
    if (relativePath != from) {
      // Going up to a parent can be redone with "forward"; going anywhere else starts a new history.
      if (relativePath.isEmpty || from.startsWith('$relativePath/')) {
        history?.recordBack(() => openPath(from));
      } else {
        history?.clearForward();
      }
    }
    currentPath = relativePath;
    clearSelection();
    await refreshContents();
  }

  Future<void> createFolder(String name) => _organize((organizer) async {
    final created = await organizer.createFolder(currentPath, name);
    return l10n.createdFolder(created);
  });

  /// Whether touching this entry would collide with a running download:
  /// the downloading level itself, or any folder while downloads run (a pack download may be writing into it).
  /// Deleting or moving these would make the level reappear in the wrong place once the download finishes.
  bool _isBusy(LibraryEntry entry) => switch (entry) {
    LevelEntry(:final level) => installs.jobFor(level.levelId) != null,
    FolderEntry() => installs.activeCount > 0,
    ExternalLevelEntry() => false,
  };

  static String get _busyMessage => l10n.cantDoThisWhile;

  /// Drops entries that collide with downloads; also returns a note about how many were skipped.
  ({List<LibraryEntry> items, String skipped}) _withoutBusy(List<LibraryEntry> items) {
    final free = items.where((entry) => !_isBusy(entry)).toList();
    final skipped = items.length - free.length;
    return (items: free, skipped: skipped == 0 ? '' : l10n.skippedStillDownloading(skipped));
  }

  Future<void> renameEntry(LibraryEntry entry, String newName) => _organize((organizer) async {
    if (_isBusy(entry)) return _busyMessage;
    await organizer.rename(entry, newName);
    return l10n.renamedTo(newName);
  });

  /// Moves entries into one folder. One failure does not stop the rest.
  Future<void> moveEntries(List<LibraryEntry> all, String targetFolder) => _organize((organizer) async {
    final (:items, :skipped) = _withoutBusy(all);
    var moved = 0;
    final failures = <String>[];
    for (final entry in items) {
      try {
        await organizer.move(entry, targetFolder);
        moved++;
      } on LibraryOperationException catch (e) {
        failures.add('${entry.name}: ${e.message}');
      }
    }

    final where = targetFolder.isEmpty ? l10n.root : targetFolder;
    if (failures.isEmpty) {
      return l10n.movedItems(moved, where, skipped);
    }
    return l10n.movedButCouldNot(moved, failures.length, failures.first, skipped);
  });

  /// Deletes entries. Downloaded levels are also removed from the index.
  Future<void> deleteEntries(List<LibraryEntry> all) => _organize((organizer) async {
    final (:items, :skipped) = _withoutBusy(all);
    var count = 0;
    for (final entry in items) {
      if (entry is LevelEntry) {
        await installs.manager?.uninstall(entry.level.levelId);
        _pendingUpdates.remove(entry.level.levelId);
      } else {
        await organizer.delete(entry);
      }
      count++;
    }
    installs.refresh();
    return l10n.deletedItems(count, skipped);
  });

  Future<void> moveEntry(LibraryEntry entry, String targetFolder) => _organize((organizer) async {
    if (_isBusy(entry)) return _busyMessage;
    await organizer.move(entry, targetFolder);
    final where = targetFolder.isEmpty ? l10n.root : targetFolder;
    return l10n.movedEntry(entry.name, where);
  });

  /// Deletes a folder or an unindexed level folder entirely.
  Future<void> deleteEntry(LibraryEntry entry) => _organize((organizer) async {
    if (_isBusy(entry)) return _busyMessage;
    final removed = await organizer.delete(entry);
    installs.refresh();
    return removed == 0 ? l10n.deletedEntry(entry.name) : l10n.deletedWithLevels(removed, entry.name);
  });

  /// Lists one folder at a time for the move dialog, so large libraries stay fast.
  Future<FolderContents> browse(String relativePath) async {
    final current = organizer;
    if (current == null) return const FolderContents(path: '', folders: [], levels: []);
    try {
      return await current.list(relativePath);
    } on FileSystemException {
      return FolderContents(path: relativePath, folders: const [], levels: const []);
    }
  }

  Future<void> _organize(Future<String> Function(LibraryOrganizer organizer) action) async {
    final current = organizer;
    if (current == null) return;

    try {
      onStatus(await action(current));
    } on LibraryOperationException catch (e) {
      onStatus(e.message);
    } on FileSystemException catch (e) {
      onStatus(l10n.folderOperationFailed(e.message));
    }
    await refreshContents();
  }

  /// Called when downloads change; clears update marks of levels that now have the new version.
  void onInstallsChanged() {
    unawaited(refreshContents());
    final current = library;
    _pendingUpdates.removeWhere((id, remote) {
      final item = current?.get(id);
      return item == null || item.fileId.toLowerCase() == (remote.fileId ?? '').toLowerCase();
    });
    notifyListeners();
  }

  Future<void> checkUpdates() async {
    final manager = installs.manager;
    if (manager == null || isCheckingUpdates) return;

    isCheckingUpdates = true;
    onStatus(l10n.checkingForUpdates);
    notifyListeners();

    try {
      final missing = await manager.library.pruneMissing();
      final updates = await manager.checkUpdates();
      _pendingUpdates
        ..clear()
        ..addEntries(updates.map((u) => MapEntry(u.installed.levelId, u.remote)));

      final missingText = missing.isEmpty ? '' : l10n.removedMissingLevels(missing.length);
      final updateText = updates.isEmpty ? l10n.everythingIsUpTo : l10n.updatesAvailable(updates.length);
      onStatus(updateText + missingText);
    } on FileSystemException catch (e) {
      onStatus(l10n.couldNotCheckForUpdates(e.message));
    } finally {
      isCheckingUpdates = false;
      notifyListeners();
    }
  }

  Future<void> updateAll() async {
    for (final remote in _pendingUpdates.values.toList()) {
      await installs.install(remote);
    }
  }

  Future<void> uninstall(InstalledLevel level) async {
    final manager = installs.manager;
    if (manager == null || installs.jobFor(level.levelId) != null) return;

    try {
      await manager.uninstall(level.levelId);
      _pendingUpdates.remove(level.levelId);
      await refreshContents();
      onStatus(l10n.deletedLevel(level.song));
    } on FileSystemException catch (e) {
      onStatus(l10n.couldNotDelete(e.message));
    } finally {
      notifyListeners();
      // Also refresh the download buttons on the levels page.
      installs.refresh();
    }
  }

  Future<void> changeFolder() async {
    if (installs.activeCount > 0) {
      onStatus(l10n.cantChangeTheFolder);
      return;
    }

    final path = await getDirectoryPath(confirmButtonText: l10n.useThisFolder);
    if (path == null) return;

    try {
      await open(path);
      final current = settings ?? AppSettings(libraryPath: path);
      current.libraryPath = library!.rootPath;
      settings = current;
      await current.save();
      onStatus(l10n.libraryFolderChanged(library!.rootPath));
      installs.refresh();
      if (recovery case final message?) onStatus(message);
    } on FileSystemException catch (e) {
      onStatus(l10n.couldNotOpenFolder(e.message));
    }
  }

  Future<void> openFolder([InstalledLevel? level]) async {
    final current = library;
    if (current == null) return;
    await openFolderPath(level == null ? '' : level.folderName);
  }

  /// Opens a library-relative path in Explorer; the current folder if omitted.
  Future<void> openFolderPath([String? relativePath]) async {
    final current = organizer;
    if (current == null) return;
    try {
      final path = current.fullPath(relativePath?.isNotEmpty == true ? relativePath! : currentPath);
      if (!await Directory(path).exists()) return;
      await launchUrl(Uri.directory(path));
    } on LibraryOperationException catch (e) {
      onStatus(e.message);
    }
  }
}

String formatBytes(int bytes) {
  if (bytes >= 1024 * 1024 * 1024) return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  if (bytes >= 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  if (bytes >= 1024) return '${(bytes / 1024).round()} KB';
  return '$bytes B';
}
