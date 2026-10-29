import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tufapp/core/models/difficulty.dart';
import 'package:tufapp/ui/widgets/difficulty_slider.dart';

void main() {
  // Width 600 with 24 padding on each side → x of difficulty i = 24 + 138 * i
  final difficulties = [for (var i = 0; i < 5; i++) Difficulty(id: i, name: 'P$i', color: '#808080')];

  Future<List<(int, int)>> pumpSlider(WidgetTester tester, {int lower = 0, int upper = 4}) async {
    final calls = <(int, int)>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 600,
              child: DifficultySlider(
                difficulties: difficulties,
                lower: lower,
                upper: upper,
                onChanged: (lo, hi) => calls.add((lo, hi)),
              ),
            ),
          ),
        ),
      ),
    );
    return calls;
  }

  testWidgets('끄는 동안에는 알리지 않고, 놓을 때 한 번만 알린다', (tester) async {
    final calls = await pumpSlider(tester);

    final gesture = await tester.startGesture(const Offset(24, 46));
    await gesture.moveTo(const Offset(162, 46));
    await gesture.moveTo(const Offset(300, 46));
    await tester.pump();
    expect(calls, isEmpty);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(calls, [(2, 4)]);
  });

  testWidgets('노브가 서로 넘어가면 놓을 때 순서를 바로잡는다', (tester) async {
    final calls = await pumpSlider(tester, lower: 1, upper: 2);

    final gesture = await tester.startGesture(const Offset(162, 46)); // knob 1
    await gesture.moveTo(const Offset(576, 46)); // to position 4
    await gesture.up();
    await tester.pumpAndSettle();

    expect(calls, [(2, 4)]);
  });

  testWidgets('제자리에서 눌렀다 떼면 알리지 않는다', (tester) async {
    final calls = await pumpSlider(tester);

    await tester.tapAt(const Offset(576, 46));
    await tester.pumpAndSettle();

    expect(calls, isEmpty);
  });

  testWidgets('Tab으로 노브에 가서 키보드로 움직이고, 키를 멈추면 한 번만 알린다', (tester) async {
    final calls = await pumpSlider(tester);
    double ring(int knob) => tester.widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity)).elementAt(knob).opacity;

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect((ring(0), ring(1)), (1, 0), reason: '아래쪽 노브에 포커스 링');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 100));
    expect(calls, isEmpty, reason: '누르는 동안에는 검색하지 않는다');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(calls, [(2, 4)]);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect((ring(0), ring(1)), (0, 1), reason: '위쪽 노브로 넘어간다');
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(calls.last, (2, 2), reason: '위쪽 노브는 아래쪽 노브를 넘지 않는다');

    await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(calls.last, (2, 4), reason: 'Page Up은 다섯 칸, 끝에서 멈춘다');
  });

  testWidgets('화면 낭독기에 슬라이더로 알린다', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpSlider(tester, lower: 1, upper: 3);
    expect(
      tester.getSemantics(find.byType(FocusableActionDetector).first),
      matchesSemantics(
        isSlider: true,
        isFocusable: true,
        hasFocusAction: true,
        hasIncreaseAction: true,
        hasDecreaseAction: true,
        label: '최저 난이도',
        value: 'P1',
        increasedValue: 'P2',
        decreasedValue: 'P0',
      ),
    );
    semantics.dispose();
  });
}
