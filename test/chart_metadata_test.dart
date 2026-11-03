import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tufapp/core/chart_metadata.dart';

/// Level files as the game writes them: tabs, spaces before commas, trailing commas.
String chart({String song = '', String artist = '', String author = '', String extra = ''}) =>
    '{\n'
    '\t"angleData": [0, 0, 0], \n'
    '\t"settings":\n'
    '\t{\n'
    '\t\t"version": 15 ,\n'
    '\t\t"artist": ${jsonEncode(artist)}, \n'
    '\t\t"specialArtistType": "None", \n'
    '\t\t"song": ${jsonEncode(song)}, \n'
    '\t\t"author": ${jsonEncode(author)}, \n'
    '\t\t"trackColor": "debb7b", \n'
    '$extra'
    '\t},\n'
    '\t"actions":\n'
    '\t[\n'
    '\t\t{ "floor": 1, "eventType": "EditorComment", "comment": "x", "song": "not a setting" },\n'
    '\t]\n'
    '}\n';

const tuf = (song: 'multi_arm', artist: 'Frums', author: 'Zagon');

/// The value of [key] in settings, read like the game does.
String? valueOf(String text, String key) {
  final match = RegExp('"$key": ("(?:[^"\\\\]|\\\\.)*")').firstMatch(text.substring(text.indexOf('"settings"')));
  return match == null ? null : jsonDecode(match.group(1)!) as String;
}

void main() {
  group('레벨 파일 정보 채우기', () {
    test('비어 있는 곡·작곡가·제작자를 TUF 정보로 채운다', () {
      final updated = ChartMetadata.apply(chart(), tuf)!;
      expect(valueOf(updated, 'song'), 'multi_arm');
      expect(valueOf(updated, 'artist'), 'Frums');
      expect(valueOf(updated, 'author'), 'Zagon');
    });

    test('다른 값은 덮어쓰고, 나머지 글자는 그대로 둔다', () {
      final original = chart(song: 'multi arm (old)', artist: 'Frums', author: 'someone');
      final updated = ChartMetadata.apply(original, tuf)!;
      expect(valueOf(updated, 'song'), 'multi_arm');
      expect(valueOf(updated, 'author'), 'Zagon');
      expect(
        updated,
        original.replaceFirst('"multi arm (old)"', '"multi_arm"').replaceFirst('"someone"', '"Zagon"'),
        reason: '바꾼 값 말고는 한 글자도 달라지면 안 된다',
      );
      expect(updated, contains('"song": "not a setting"'), reason: 'settings 밖의 같은 이름은 건드리지 않는다');
    });

    test('리치 텍스트로 꾸몄을 뿐 같은 값이면 그대로 둔다', () {
      final decorated = chart(
        song: '<color=#FF0000>multi</color>_arm',
        artist: '<b>Frums</b> ',
        author: '<size=40>Zagon</size>',
      );
      expect(ChartMetadata.apply(decorated, tuf), isNull);
    });

    test('대소문자만 달라도 다른 값이다', () {
      final updated = ChartMetadata.apply(chart(song: 'MULTI_ARM', artist: 'Frums', author: 'Zagon'), tuf)!;
      expect(valueOf(updated, 'song'), 'multi_arm');
    });

    test('TUF 쪽이 비어 있으면 원래 값을 지우지 않는다', () {
      final original = chart(song: 'multi_arm', artist: 'Frums', author: 'Zagon');
      expect(ChartMetadata.apply(original, (song: 'multi_arm', artist: '', author: ' ')), isNull);
    });

    test('이스케이프, 줄바꿈, 따옴표가 든 값도 읽고 쓴다', () {
      final original = chart(song: 'a "quoted"\nsong', artist: r'C:\path', author: 'Zagon');
      expect(ChartMetadata.apply(original, (song: 'a "quoted"\nsong', artist: r'C:\path', author: 'Zagon')), isNull);

      final raw = original.replaceFirst(r'"a \"quoted\"\nsong"', '"line\nbreak"');
      final updated = ChartMetadata.apply(raw, (song: 'Say "hi"', artist: r'C:\path', author: 'Zagon'))!;
      expect(valueOf(updated, 'song'), 'Say "hi"');
    });

    test('settings에 키가 없으면 넣는다', () {
      final original = chart(artist: 'Frums', author: 'Zagon').replaceFirst(RegExp(r'\t\t"song": "", \n'), '');
      final updated = ChartMetadata.apply(original, tuf)!;
      expect(valueOf(updated, 'song'), 'multi_arm');
    });

    test('settings가 없거나 닫히지 않으면 손대지 않는다', () {
      expect(ChartMetadata.apply('{"pathData": "RRRR"}', tuf), isNull);
      expect(ChartMetadata.apply('{"settings": {"song": "x", ', tuf), isNull);
    });

    test('파일: BOM을 지키고, UTF-8이 아니면 그대로 둔다', () async {
      final dir = await Directory.systemTemp.createTemp('tufapp_chart_test_');
      addTearDown(() => dir.delete(recursive: true));

      final withBom = File(p.join(dir.path, 'main.adofai'))
        ..writeAsBytesSync([0xEF, 0xBB, 0xBF, ...utf8.encode(chart(song: '곡'))]);
      expect(await ChartMetadata.fill(withBom.path, tuf), isTrue);
      final bytes = withBom.readAsBytesSync();
      expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
      expect(valueOf(utf8.decode(bytes.sublist(3)), 'song'), 'multi_arm');
      expect(await ChartMetadata.fill(withBom.path, tuf), isFalse, reason: '두 번째는 바꿀 게 없다');

      final latin = File(p.join(dir.path, 'old.adofai'))..writeAsBytesSync([...latin1.encode(chart(song: 'café'))]);
      final before = latin.readAsBytesSync();
      expect(await ChartMetadata.fill(latin.path, tuf), isFalse);
      expect(latin.readAsBytesSync(), before);
    });
  });
}
