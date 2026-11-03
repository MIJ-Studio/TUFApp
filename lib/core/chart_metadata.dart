import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart' show visibleForTesting;

import 'models/level.dart';

/// Song, artist and author written in a level file's (.adofai) settings, as the game shows them.
typedef ChartInfo = ({String song, String artist, String author});

/// Fills in the song, artist and author of a level file from TUF.
///
/// A value is replaced when it is empty or differs from TUF. Rich text the creator added (`<color=...>`,
/// `<b>`, ...) doesn't count as a difference, so a decorated title that reads the same is kept.
/// The file is edited in place as text: everything else, including the BOM, formatting and trailing commas the
/// game allows, stays byte for byte, and a file that isn't valid UTF-8 is left alone.
class ChartMetadata {
  const ChartMetadata._();

  static const _keys = ['song', 'artist', 'author'];
  static const _bom = [0xEF, 0xBB, 0xBF];
  static final _richText = RegExp(r'</?[a-zA-Z]+(?:=[^>]*)?>');

  /// What TUF says about [level]: every creator in full, since the level file has room for all names.
  static ChartInfo infoOf(Level level) => (song: level.song, artist: level.artist, author: level.creatorFull ?? '');

  /// Updates the file at [path] in a background isolate (level files can be tens of MB).
  /// Returns whether the file was changed.
  static Future<bool> fill(String path, ChartInfo tuf) => Isolate.run(() => _fillFile(path, tuf));

  static bool _fillFile(String path, ChartInfo tuf) {
    final file = File(path);
    final bytes = file.readAsBytesSync();
    final hasBom = bytes.length >= 3 && bytes[0] == _bom[0] && bytes[1] == _bom[1] && bytes[2] == _bom[2];
    final String text;
    try {
      text = utf8.decode(hasBom ? bytes.sublist(3) : bytes);
    } on FormatException {
      return false;
    }

    final updated = apply(text, tuf);
    if (updated == null) return false;
    file.writeAsBytesSync([if (hasBom) ..._bom, ...utf8.encode(updated)], flush: true);
    return true;
  }

  /// [text] with the values replaced, or null when nothing needs to change (or no settings are found).
  @visibleForTesting
  static String? apply(String text, ChartInfo tuf) {
    final settings = _findSettings(text);
    if (settings == null) return null;

    final wanted = {'song': tuf.song.trim(), 'artist': tuf.artist.trim(), 'author': tuf.author.trim()};
    final edits = <({int start, int end, String text})>[];
    for (final key in _keys) {
      final value = wanted[key]!;
      // Never blank out what the creator wrote because TUF has nothing.
      if (value.isEmpty) continue;
      final found = settings.values[key];
      if (found == null) {
        edits.add((
          start: settings.contentStart,
          end: settings.contentStart,
          text: '\n\t\t"$key": ${jsonEncode(value)},',
        ));
      } else if (_plain(found.value) != value) {
        edits.add((start: found.start, end: found.end, text: jsonEncode(value)));
      }
    }
    if (edits.isEmpty) return null;

    // Apply from the end so earlier offsets stay valid.
    edits.sort((a, b) => b.start.compareTo(a.start));
    var result = text;
    for (final edit in edits) {
      result = result.replaceRange(edit.start, edit.end, edit.text);
    }
    return result;
  }

  /// Reads the value as shown in the game, without rich text and surrounding spaces.
  static String _plain(String value) => value.replaceAll(_richText, '').trim();

  /// Finds the top-level string values of the `"settings": {...}` object.
  /// Level files aren't strict JSON (trailing commas, raw line breaks in strings), so this scans the text
  /// instead of parsing it, and only the keys directly in settings are read.
  static ({int contentStart, Map<String, ({int start, int end, String value})> values})? _findSettings(String text) {
    final open = RegExp(r'"settings"\s*:\s*\{').firstMatch(text);
    if (open == null) return null;

    final values = <String, ({int start, int end, String value})>{};
    var depth = 1;
    var expectKey = true;
    String? key;
    var i = open.end;
    while (i < text.length && depth > 0) {
      final char = text[i];
      if (char == '"') {
        final end = _stringEnd(text, i);
        if (end < 0) return null;
        if (depth == 1) {
          if (expectKey) {
            key = _decode(text.substring(i + 1, end - 1));
            expectKey = false;
          } else if (key != null && _keys.contains(key)) {
            values.putIfAbsent(key, () => (start: i, end: end, value: _decode(text.substring(i + 1, end - 1))));
          }
        }
        i = end;
        continue;
      }
      switch (char) {
        case '{' || '[':
          depth++;
        case '}' || ']':
          depth--;
        case ',' when depth == 1:
          expectKey = true;
          key = null;
      }
      i++;
    }
    return depth == 0 ? (contentStart: open.end, values: values) : null;
  }

  /// Index just after the closing quote of the string starting at [start], or -1 if it never closes.
  static int _stringEnd(String text, int start) {
    for (var i = start + 1; i < text.length; i++) {
      final char = text[i];
      if (char == r'\') {
        i++;
      } else if (char == '"') {
        return i + 1;
      }
    }
    return -1;
  }

  /// Decodes JSON string escapes; raw line breaks and tabs (which the game accepts) are kept as they are.
  static String _decode(String raw) {
    if (!raw.contains(r'\')) return raw;
    try {
      final escaped = raw.replaceAll('\n', r'\n').replaceAll('\r', r'\r').replaceAll('\t', r'\t');
      return jsonDecode('"$escaped"') as String;
    } on FormatException {
      return raw;
    }
  }
}
