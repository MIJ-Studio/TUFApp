import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:tufapp/app/controllers.dart';
import 'package:tufapp/core/level_library.dart';
import 'package:tufapp/core/level_manager.dart';
import 'package:tufapp/core/tuf_api_client.dart';
import 'package:tufapp/ui/pages/settings_page.dart';

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('tufapp_settings_test_');
    AppSettings.directoryForTesting = dir.path;
  });

  tearDown(() {
    AppSettings.directoryForTesting = null;
    dir.deleteSync(recursive: true);
  });

  test('설정 파일: 새 항목을 읽고 쓰며, 기본값은 쓰지 않는다', () async {
    final file = File(p.join(dir.path, 'settings.json'));
    await AppSettings(libraryPath: dir.path).save();
    expect((jsonDecode(file.readAsStringSync()) as Map).keys, ['libraryPath'], reason: 'C# 버전도 읽을 수 있게');

    await AppSettings(libraryPath: dir.path, levelFolderTemplate: '{artist} - {song}', fillChartMetadata: true).save();
    final loaded = await AppSettings.load();
    expect(loaded.levelFolderTemplate, '{artist} - {song}');
    expect(loaded.fillChartMetadata, isTrue);

    file.writeAsStringSync('{"libraryPath": "x", "levelFolderTemplate": "  ", "fillChartMetadata": "yes"}');
    final odd = await AppSettings.load();
    expect(odd.levelFolderTemplate, isNull, reason: '빈 형식은 기본값');
    expect(odd.fillChartMetadata, isFalse, reason: 'true가 아니면 끔');
  });

  testWidgets(
    '설정 화면: 형식을 고치면 예시가 바로 바뀌고, 태그 버튼과 스위치가 설정을 바꾼다',
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = AppController(api: TufApiClient(client: MockClient((_) async => http.Response('{}', 404))));
      addTearDown(app.dispose);
      app.library.settings = AppSettings(libraryPath: dir.path);

      await tester.pumpWidget(
        AppScope(
          controller: app,
          child: const MaterialApp(home: SettingsPage()),
        ),
      );
      expect(find.text('예시: #1 multi_arm'), findsOneWidget, reason: '기본 형식, TUF 1번 레벨 (서버가 안 되면 저장해 둔 정보)');

      await tester.enterText(find.byKey(SettingsPage.folderTemplateKey), '{Artist} - {song} [{id}]');
      await tester.pump();
      expect(find.text('예시: Frums - multi_arm [1]'), findsOneWidget);
      expect(app.levelFolderTemplate, '{Artist} - {song} [{id}]');
      expect(find.textContaining('뒤에 레벨 ID가 붙습니다'), findsNothing, reason: 'ID가 있으면 안내하지 않는다');

      await tester.tap(find.widgetWithText(ActionChip, '{bpm}  BPM'));
      await tester.pump();
      expect(app.levelFolderTemplate, '{Artist} - {song} [{id}]{bpm}', reason: '커서 자리에 넣는다');

      await tester.enterText(find.byKey(SettingsPage.folderTemplateKey), '{sogn} {song}');
      await tester.pump();
      expect(find.text('없는 태그(적은 그대로 남습니다): {sogn}'), findsOneWidget);
      expect(find.textContaining('뒤에 레벨 ID가 붙습니다'), findsOneWidget);

      await tester.tap(find.byTooltip('기본값으로 되돌리기'));
      await tester.pump();
      expect(app.library.settings!.levelFolderTemplate, isNull, reason: '기본값은 저장하지 않는다');

      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(app.fillChartMetadata, isTrue);
      expect(app.library.settings!.fillChartMetadata, isTrue, reason: '저장되는 설정에 들어간다 (파일은 위 테스트)');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '받은 레벨에 적용: 바뀔 내용을 먼저 보여 주고, 취소하면 아무것도 바꾸지 않는다',
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = AppController(
        api: TufApiClient(
          client: MockClient(
            (_) async => http.Response.bytes(
              utf8.encode(
                jsonEncode({
                  'results': [
                    {'id': 7, 'song': 'Song', 'artist': 'Artist'},
                  ],
                }),
              ),
              200,
            ),
          ),
        ),
      );
      addTearDown(app.dispose);
      final libraryDir = Directory(p.join(dir.path, 'library'));
      await tester.runAsync(() async {
        await Directory(p.join(libraryDir.path, '#7 Song')).create(recursive: true);
        final library = await LevelLibrary.open(libraryDir.path);
        await library.set(
          InstalledLevel(
            levelId: 7,
            song: 'Song',
            artist: 'Artist',
            fileId: 'f',
            folderName: '#7 Song',
            installedAt: DateTime(2026),
          ),
        );
        await app.library.open(libraryDir.path);
      });
      app.library.settings = AppSettings(libraryPath: libraryDir.path, levelFolderTemplate: '{artist} - {song}');

      await tester.pumpWidget(
        AppScope(
          controller: app,
          child: const MaterialApp(home: SettingsPage()),
        ),
      );
      await tester.tap(find.widgetWithText(OutlinedButton, '적용'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('받은 레벨에 적용할까요?'), findsOneWidget);
      expect(find.text('폴더 1개 이름 바꾸기'), findsOneWidget);
      expect(find.text('레벨 정보를 TUF 정보로 채우기'), findsOneWidget, reason: '설정 화면의 스위치 제목');
      expect(find.textContaining('받은 레벨 1개의 파일을'), findsNothing, reason: '정보 채우기가 꺼져 있으면 파일은 건드리지 않는다');
      expect(find.text('#7 Song'), findsOneWidget);
      expect(find.text('Artist - Song'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(app.library.installed.single.folderName, '#7 Song');
      expect(app.library.isMaintaining, isFalse);
    },
  );

  test('적용: 폴더 이름을 바꾼 뒤, 켜져 있으면 옮겨진 폴더의 레벨 파일에 정보를 채운다', () async {
    final app = AppController(
      api: TufApiClient(
        client: MockClient(
          (_) async => http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'results': [
                  {'id': 7, 'song': 'Song', 'artist': 'Artist', 'creator': 'Maker'},
                ],
              }),
            ),
            200,
          ),
        ),
      ),
    );
    addTearDown(app.dispose);
    final libraryDir = Directory(p.join(dir.path, 'library'));
    File(p.join(libraryDir.path, '#7 Song', 'main.adofai'))
      ..createSync(recursive: true)
      ..writeAsStringSync('{"settings": {"song": "", "artist": "", "author": ""}}');
    final library = await LevelLibrary.open(libraryDir.path);
    await library.set(
      InstalledLevel(
        levelId: 7,
        song: 'Song',
        artist: 'Artist',
        fileId: 'f',
        folderName: '#7 Song',
        mainChartPath: 'main.adofai',
        installedAt: DateTime(2026),
      ),
    );
    await app.library.open(libraryDir.path);

    final plan = await app.library.planApply('{artist} - {song}');
    expect(plan!.renames.single.to, 'Artist - Song');
    await app.library.apply(plan, fill: true);

    expect(app.library.installed.single.folderName, 'Artist - Song');
    expect(
      File(p.join(libraryDir.path, 'Artist - Song', 'main.adofai')).readAsStringSync(),
      '{"settings": {"song": "Song", "artist": "Artist", "author": "Maker"}}',
    );
    expect(app.status, '폴더 1개의 이름을 바꿨습니다. 레벨 파일 1개의 정보를 채웠습니다.');
    expect(app.library.isMaintaining, isFalse);
  });

  testWidgets('예시는 TUF에서 받은 1번 레벨의 지금 정보로 바뀐다', (tester) async {
    final app = AppController(
      api: TufApiClient(
        client: MockClient(
          (request) async => request.url.path == '/v2/database/levels/1'
              ? http.Response.bytes(
                  utf8.encode(
                    jsonEncode({
                      'level': {'id': 1, 'song': 'multi_arm', 'artist': 'Frums', 'team': 'Live Team'},
                    }),
                  ),
                  200,
                )
              : http.Response('{}', 404),
        ),
      ),
    );
    addTearDown(app.dispose);
    app.library.settings = AppSettings(libraryPath: dir.path, levelFolderTemplate: '{team} [{id}]');

    await tester.pumpWidget(
      AppScope(
        controller: app,
        child: const MaterialApp(home: SettingsPage()),
      ),
    );
    await tester.pump();
    expect(find.text('예시: Live Team [1]'), findsOneWidget);
  });
}
