import 'level_manager.dart';
import 'models/level.dart';

/// A value that can be put in the level folder name, written as `{name}` (case doesn't matter).
enum FolderTag {
  id,
  song,
  artist,
  creator,
  charter,
  vfxer,
  team,
  difficulty,
  bpm,
  tiles;

  String get token => '{$name}';

  String valueOf(Level level) => switch (this) {
    id => '${level.id}',
    song => level.song,
    artist => level.artist,
    creator => level.creatorDisplay ?? '',
    charter => level.creditedNames('charter').join(' & '),
    vfxer => level.creditedNames('vfxer').join(' & '),
    // Most levels have no team, so the creators stand in (the website shows them in the same place).
    team => level.team ?? level.creatorDisplay ?? '',
    difficulty => level.difficulty?.shortName ?? '',
    bpm => switch (level.bpm) {
      null || <= 0 => '',
      final bpm => bpm == bpm.roundToDouble() ? '${bpm.round()}' : '${double.parse(bpm.toStringAsFixed(2))}',
    },
    tiles => switch (level.tilecount) {
      null || <= 0 => '',
      final tiles => '$tiles',
    },
  };

  /// Free text that may be shortened when the name gets too long. Numbers and the difficulty are never cut.
  bool get isText => switch (this) {
    song || artist || creator || charter || vfxer || team => true,
    _ => false,
  };

  static FolderTag? named(String name) {
    final lower = name.toLowerCase();
    return values.where((tag) => tag.name == lower).firstOrNull;
  }
}

/// How a downloaded level's folder is named, e.g. "{artist} - {song} [{id}]".
/// '/' (or '\') in the template makes subfolders, e.g. "{artist}/{song}".
class LevelFolderTemplate {
  const LevelFolderTemplate._();

  /// The name used before templates existed: "#5947 4'33''".
  static const defaultTemplate = '#{id} {song}';

  static final _tag = RegExp(r'\{([^{}]*)\}');
  static final _emptyBrackets = RegExp(r'\(\s*\)|\[\s*\]|\{\s*\}|（\s*）|【\s*】|「\s*」');
  static final _repeatedSeparator = RegExp(r'\s*([-–—|&,·~])(?:\s*\1)+\s*');
  static final _edgeSeparators = RegExp(r'^[\s\-–—|&,·~]+|[\s\-–—|&,·~]+$');
  static final _spaces = RegExp(r'\s+');

  /// Stands in for a value while the template is tidied up; a control character never appears in a template.
  static const _marker = '\u0000';
  static final _markers = RegExp('$_marker(\\d+)$_marker');

  /// Tags in [template] that don't exist, as written (e.g. "{sogn}").
  static List<String> unknownTags(String template) => [
    for (final match in _tag.allMatches(template))
      if (FolderTag.named(match.group(1)!) == null) match.group(0)!,
  ];

  /// The folder path for [level], relative to where it is saved ('/'-separated, each part a safe folder name).
  /// An empty template falls back to [defaultTemplate].
  static String format(String template, Level level) {
    final source = template.trim().isEmpty ? defaultTemplate : template;
    final parts = [
      for (final segment in source.split(RegExp(r'[/\\]')))
        if (segment.trim().isNotEmpty) _formatSegment(segment, level),
    ].where((part) => part.isNotEmpty).toList();
    // A template that only produced empty values still needs a name, and the id keeps it unique.
    return parts.isEmpty ? LevelManager.safeFolderName('#${level.id}') : parts.join('/');
  }

  static String _formatSegment(String segment, Level level) {
    final values = <FolderTag, String>{};
    for (final match in _tag.allMatches(segment)) {
      if (FolderTag.named(match.group(1)!) case final tag?) {
        final value = tag.valueOf(level);
        values[tag] = value.trim().isEmpty ? '' : value;
      }
    }

    String build() {
      // Values go in as markers first, so tidying up only touches what the template itself wrote.
      // A title like "Altered⇄[     ]" keeps its spaces and brackets, and the default template gives the same
      // names as before templates existed.
      final inserted = <String>[];
      var text = segment.replaceAllMapped(_tag, (match) {
        final tag = FolderTag.named(match.group(1)!);
        if (tag == null) return match.group(0)!;
        final value = values[tag]!;
        if (value.isEmpty) return '';
        inserted.add(value);
        return '$_marker${inserted.length - 1}$_marker';
      });
      // Only tidy up when a value was empty, so separators the user wrote around real values stay as they are.
      if (values.values.any((value) => value.isEmpty)) {
        text = text
            .replaceAll(_emptyBrackets, '')
            .replaceAllMapped(_repeatedSeparator, (match) => ' ${match.group(1)} ')
            .replaceAll(_edgeSeparators, '')
            .replaceAll(_spaces, ' ');
      }
      return text.replaceAllMapped(_markers, (match) => inserted[int.parse(match.group(1)!)]).trim();
    }

    // Shorten the longest text value first, so the id and other short values survive the length limit.
    var name = build();
    while (name.length > LevelManager.maxFolderNameLength) {
      final longest = values.entries
          .where((entry) => entry.key.isText && entry.value.length > _minShortened)
          .fold<MapEntry<FolderTag, String>?>(
            null,
            (best, entry) => best == null || entry.value.length > best.value.length ? entry : best,
          );
      if (longest == null) break;
      final keep = (longest.value.length - (name.length - LevelManager.maxFolderNameLength)).clamp(
        _minShortened,
        longest.value.length - 1,
      );
      values[longest.key] = _cut(longest.value, keep);
      name = build();
    }
    return name.isEmpty ? '' : LevelManager.safeFolderName(name.replaceAll(_barWithSpaces, _bar));
  }

  static const _minShortened = 8;

  /// Windows doesn't allow '|' in folder names, and the creators are joined with it ("charter | VFX"),
  /// so it becomes the full-width bar that looks the same instead of '_'.
  static const _bar = '｜';

  /// The full-width bar already has room on both sides, so the spaces around it go ("A | B" → "A｜B").
  static final _barWithSpaces = RegExp(r' *\| *');

  /// The first [length] UTF-16 units, without splitting an emoji or other surrogate pair.
  static String _cut(String text, int length) {
    var end = length;
    if (end > 0 && end < text.length && _isHighSurrogate(text.codeUnitAt(end - 1))) end--;
    return text.substring(0, end).trimRight();
  }

  static bool _isHighSurrogate(int unit) => unit >= 0xD800 && unit <= 0xDBFF;
}
