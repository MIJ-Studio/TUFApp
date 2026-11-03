import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import 'json.dart';
import 'l10n.dart';
import 'zip_names.dart';

/// A downloaded level. Uses the same JSON format as the C# version, so existing libraries load as is.
class InstalledLevel {
  const InstalledLevel({
    required this.levelId,
    required this.song,
    required this.artist,
    this.creator,
    this.difficulty,
    required this.fileId,
    required this.folderName,
    this.mainChartPath,
    this.sizeBytes = 0,
    required this.installedAt,
  });

  factory InstalledLevel.fromJson(Map<String, dynamic> json) => InstalledLevel(
    levelId: asInt(json['levelId']),
    song: json['song'] as String? ?? '',
    artist: json['artist'] as String? ?? '',
    creator: asStringOrNull(json['creator']),
    difficulty: asStringOrNull(json['difficulty']),
    fileId: json['fileId'] as String? ?? '',
    folderName: json['folderName'] as String? ?? '',
    mainChartPath: asStringOrNull(json['mainChartPath']),
    sizeBytes: asInt(json['sizeBytes']),
    installedAt: DateTime.tryParse(json['installedAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
  );

  final int levelId;
  final String song;
  final String artist;
  final String? creator;
  final String? difficulty;

  /// CDN fileId at download time. A different value on the server means an update is available.
  final String fileId;

  /// Folder name relative to the library root.
  final String folderName;

  /// Path of the main .adofai file relative to the folder, or null if not found.
  final String? mainChartPath;
  final int sizeBytes;
  final DateTime installedAt;

  InstalledLevel copyWith({String? folderName}) => InstalledLevel(
    levelId: levelId,
    song: song,
    artist: artist,
    creator: creator,
    difficulty: difficulty,
    fileId: fileId,
    folderName: folderName ?? this.folderName,
    mainChartPath: mainChartPath,
    sizeBytes: sizeBytes,
    installedAt: installedAt,
  );

  Map<String, dynamic> toJson() => {
    'levelId': levelId,
    'song': song,
    'artist': artist,
    'creator': creator,
    'difficulty': difficulty,
    'fileId': fileId,
    'folderName': folderName,
    'mainChartPath': mainChartPath,
    'sizeBytes': sizeBytes,
    'installedAt': installedAt.toIso8601String(),
  };
}

/// Index of downloaded levels, stored as [indexFileName] in the library folder.
class LevelLibrary {
  LevelLibrary._(this.rootPath, Iterable<InstalledLevel> levels, {this.recovery}) {
    for (final level in levels) {
      _levels[level.levelId] = level;
    }
  }

  static const indexFileName = 'tufapp-library.json';

  /// Temporary folder used while downloading and extracting.
  static const tempFolderName = '.tufapp-tmp';

  final String rootPath;

  /// What was repaired because the index file was broken, or null if it was fine.
  final String? recovery;
  final Map<int, InstalledLevel> _levels = {};
  Future<void> _saveChain = Future.value();

  String get tempPath => p.join(rootPath, tempFolderName);

  static Future<LevelLibrary> open(String rootPath) async {
    final root = p.normalize(p.absolute(rootPath));
    await Directory(root).create(recursive: true);

    final index = File(p.join(root, indexFileName));
    if (!await index.exists()) return LevelLibrary._(root, const []);

    // A broken index must not crash the app. Level folders are never touched here.
    Object? json;
    try {
      json = jsonDecode(await index.readAsString());
    } on FormatException {
      json = null;
    }
    if (json is! List) {
      // Keep the unreadable file next to it instead of deleting it, and start with an empty index.
      final backup = '${index.path}.broken-${DateTime.now().millisecondsSinceEpoch}';
      await index.rename(backup);
      return LevelLibrary._(root, const [], recovery: l10n.couldntReadTheDownloaded(p.basename(backup)));
    }

    final levels = <InstalledLevel>[];
    var skipped = 0;
    for (final item in json) {
      final level = item is Map<String, dynamic> ? _tryParse(item) : null;
      // Skip entries with no folder name or one pointing outside the
      // library; deleting or updating them would be dangerous.
      if (level == null || !_isSafeFolderName(level.folderName)) {
        skipped++;
      } else {
        levels.add(level);
      }
    }
    return LevelLibrary._(root, levels, recovery: skipped == 0 ? null : l10n.removedUnreadableEntries(skipped));
  }

  static InstalledLevel? _tryParse(Map<String, dynamic> json) {
    try {
      return InstalledLevel.fromJson(json);
    } on TypeError {
      return null;
    } on FormatException {
      return null;
    }
  }

  /// Whether the name points to a subfolder of the library (not empty, not the root itself, not outside it).
  static bool _isSafeFolderName(String folderName) {
    final name = folderName.replaceAll(r'\', '/').trim();
    if (name.isEmpty || p.isAbsolute(name)) return false;
    final normalized = p.posix.normalize(name);
    return normalized != '.' && !normalized.startsWith('..');
  }

  /// Actual path of [level]'s folder, or null if it is the root or
  /// outside it (such paths must never be deleted or replaced).
  String? safeFolderPathOf(InstalledLevel level) {
    if (!_isSafeFolderName(level.folderName)) return null;
    final path = p.normalize(folderPathOf(level));
    return p.isWithin(rootPath, path) ? path : null;
  }

  /// Most recently downloaded first.
  List<InstalledLevel> getAll() => _levels.values.toList()..sort((a, b) => b.installedAt.compareTo(a.installedAt));

  InstalledLevel? get(int levelId) => _levels[levelId];

  bool contains(int levelId) => _levels.containsKey(levelId);

  String folderPathOf(InstalledLevel level) => p.join(rootPath, level.folderName);

  /// [wanted] ('/'-separated, relative to the root), or "[wanted] ({id})" (then "... 2", "... 3") when that folder
  /// already exists. A name without the id can be taken by another level, and an existing folder may hold other
  /// levels or the user's files, so it is never reused. [current] is the level's own folder, which may be renamed
  /// to the same name in different case (Windows sees those as one folder).
  Future<String> freeFolderName(String wanted, int levelId, {String? current}) async {
    final own = current == null ? null : _normalizePath(current).toLowerCase();
    var candidate = wanted;
    for (
      var attempt = 1;
      _normalizePath(candidate).toLowerCase() != own && await Directory(p.join(rootPath, candidate)).exists();
      attempt++
    ) {
      candidate = attempt == 1 ? '$wanted ($levelId)' : '$wanted ($levelId) $attempt';
    }
    return candidate;
  }

  Future<void> set(InstalledLevel level) {
    if (!_isSafeFolderName(level.folderName)) {
      throw FileSystemException(l10n.invalidLevelFolderName, level.folderName);
    }
    _levels[level.levelId] = level;
    return _save();
  }

  /// Updates the paths of all levels inside a folder that was moved or renamed.
  /// If [from] is a level folder itself, only that level changes.
  Future<void> movePath(String from, String to) async {
    final source = _normalizePath(from);
    final target = _normalizePath(to);
    if (source.isEmpty || source == target) return;

    var changed = false;
    for (final level in _levels.values.toList()) {
      final current = _normalizePath(level.folderName);
      final String moved;
      if (current == source) {
        moved = target;
      } else if (current.startsWith('$source/')) {
        moved = '$target${current.substring(source.length)}';
      } else {
        continue;
      }
      _levels[level.levelId] = level.copyWith(folderName: moved);
      changed = true;
    }
    if (changed) await _save();
  }

  static String _normalizePath(String path) => path.replaceAll(r'\', '/').replaceAll(RegExp(r'^/+|/+$'), '');

  Future<bool> remove(int levelId) async {
    final removed = _levels.remove(levelId) != null;
    if (removed) await _save();
    return removed;
  }

  /// Removes entries whose folder is gone (deleted by hand, for example).
  Future<List<InstalledLevel>> pruneMissing() async {
    final missing = <InstalledLevel>[];
    for (final level in _levels.values.toList()) {
      final path = safeFolderPathOf(level);
      if (path == null || !await Directory(path).exists()) missing.add(level);
    }
    for (final level in missing) {
      _levels.remove(level.levelId);
    }
    if (missing.isNotEmpty) await _save();
    return missing;
  }

  /// Chains saves so they never overlap. A failed save doesn't stop the next one.
  Future<void> _save() {
    _saveChain = _saveChain.catchError((Object _) {}).then((_) => _writeIndex());
    return _saveChain;
  }

  Future<void> _writeIndex() async {
    final snapshot = _levels.values.toList()..sort((a, b) => a.levelId.compareTo(b.levelId));
    final json = const JsonEncoder.withIndent('  ').convert(snapshot.map((l) => l.toJson()).toList());

    // Write a temporary file and swap it in so the index survives a crash mid-save.
    final temp = File(p.join(rootPath, '$indexFileName.tmp'));
    await temp.writeAsString(json);
    await temp.rename(p.join(rootPath, indexFileName));
  }
}

abstract final class LevelArchive {
  /// Extracts the zip into [destinationDir] and returns the total size of the extracted files.
  /// If everything sits in a single folder, that level is flattened; junk like __MACOSX is skipped.
  /// Heavy work, so it runs in an isolate.
  static int extract(String zipPath, String destinationDir) {
    final root = p.normalize(p.absolute(destinationDir));
    Directory(root).createSync(recursive: true);

    final input = InputFileStream(zipPath);
    try {
      final archive = ZipDecoder().decodeStream(input);
      final entries = archive.files.where((f) => !_isJunk(f.name)).toList();

      // Decode names (Korean, Japanese, ...) that old zip tools stored without the UTF-8 flag.
      final fixName = ZipNames.decoder(entries.map((f) => f.name), hint: _levelText(entries));
      final names = {for (final entry in entries) entry: _normalize(fixName(entry.name))};
      final prefix = _singleRootFolder(names.values);

      var total = 0;
      for (final entry in entries) {
        final relative = names[entry]!.substring(prefix.length);
        if (relative.isEmpty) continue;

        final target = p.normalize(p.join(root, relative));
        // Zip slip protection: reject paths that escape the target folder.
        if (!p.isWithin(root, target)) {
          throw FormatException(l10n.zipInvalidPath(entry.name));
        }

        if (!entry.isFile) {
          Directory(target).createSync(recursive: true);
          continue;
        }

        Directory(p.dirname(target)).createSync(recursive: true);
        final output = OutputFileStream(target);
        try {
          entry.writeContent(output);
        } finally {
          output.closeSync();
        }
        total += entry.size;
      }
      return total;
    } finally {
      input.closeSync();
    }
  }

  static String _normalize(String path) => path.replaceAll('\\', '/');

  /// A level file (.adofai) contains the music and image file names verbatim.
  /// It is used to pick the code page that decodes garbled names correctly.
  static String? _levelText(List<ArchiveFile> entries) {
    for (final entry in entries) {
      if (!entry.isFile) continue;
      if (!_normalize(entry.name).toLowerCase().endsWith('.adofai')) continue;
      if (entry.size > ZipNames.hintLimit) continue;

      final bytes = entry.readBytes();
      if (bytes == null) continue;
      return const Utf8Decoder(allowMalformed: true).convert(bytes);
    }
    return null;
  }

  static bool _isJunk(String name) {
    final path = _normalize(name).toLowerCase();
    return path.startsWith('__macosx/') || path == '.ds_store' || path.endsWith('/.ds_store');
  }

  /// "Folder/" if every entry starts with "Folder/", otherwise "".
  static String _singleRootFolder(Iterable<String> paths) {
    String? prefix;
    for (final path in paths) {
      final slash = path.indexOf('/');
      if (slash <= 0) return '';
      final first = path.substring(0, slash + 1);
      if (prefix == null) {
        prefix = first;
      } else if (prefix != first) {
        return '';
      }
    }
    return prefix ?? '';
  }
}
