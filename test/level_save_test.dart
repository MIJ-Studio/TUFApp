import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:tufapp/core/level_library.dart';
import 'package:tufapp/core/level_manager.dart';
import 'package:tufapp/core/models/level.dart';
import 'package:tufapp/core/tuf_api_client.dart';

/// Downloads with the folder name template and level info filling, against a fake server.
void main() {
  late Directory root;
  late LevelLibrary library;
  late TufApiClient api;
  late AppSettings settings;
  late LevelManager manager;
  final detailRequests = <int>[];

  /// A zip with one level file whose info the creator left empty.
  List<int> zip() {
    final chart = utf8.encode('{"settings": {"artist": "", "song": "<b>Song</b>", "author": "", "version": 15 }, }');
    return ZipEncoder().encode(Archive()..addFile(ArchiveFile('main.adofai', chart.length, chart)));
  }

  Level level(int id, {String song = 'Song', String artist = 'Artist'}) =>
      Level(id: id, song: song, artist: artist, creator: 'search result', dlLink: 'https://cdn.tuforums.com/$id.zip');

  setUp(() async {
    root = await Directory.systemTemp.createTemp('tufapp_save_test_');
    detailRequests.clear();
    api = TufApiClient(
      client: MockClient((request) async {
        final path = request.url.path;
        if (request.url.host == 'cdn.tuforums.com') return http.Response.bytes(zip(), 200);
        if (RegExp(r'/levels/(\d+)$').firstMatch(path) case final match?) {
          final id = int.parse(match.group(1)!);
          detailRequests.add(id);
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'level': {
                  'id': id,
                  'song': 'Song',
                  'artist': 'Artist',
                  'levelCredits': [
                    {
                      'role': 'charter',
                      'sortOrder': 0,
                      'creator': {'id': 1, 'name': 'Charter A'},
                    },
                    {
                      'role': 'charter',
                      'sortOrder': 1,
                      'creator': {'id': 2, 'name': 'Charter B'},
                    },
                  ],
                },
              }),
            ),
            200,
          );
        }
        return http.Response('{}', 404);
      }),
    );
    library = await LevelLibrary.open(root.path);
    settings = AppSettings(libraryPath: root.path);
    manager = LevelManager(api, library, settings: () => settings);
  });

  tearDown(() async {
    api.close();
    await root.delete(recursive: true);
  });

  String chartOf(String folderName) => File(p.join(root.path, folderName, 'main.adofai')).readAsStringSync();

  test('설정한 형식으로 폴더를 만들고, 하위 폴더와 팩 폴더도 따른다', () async {
    settings.levelFolderTemplate = '{artist}/{song} [{id}]';
    final installed = await manager.install(level(10), parentFolder: 'Pack');
    expect(installed.folderName, 'Pack/Artist/Song [10]');
    expect(File(p.join(root.path, 'Pack', 'Artist', 'Song [10]', 'main.adofai')).existsSync(), isTrue);
    expect(detailRequests, isEmpty, reason: '제작자를 안 쓰면 레벨 정보를 다시 받지 않는다');
  });

  test('ID가 없는 형식에서 이름이 겹치면 ID를 붙이고, 있던 폴더는 지우지 않는다', () async {
    settings.levelFolderTemplate = '{artist} - {song}';
    final userFiles = Directory(p.join(root.path, 'Artist - Song'))..createSync();
    File(p.join(userFiles.path, 'mine.txt')).writeAsStringSync('keep me');

    final first = await manager.install(level(1));
    final second = await manager.install(level(2));
    expect(first.folderName, 'Artist - Song (1)');
    expect(second.folderName, 'Artist - Song (2)');
    expect(File(p.join(userFiles.path, 'mine.txt')).readAsStringSync(), 'keep me');

    // An update goes back into the level's own folder.
    final again = await manager.install(level(1));
    expect(again.folderName, 'Artist - Song (1)');
    expect(library.getAll(), hasLength(2));
  });

  test('레벨 정보 채우기를 켜면 받은 레벨 파일에 TUF 정보를 쓴다', () async {
    final off = await manager.install(level(3));
    expect(chartOf(off.folderName), contains('"author": ""'), reason: '꺼져 있으면 파일을 건드리지 않는다');

    settings.fillChartMetadata = true;
    final on = await manager.install(level(4));
    final text = chartOf(on.folderName);
    expect(text, contains('"artist": "Artist"'));
    expect(text, contains('"song": "<b>Song</b>"'), reason: '꾸밈만 다른 값은 그대로');
    expect(text, contains('"author": "Charter A & Charter B"'), reason: '검색 결과에 없는 크레딧은 레벨 정보로 채운다');
    expect(detailRequests, [4]);
  });
}
