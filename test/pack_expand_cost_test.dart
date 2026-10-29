import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tufapp/app/controllers.dart';
import 'package:tufapp/core/models/pack.dart';
import 'package:tufapp/ui/pages/packs_page.dart';
import 'package:tufapp/ui/widgets/level_card.dart';

/// Opening or closing folders with many levels must not build every level card in one frame.
void main() {
  Map<String, dynamic> level(int id) => {
    'id': id,
    'song': 'Song $id',
    'artist': 'Artist',
    'diffId': 16,
    'dlLink': 'https://cdn.tuforums.com/zips/$id',
  };

  Map<String, dynamic> entry(int id) => {'id': id, 'type': 'level', 'sortOrder': id, 'referencedLevel': level(id + 1)};

  // One folder of 200 levels.
  final oneBigFolder = LevelPackDetail.fromJson({
    'id': 'big',
    'name': 'Big pack',
    'levelCount': 200,
    'items': [
      {
        'id': 1000,
        'type': 'folder',
        'name': 'Folder',
        'sortOrder': 0,
        'children': [for (var i = 0; i < 200; i++) entry(i)],
      },
    ],
  });

  // Like real packs: a folder of 20 subfolders with 10 levels each, all opened at once by "Expand all".
  final manyFolders = LevelPackDetail.fromJson({
    'id': 'tree',
    'name': 'Tree pack',
    'levelCount': 200,
    'items': [
      {
        'id': 1000,
        'type': 'folder',
        'name': 'Planetary',
        'sortOrder': 0,
        'children': [
          for (var f = 0; f < 20; f++)
            {
              'id': 2000 + f,
              'type': 'folder',
              'name': 'P$f',
              'sortOrder': f,
              'children': [for (var i = 0; i < 10; i++) entry(f * 10 + i)],
            },
        ],
      },
    ],
  });

  Future<AppController> pump(WidgetTester tester, LevelPackDetail detail) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = AppController();
    addTearDown(app.dispose);
    app.packs
      ..openedPack = detail.pack
      ..detail = detail;
    await tester.pumpWidget(
      AppScope(
        controller: app,
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(body: PacksPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return app;
  }

  /// Most level cards alive in any frame while an opening or closing plays out.
  Future<int> mostCards(WidgetTester tester) async {
    var most = 0;
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final now = find.byType(LevelCard, skipOffstage: false).evaluate().length;
      if (now > most) most = now;
    }
    await tester.pumpAndSettle();
    return most;
  }

  testWidgets('레벨 200개 폴더를 열고 닫는 동안 화면 근처의 카드만 만든다', (tester) async {
    final app = await pump(tester, oneBigFolder);

    app.packs.toggleFolder(1000);
    expect(await mostCards(tester), lessThan(60));

    app.packs.toggleFolder(1000);
    expect(await mostCards(tester), lessThan(60));
  });

  testWidgets('모두 펼치기로 폴더 수십 개를 한꺼번에 열어도 화면 근처의 카드만 만든다', (tester) async {
    final app = await pump(tester, manyFolders);

    app.packs.setAllExpanded(true);
    expect(await mostCards(tester), lessThan(60));
    expect(find.text('Song 1'), findsOneWidget, reason: '다 열린 뒤에는 보인다');

    app.packs.setAllExpanded(false);
    expect(await mostCards(tester), lessThan(60));
  });
}
