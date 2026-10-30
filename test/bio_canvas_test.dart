import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tufapp/app/controllers.dart';
import 'package:tufapp/core/models/profile.dart';
import 'package:tufapp/core/tuf_api_client.dart';
import 'package:tufapp/ui/pages/profile/bio_canvas.dart';

/// Supporter bios are drawn as a free-form canvas like the website (real data: V0W4N, 2026-10).
void main() {
  String fixture(String name) => File('test/fixtures/$name.json').readAsStringSync();
  ProfileBio bio() => ProfileBio.fromJson(jsonDecode(fixture('player_174_bio')) as Map<String, dynamic>, stellar: true);

  group('읽기', () {
    test('블록마다 자리와 내용을 읽는다', () {
      final blocks = bio().blocks;
      // Image blocks without an uploaded image are left out, like the website renders nothing for them.
      expect(blocks.whereType<BioImageBlock>(), hasLength(6));
      expect(blocks.whereType<BioTextBlock>(), hasLength(20));

      final background = blocks.first as BioImageBlock;
      expect((background.layout.x, background.layout.y, background.layout.w, background.layout.h), (0, 0, 1000, 1200));

      final tilted = blocks.whereType<BioImageBlock>().firstWhere((block) => block.layout.rotation != 0);
      expect(tilted.layout.rotation, -6);
      expect(tilted.crop.contain, isTrue);

      final video = blocks.whereType<BioEmbedBlock>().single;
      expect((video.layout.x, video.layout.y, video.layout.w, video.layout.h), (234, 366, 532, 300));

      final social = blocks.whereType<BioSocialBlock>().first;
      expect([for (final link in social.links) link.platform], ['youtube', 'twitter']);
      expect((social.iconSize, social.gap, social.align), (69, 0, 'left'));

      final featured = blocks.whereType<BioFeaturedBlock>().single;
      expect(featured.ids, [8486, 7623, 11425, 6410, 7653]);
      expect(featured.layout.rotation, 5);
    });

    test('옛 배치(정렬·폭)는 위에서부터 쌓고, 값은 웹과 같은 범위로 자른다', () {
      final parsed = ProfileBio.fromJson({
        'bioCanvas': {
          'version': 1,
          'blocks': [
            {
              'id': 'a',
              'type': 'text',
              'layout': {'align': 'right', 'width': 'half'},
              'data': {'body': 'one'},
            },
            {
              'id': 'b',
              'type': 'link',
              'layout': {'align': 'center'},
              'data': {'label': 'Site', 'url': 'https://example.com'},
            },
            {
              'id': 'c',
              'type': 'text',
              'layout': {'x': 5000, 'y': -9999, 'w': 1, 'rotation': 720},
              'data': {'body': 'x', 'fontSize': 300, 'color': 'red'},
            },
            {
              'id': 'd',
              'type': 'link',
              'data': {'label': 'Bad', 'url': 'javascript:alert(1)'},
            },
          ],
        },
      }, stellar: true).blocks;

      expect(parsed, hasLength(3), reason: 'only http/https links');
      final first = parsed[0].layout;
      expect((first.x, first.y, first.w, first.h), (500, 24, 500, 120));
      final second = parsed[1].layout;
      expect((second.x, second.y, second.w, second.h), (0, 24 + 120 + 16, 1000, 56));
      final third = parsed[2] as BioTextBlock;
      expect((third.layout.x, third.layout.y, third.layout.w, third.layout.h), (1000, -1200, 40, 24));
      expect(third.layout.rotation, 360);
      expect(third.fontSize, 72);
      expect(third.color, isNull, reason: 'only #rgb or #rrggbb');
    });

    test('후원이 끝나면 글·링크·소셜만 글로 보여준다', () {
      final lapsed = ProfileBio.fromJson(jsonDecode(fixture('player_174_bio')) as Map<String, dynamic>, stellar: false);
      expect(lapsed.blocks, isEmpty);
      expect(lapsed.text, contains('youtube: https://www.youtube.com/@V0W4N'));
      expect(lapsed.text, contains('Sample text'));
    });
  });

  group('그리기', () {
    Future<List<Uri>> pump(WidgetTester tester, double width) async {
      await tester.binding.setSurfaceSize(Size(width, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final requested = <Uri>[];
      final client = MockClient((request) async {
        requested.add(request.url);
        return request.url.path == '/v2/database/levels'
            ? http.Response.bytes(utf8.encode(fixture('featured_levels')), 200)
            : http.Response('{}', 404);
      });
      final app = AppController(api: TufApiClient(client: client));
      addTearDown(app.dispose);

      await tester.pumpWidget(
        AppScope(
          controller: app,
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: width,
                  child: BioCanvas(blocks: bio().blocks),
                ),
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      return requested;
    }

    // Also on Windows: desktop scrollbars need their own scroll controller, unlike the default mobile platform.
    testWidgets(
      '1000 폭 무대에 블록을 겹쳐 그리고, 추천 레벨을 번호로 받아 온다',
      variant: TargetPlatformVariant.only(TargetPlatform.windows),
      (tester) async {
        final requested = await pump(tester, 1200);
        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(BioCanvas)).height, 1200, reason: 'never scaled up');
        expect(find.text('Sample text'), findsNWidgets(20));

        final query = requested.singleWhere((uri) => uri.path == '/v2/database/levels').queryParameters;
        expect(query['query'], 'id:8486 | id:7623 | id:11425 | id:6410 | id:7653');
        expect(find.text('Imaginary Legacy'), findsOneWidget);
      },
    );

    testWidgets('좁으면 무대 전체를 줄인다', (tester) async {
      await pump(tester, 500);
      expect(tester.takeException(), isNull);
      final stage = tester.getRect(find.byType(FittedBox).first);
      expect(stage.width, 500);
      expect(stage.height, 600);
    });
  });
}
