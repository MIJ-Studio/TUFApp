import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tufapp/app/controllers.dart';
import 'package:tufapp/core/models/pack.dart';
import 'package:tufapp/ui/pages/packs_page.dart';
import 'package:tufapp/ui/widgets/motion.dart';

/// The scrollbar of a pack's contents must stay steady: the scroll length may not jump while scrolling.
void main() {
  Map<String, dynamic> level(int id) => {
    'id': id,
    'song': 'Song $id',
    'artist': 'Artist',
    'diffId': 16,
    'dlLink': 'https://cdn.tuforums.com/zips/$id',
  };

  // 30 folders of 40 levels each.
  final detail = LevelPackDetail.fromJson({
    'id': 'big',
    'name': 'Big pack',
    'levelCount': 1200,
    'items': [
      for (var f = 0; f < 30; f++)
        {
          'id': 1000 + f,
          'type': 'folder',
          'name': 'Folder $f',
          'sortOrder': f,
          'children': [
            for (var i = 0; i < 40; i++)
              {'id': f * 100 + i, 'type': 'level', 'sortOrder': i, 'referencedLevel': level(f * 100 + i + 1)},
          ],
        },
    ],
  });

  Future<(AppController, ScrollPosition)> pump(WidgetTester tester) async {
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
    return (app, tester.state<ScrollableState>(find.byType(Scrollable).last).position);
  }

  /// Scrolls down step by step and returns how far the scroll length moved.
  Future<double> lengthSpread(WidgetTester tester, ScrollPosition position) async {
    final extents = <double>[];
    for (var step = 0; step < 40; step++) {
      position.jumpTo((position.pixels + 120).clamp(0, position.maxScrollExtent));
      await tester.pump();
      extents.add(position.maxScrollExtent);
    }
    return extents.reduce(max) - extents.reduce(min);
  }

  testWidgets('접힌 폴더 안의 레벨은 목록에 남지 않아 스크롤 길이가 흔들리지 않는다', (tester) async {
    final (_, position) = await pump(tester);
    expect(await lengthSpread(tester, position), lessThan(1), reason: '스크롤 길이가 바뀌면 스크롤바 크기와 위치가 튄다');
    expect(find.text('Song 1'), findsNothing);
  });

  testWidgets('폴더를 펼치면 펼쳐지는 애니메이션이 나오고, 접으면 끝난 뒤 행이 빠진다', (tester) async {
    final (app, _) = await pump(tester);

    app.packs.toggleFolder(1000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final opening = tester.getSize(find.ancestor(of: find.text('Song 1'), matching: find.byType(Reveal)).last).height;
    await tester.pumpAndSettle();
    final open = tester.getSize(find.ancestor(of: find.text('Song 1'), matching: find.byType(Reveal)).last).height;
    expect(opening, lessThan(open), reason: '한 번에 나타나지 않고 펼쳐진다');

    app.packs.toggleFolder(1000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Song 1'), findsOneWidget, reason: '접히는 동안에는 아직 보인다');
    await tester.pumpAndSettle();
    expect(find.text('Song 1'), findsNothing);
    expect(find.byType(Reveal).evaluate().length, lessThan(40), reason: '접힌 뒤에는 행이 빠진다');
  });
}

double max(double a, double b) => a > b ? a : b;
double min(double a, double b) => a < b ? a : b;
