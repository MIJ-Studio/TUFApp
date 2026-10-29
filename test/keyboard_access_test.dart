import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tufapp/app/controllers.dart';
import 'package:tufapp/core/models/profile.dart';
import 'package:tufapp/core/tuf_api_client.dart';
import 'package:tufapp/ui/pages/library_page.dart';
import 'package:tufapp/ui/pages/profile/bio_canvas.dart';
import 'package:tufapp/ui/widgets/hover_tip.dart';

/// Everything that can be clicked can also be reached and used from the keyboard.
void main() {
  testWidgets('레벨 관리: 화살표·Home/End로 고르고 Shift로 범위를 넓힌다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final root = (await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('tufapp_keys_');
      for (final name in ['a', 'b', 'c', 'd']) {
        await Directory('${dir.path}/$name').create();
      }
      return dir;
    }))!;
    addTearDown(() => root.delete(recursive: true));
    final app = AppController();
    addTearDown(app.dispose);
    await tester.runAsync(() => app.library.open(root.path));

    await tester.pumpWidget(
      AppScope(
        controller: app,
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(body: LibraryPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final library = app.library;

    // Clicking empty space gives the page keyboard focus.
    await tester.tapAt(const Offset(20, 880));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(library.selection, {'a'}, reason: '아무것도 고르지 않았으면 첫 항목부터');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(library.selection, {'b'});

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(library.selection, {'b', 'c', 'd'}, reason: 'Shift는 기준점부터 범위');

    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    expect(library.selection, {'a'});
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    expect(library.selection, {'d'});
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    expect(library.selection, {'c'});

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(library.currentPath, 'c', reason: 'Enter로 연다');
  });

  testWidgets('툴팁은 키보드 포커스로도 뜬다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              HoverTip(
                message: '설명',
                child: IconButton(onPressed: () {}, icon: const Icon(Icons.info)),
              ),
              TextButton(onPressed: () {}, child: const Text('다음')),
            ],
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(HoverTip.delay);
    await tester.pumpAndSettle();
    expect(find.text('설명'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.text('설명'), findsNothing, reason: '포커스가 떠나면 닫힌다');
  });

  testWidgets('자기소개 소셜 버튼도 Tab으로 가서 Enter로 연다', (tester) async {
    final app = AppController(api: TufApiClient(client: MockClient((_) async => http.Response('{}', 404))));
    addTearDown(app.dispose);
    await tester.pumpWidget(
      AppScope(
        controller: app,
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: BioCanvas(
              blocks: const [
                BioSocialBlock(
                  BioLayout(x: 0, y: 0, w: 360, h: 64),
                  links: [(platform: 'youtube', url: 'https://www.youtube.com/@example', label: null)],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('TUF를 떠나시겠습니까?'), findsOneWidget);
  });
}
