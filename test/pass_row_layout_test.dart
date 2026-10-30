import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tufapp/app/controllers.dart';
import 'package:tufapp/core/models/pass.dart';
import 'package:tufapp/core/tuf_api_client.dart';
import 'package:tufapp/ui/widgets/pass_row.dart';

/// Elements of a pass row must not move with the content (video or not, date length, contribution chip).
void main() {
  LevelPass pass({required int id, String? video, required String date, double score = 1234.5}) => LevelPass.fromJson({
    'id': id,
    'playerId': 1,
    'player': {'name': 'p$id'},
    'scoreV2': score,
    'accuracy': 0.99,
    'speed': 1,
    'videoLink': ?video,
    'vidUploadTime': date,
  });

  Future<void> pump(WidgetTester tester, List<Widget> rows) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = AppController(api: TufApiClient(client: MockClient((_) async => http.Response('{}', 404))));
    addTearDown(app.dispose);
    await tester.pumpWidget(
      AppScope(
        controller: app,
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Column(
              children: [for (final row in rows) Padding(padding: const EdgeInsets.only(bottom: 8), child: row)],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  Widget row(LevelPass pass, {double? impact}) => PassRow(
    pass: pass,
    leading: const SizedBox.shrink(),
    title: Text('song ${pass.id}'),
    onTap: () {},
    impact: impact,
  );

  testWidgets('날짜와 영상 단추는 항상 오른쪽 끝, 같은 높이', (tester) async {
    await pump(tester, [
      row(pass(id: 1, video: 'https://youtu.be/abc', date: '2026-07-22T12:00:00Z')),
      row(pass(id: 2, date: '2026-09-06T12:00:00Z')),
      row(pass(id: 3, video: 'https://youtu.be/def', date: '2026-12-26T12:00:00Z')),
    ]);
    expect(tester.takeException(), isNull);

    final cards = find.byType(PassRow);
    final dates = [
      for (final date in ['2026년 7월 22일', '2026년 9월 6일', '2026년 12월 26일']) find.text(date),
    ];

    for (var i = 0; i < 3; i++) {
      final card = tester.getRect(cards.at(i));
      final date = tester.getRect(dates[i]);
      // Sits right inside the card's right padding (12); the right edge is the same even for short dates.
      expect(card.right - date.right, closeTo(12, 0.5), reason: '날짜 ${i + 1}');
      // The date is at the same height even without a video.
      expect(date.top - card.top, closeTo(tester.getRect(dates[0]).top - tester.getRect(cards.at(0)).top, 0.5));
    }

    final icons = find.byIcon(Icons.smart_display_outlined);
    expect(icons, findsNWidgets(2));
    // The video button is in the same place on every row.
    expect(tester.getRect(icons.at(0)).center.dx, tester.getRect(icons.at(1)).center.dx);
  });

  testWidgets('몫 칩은 점수 칸만 움직인다', (tester) async {
    await pump(tester, [
      row(pass(id: 1, date: '2026-07-22T12:00:00Z'), impact: 1000),
      row(pass(id: 2, date: '2026-07-22T12:00:00Z', score: 67016)),
    ]);
    expect(tester.takeException(), isNull);
    final cards = find.byType(PassRow);
    double topIn(int row, String text) =>
        tester.getRect(find.text(text).at(row)).top - tester.getRect(cards.at(row)).top;

    for (final label in ['점수', '정확도', '배속']) {
      final found = find.text(label);
      expect(tester.getRect(found.at(0)).left, tester.getRect(found.at(1)).left, reason: label);
    }
    // Accuracy and speed are at the same height on rows with and without a chip; only the score column moves up.
    expect(topIn(0, '정확도'), closeTo(topIn(1, '정확도'), 0.5));
    expect(topIn(0, '배속'), closeTo(topIn(1, '배속'), 0.5));
    expect(topIn(0, '점수'), lessThan(topIn(1, '점수')));
  });

  testWidgets('영상 단추는 세로 가운데, 날짜는 오른쪽 아래 모서리, 표시는 아래 줄 오른쪽 끝', (tester) async {
    await pump(tester, [row(pass(id: 1, video: 'https://youtu.be/abc', date: '2026-07-22T12:00:00Z'))]);
    final card = tester.getRect(find.byType(PassRow));
    final icon = tester.getRect(find.byIcon(Icons.smart_display_outlined));
    final date = tester.getRect(find.text('2026년 7월 22일'));
    expect(icon.center.dy, closeTo(card.center.dy, 1), reason: '레벨 카드처럼 세로 가운데');
    expect(card.bottom - date.bottom, closeTo(12, 0.5), reason: '아래 모서리 (여백 12 안쪽)');
    expect(card.right - date.right, closeTo(12, 0.5));

    // The flag chip (<3.4.0) sits at the right end of the three-line column,
    // right before the score column (16 gap + 8 chip padding).
    final flag = tester.getRect(find.text('<3.4.0'));
    final score = tester.getRect(find.text('점수'));
    expect(score.left - flag.right, closeTo(16 + 8, 0.5));
  });
}
