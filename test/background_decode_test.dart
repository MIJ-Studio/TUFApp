import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tufapp/core/models/difficulty.dart';
import 'package:tufapp/core/tuf_api_client.dart';

/// Big responses are decoded (and packs parsed) on a background isolate; the result must be the same.
void main() {
  Map<String, dynamic> level(int id) => {
    'id': id,
    'song': 'Song $id',
    'artist': 'Artist',
    'diffId': 16,
    'dlLink': 'https://cdn.tuforums.com/zips/$id',
  };

  Map<String, dynamic> pack(int levels) => {
    'id': 'p',
    'name': 'Pack',
    'levelCount': levels,
    'items': [
      {
        'id': 1,
        'type': 'folder',
        'name': 'Folder',
        'sortOrder': 0,
        'children': [
          for (var i = 0; i < levels; i++)
            {'id': 100 + i, 'type': 'level', 'sortOrder': levels - i, 'referencedLevel': level(i + 1)},
        ],
      },
    ],
  };

  TufApiClient client(Map<String, dynamic> body) =>
      TufApiClient(client: MockClient((_) async => http.Response.bytes(utf8.encode(jsonEncode(body)), 200)));

  for (final (name, levels) in [('작은 팩은 그 자리에서', 3), ('큰 팩은 백그라운드에서', 600)]) {
    test('$name 읽어도 결과가 같고, 레벨 정보를 채워 넣는다', () async {
      final body = pack(levels);
      if (levels > 100) expect(utf8.encode(jsonEncode(body)).length, greaterThan(64 * 1024));

      const difficulty = Difficulty(id: 16, name: 'U1', color: '#ffffff');
      final detail = await client(body).getPack('p', resolveLevel: (level) => level.copyWith(difficulty: difficulty));

      final all = detail.allLevels.toList();
      expect(all, hasLength(levels));
      expect(all.first.level.song, 'Song $levels', reason: 'sortOrder 순서');
      expect(all.every((entry) => entry.level.difficulty?.name == 'U1'), isTrue);
    });
  }

  test('큰 응답이 깨져 있으면 읽을 수 없다고 알린다', () async {
    final broken = '{"levels": [${List.filled(20000, '"x"').join(',')}';
    final api = TufApiClient(client: MockClient((_) async => http.Response(broken, 200)));
    await expectLater(api.getPack('p'), throwsA(isA<TufApiException>()));
  });
}
