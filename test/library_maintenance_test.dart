import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:tufapp/core/level_library.dart';
import 'package:tufapp/core/library_maintenance.dart';
import 'package:tufapp/core/tuf_api_client.dart';

/// Applying the folder name format and level info filling to levels already downloaded.
void main() {
  late Directory root;
  late LevelLibrary library;
  late TufApiClient api;
  final requests = <List<int>>[];
  final failingIds = <int>{};

  Map<String, Object> levelJson(int id) => {
    'id': id,
    'song': 'Song $id',
    'artist': 'Artist',
    'levelCredits': [
      {
        'role': 'charter',
        'sortOrder': 0,
        'creator': {'id': 1, 'name': 'Charter'},
      },
    ],
  };

  setUp(() async {
    root = await Directory.systemTemp.createTemp('tufapp_maintenance_test_');
    requests.clear();
    failingIds.clear();
    api = TufApiClient(
      client: MockClient((request) async {
        final query = request.url.queryParameters['query'] ?? '';
        final ids = [for (final match in RegExp(r'id:(\d+)').allMatches(query)) int.parse(match.group(1)!)];
        requests.add(ids);
        // Like the real server, which turns down longer search text.
        if (query.length > 255) return http.Response('{"error":"Query parameter exceeds 255 characters"}', 400);
        if (ids.any(failingIds.contains)) return http.Response('{}', 500);
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'results': [for (final id in ids) levelJson(id)],
            }),
          ),
          200,
        );
      }),
    );
    library = await LevelLibrary.open(root.path);
  });

  tearDown(() async {
    api.close();
    await root.delete(recursive: true);
  });

  /// A downloaded level in [folder] with an empty level file.
  Future<InstalledLevel> add(int id, String folder) async {
    final dir = Directory(p.join(root.path, folder))..createSync(recursive: true);
    File(p.join(dir.path, 'main.adofai')).writeAsStringSync('{"settings": {"song": "", "artist": "", "author": ""}}');
    final level = InstalledLevel(
      levelId: id,
      song: 'Song $id',
      artist: 'Artist',
      fileId: 'f$id',
      folderName: folder,
      mainChartPath: 'main.adofai',
      installedAt: DateTime(2026),
    );
    await library.set(level);
    return level;
  }

  test('ID 검색은 서버 한도(255자)에 맞게 나눈다', () {
    final ids = [for (var id = 10000; id < 10100; id++) id];
    final batches = TufApiClient.idBatches(ids);
    expect(batches.expand((batch) => batch), ids, reason: '빠짐없이 순서대로');
    for (final batch in batches) {
      expect(batch.map((id) => 'id:$id').join(' | ').length, lessThanOrEqualTo(255));
    }
    expect(batches.first, hasLength(23), reason: '"id:12345 | " 11자씩, 한도까지 채운다');
    expect(TufApiClient.idBatches([]), isEmpty);
  });

  test('TUF 정보를 나눠 받고, 실패한 묶음은 빼고 계속한다', () async {
    final levels = [for (var id = 10000; id < 10120; id++) await add(id, '#$id')];
    final batches = TufApiClient.idBatches([for (final level in levels) level.levelId]);
    failingIds.add(batches[1].first);
    final progress = <int>[];
    final info = await LibraryMaintenance(api, library).fetchInfo(levels, onProgress: (done, _) => progress.add(done));
    expect(requests, hasLength(batches.length));
    expect(info.length, 120 - batches[1].length, reason: '두 번째 묶음만 실패');
    expect(info[10000]!.creatorFull, 'Charter', reason: '검색 결과에 크레딧이 들어 있다');
    expect(progress.last, 120);
  });

  test('하나도 못 받으면 "바꿀 게 없음"이 아니라 오류로 알린다', () async {
    final levels = [await add(1, '#1'), await add(2, '#2')];
    failingIds.addAll([1, 2]);
    await expectLater(LibraryMaintenance(api, library).fetchInfo(levels), throwsA(isA<TufApiException>()));
  });

  test('맨 위 레벨은 형식 전체를, 폴더 안 레벨은 자기 폴더 이름만 바꾼다', () async {
    final top = await add(1, '#1 Song 1');
    final sorted = await add(2, 'Favorites/#2 Song 2');
    final done = await add(3, 'Artist/Song 3');
    final noInfo = await add(4, '#4 Song 4');
    final info = await LibraryMaintenance(api, library).fetchInfo([top, sorted, done]);

    final plans = LibraryMaintenance.planRenames([top, sorted, done, noInfo], info, '{artist}/{song}');
    expect(
      [for (final plan in plans) (plan.from, plan.to)],
      [('#1 Song 1', 'Artist/Song 1'), ('Favorites/#2 Song 2', 'Favorites/Song 2')],
      reason: '이미 형식을 따르는 레벨과 TUF 정보가 없는 레벨은 빠진다',
    );
  });

  test('폴더를 옮기고 목록을 고치며, 겹치는 이름에는 ID를 붙이고 남의 폴더는 건드리지 않는다', () async {
    final first = await add(1, '#1 Song 1');
    final second = await add(2, '#2 Song 2');
    final busy = await add(3, '#3 Song 3');
    File(p.join(root.path, 'Taken', 'mine.txt'))
      ..createSync(recursive: true)
      ..writeAsStringSync('keep');
    final maintenance = LibraryMaintenance(api, library);

    final result = await maintenance.rename([
      FolderRename(level: first, from: first.folderName, to: 'Taken'),
      FolderRename(level: second, from: second.folderName, to: 'Taken'),
      FolderRename(level: busy, from: busy.folderName, to: 'Busy'),
    ], skip: (id) => id == 3);

    expect(result.renamed, 2);
    expect(library.get(1)!.folderName, 'Taken (1)');
    expect(library.get(2)!.folderName, 'Taken (2)');
    expect(library.get(3)!.folderName, '#3 Song 3', reason: '받는 중인 레벨은 건너뛴다');
    expect(File(p.join(root.path, 'Taken (1)', 'main.adofai')).existsSync(), isTrue);
    expect(File(p.join(root.path, 'Taken', 'mine.txt')).readAsStringSync(), 'keep');
    expect(Directory(p.join(root.path, '#1 Song 1')).existsSync(), isFalse);

    final reopened = await LevelLibrary.open(root.path);
    expect(reopened.get(1)!.folderName, 'Taken (1)', reason: '목록 파일에도 저장된다');
  });

  test('대소문자만 바뀌는 이름도 바꾼다 (Windows는 같은 폴더로 본다)', () async {
    final level = await add(1, 'song 1');
    await LibraryMaintenance(api, library).rename([FolderRename(level: level, from: 'song 1', to: 'Song 1')]);
    expect(library.get(1)!.folderName, 'Song 1');
    expect(Directory(root.path).listSync().map((entity) => p.basename(entity.path)), contains('Song 1'));
  });

  test('받은 레벨 파일에 TUF 정보를 채우고 바뀐 수를 센다', () async {
    final levels = [await add(1, '#1'), await add(2, '#2')];
    final maintenance = LibraryMaintenance(api, library);
    final info = await maintenance.fetchInfo(levels);

    final result = await maintenance.fillCharts(levels, info);
    expect(result, (changed: 2, failed: 0));
    final text = File(p.join(root.path, '#1', 'main.adofai')).readAsStringSync();
    expect(text, '{"settings": {"song": "Song 1", "artist": "Artist", "author": "Charter"}}');

    expect(await maintenance.fillCharts(levels, info), (changed: 0, failed: 0), reason: '두 번째는 바꿀 게 없다');
  });
}
