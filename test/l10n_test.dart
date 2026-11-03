import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tufapp/app/controllers.dart';
import 'package:tufapp/core/l10n.dart';
import 'package:tufapp/core/models/browse.dart';
import 'package:tufapp/core/models/facet.dart';
import 'package:tufapp/core/tuf_api_client.dart';
import 'package:tufapp/main.dart';

void main() {
  tearDown(() => appLanguage = AppLanguage.ko);

  test('l10n은 지금 언어의 글을 고른다', () {
    expect(l10n.download, '받기');
    appLanguage = AppLanguage.en;
    expect(l10n.download, 'Download');
    expect(ClearSort.recent.label, 'Date', reason: '목록 항목 이름도 언어를 따른다');
  });

  test('언어마다 번역 파일의 글이 모두 있다', () {
    expect([for (final language in AppLanguage.values) language.code], containsAll(['en', 'ko']));
    expect(AppLanguage.ko.nativeName, '한국어');
    expect(AppLanguage.en.nativeName, 'English');
  });

  test('묶음이 없는 태그의 묶음 이름도 언어를 바꾸면 따라 바뀐다', () {
    final catalog = FacetCatalog([const FacetItem(id: 1, name: 'Pseudo')]);
    expect(catalog.groups.single.title, '기타');
    appLanguage = AppLanguage.en;
    expect(catalog.groups.single.title, 'Other');
  });

  test('영어 단수·복수와 천 단위 쉼표', () {
    appLanguage = AppLanguage.en;
    expect(l10n.levelCount(1), '1 level');
    expect(l10n.levelCount(0), '0 levels');
    expect(l10n.passCount(1234), '1,234 passes');
    expect(l10n.updatesAvailable(1), '1 level has an update.');
    appLanguage = AppLanguage.ko;
    expect(l10n.levelCount(1234), '레벨 1,234개');
  });

  test('날짜 형식', () {
    final date = DateTime(2026, 5, 5);
    expect(formatLongDate(date), '2026년 5월 5일');
    expect(formatShortMonth(date), '26년 5월');
    appLanguage = AppLanguage.en;
    expect(formatLongDate(date), 'May 5, 2026');
    expect(formatMonthDay(date), 'May 5');
    expect(formatShortMonth(date), "May '26");
  });

  test('설정 파일의 언어 값', () {
    expect(AppLanguage.fromCode('en'), AppLanguage.en);
    expect(AppLanguage.fromCode('ko'), AppLanguage.ko);
    expect(AppLanguage.fromCode('fr'), isNull);
    expect(AppLanguage.fromCode(3), isNull, reason: '글자가 아닌 값은 무시한다');
  });

  testWidgets('언어를 바꾸면 화면 전체가 바로 바뀌고, 고른 탭은 그대로다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    // No server calls (initialize isn't run).
    final app = AppController(api: TufApiClient(client: MockClient((_) async => http.Response('{}', 404))));
    addTearDown(app.dispose);

    await tester.pumpWidget(TufApp(controller: app));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('레벨 관리'), findsWidgets);
    app.setPage(AppPage.library);
    await tester.pump(const Duration(milliseconds: 300));

    await app.setLanguage(AppLanguage.en);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.text('레벨 관리'), findsNothing);
    expect(find.text('Library'), findsWidgets);
    expect(find.text('Leaderboard'), findsWidgets);
    expect(app.page, AppPage.library, reason: '보던 페이지는 그대로');

    // Pick from the menu on the settings page.
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownMenu<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('한국어').last);
    await tester.pumpAndSettle();
    expect(appLanguage, AppLanguage.ko);
    expect(app.languageChoice, AppLanguage.ko);
    expect(find.text('설정'), findsOneWidget, reason: '설정 화면도 바로 바뀐다');
    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();
    expect(find.text('레벨 관리'), findsWidgets);
  });
}
