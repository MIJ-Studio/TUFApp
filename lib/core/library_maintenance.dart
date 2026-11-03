import 'dart:io';

import 'package:path/path.dart' as p;

import 'chart_metadata.dart';
import 'folder_template.dart';
import 'level_library.dart';
import 'models/level.dart';
import 'tuf_api_client.dart';

/// A downloaded level's folder and the name the current template gives it.
class FolderRename {
  const FolderRename({required this.level, required this.from, required this.to});

  final InstalledLevel level;

  /// Current folder, relative to the library root.
  final String from;

  /// New folder, relative to the library root. A "({id})" is added when it is taken by then.
  final String to;
}

/// What applying the download settings to the library would do, shown to the user before anything changes.
class LibraryApplyPlan {
  const LibraryApplyPlan({required this.renames, required this.info});

  final List<FolderRename> renames;

  /// Current TUF info of the downloaded levels, for filling in their level files.
  final Map<int, Level> info;
}

/// Applies the settings for new downloads (folder names, level info) to levels already in the library.
class LibraryMaintenance {
  LibraryMaintenance(this._api, this.library);

  final TufApiClient _api;
  final LevelLibrary library;

  /// Current TUF info of [levels] by id, fetched in batches. Deleted levels and failed batches are left out.
  /// Throws [TufApiException] when nothing could be fetched, so a dead connection isn't read as "nothing to do".
  Future<Map<int, Level>> fetchInfo(
    List<InstalledLevel> levels, {
    void Function(int done, int total)? onProgress,
  }) async {
    final result = <int, Level>{};
    final ids = [for (final level in levels) level.levelId];
    var done = 0;
    TufApiException? lastError;
    for (final batch in TufApiClient.idBatches(ids)) {
      try {
        for (final level in await _api.getLevelsByIds(batch)) {
          result[level.id] = level;
        }
      } on TufApiException catch (e) {
        // Levels in a failed batch are just not changed.
        lastError = e;
      }
      done += batch.length;
      onProgress?.call(done, ids.length);
    }
    if (result.isEmpty && lastError != null) throw lastError;
    return result;
  }

  /// Folders whose name differs from what [template] gives now.
  ///
  /// A level at the top of the library gets the whole template, subfolders included. A level the user put in a
  /// folder (or that came with a pack) stays in that folder and only its own folder is renamed, after the
  /// template's last part, so the user's organization is kept.
  static List<FolderRename> planRenames(Iterable<InstalledLevel> levels, Map<int, Level> info, String template) {
    final plans = <FolderRename>[];
    for (final level in levels) {
      final tuf = info[level.levelId];
      if (tuf == null) continue;
      final from = _normalize(level.folderName);
      final parent = p.posix.dirname(from);
      final formatted = LevelFolderTemplate.format(template, tuf);
      final to = parent == '.' ? formatted : '$parent/${formatted.split('/').last}';
      if (to != from) plans.add(FolderRename(level: level, from: from, to: to));
    }
    plans.sort((a, b) => a.from.toLowerCase().compareTo(b.from.toLowerCase()));
    return plans;
  }

  /// Renames the folders. One failure (a folder open in the game, ...) doesn't stop the rest.
  /// [skip] leaves out levels that must not be touched now (being downloaded).
  Future<({int renamed, List<String> failures})> rename(
    List<FolderRename> plans, {
    bool Function(int levelId)? skip,
    void Function(int done, int total)? onProgress,
  }) async {
    var renamed = 0;
    final failures = <String>[];
    for (final (index, plan) in plans.indexed) {
      final level = library.get(plan.level.levelId);
      if (level != null && skip?.call(level.levelId) != true && library.safeFolderPathOf(level) != null) {
        try {
          await _move(level, plan.to);
          renamed++;
        } on FileSystemException catch (e) {
          failures.add('${plan.from}: ${e.osError?.message ?? e.message}');
        }
      }
      onProgress?.call(index + 1, plans.length);
    }
    return (renamed: renamed, failures: failures);
  }

  Future<void> _move(InstalledLevel level, String wanted) async {
    final from = _normalize(level.folderName);
    final source = Directory(p.join(library.rootPath, from));
    // A folder deleted by hand is cleaned up by the next update check, not here.
    if (!await source.exists()) return;

    final to = await library.freeFolderName(wanted, level.levelId, current: from);
    if (to == from) return;
    final target = p.join(library.rootPath, to);
    if (!p.isWithin(library.rootPath, target)) return;
    await Directory(p.dirname(target)).create(recursive: true);
    await source.rename(target);
    await library.movePath(from, to);
  }

  /// Writes TUF's song, artist and author into each level's main level file where they are empty or differ
  /// (see [ChartMetadata]).
  Future<({int changed, int failed})> fillCharts(
    List<InstalledLevel> levels,
    Map<int, Level> info, {
    void Function(int done, int total)? onProgress,
  }) async {
    var changed = 0;
    var failed = 0;
    for (final (index, level) in levels.indexed) {
      final tuf = info[level.levelId];
      final folder = library.safeFolderPathOf(level);
      final chart = level.mainChartPath;
      if (tuf != null && folder != null && chart != null) {
        try {
          final path = p.join(folder, chart);
          if (await File(path).exists() && await ChartMetadata.fill(path, ChartMetadata.infoOf(tuf))) changed++;
        } on FileSystemException {
          failed++;
        }
      }
      onProgress?.call(index + 1, levels.length);
    }
    return (changed: changed, failed: failed);
  }

  static String _normalize(String path) => path.replaceAll(r'\', '/').replaceAll(RegExp(r'^/+|/+$'), '');
}
