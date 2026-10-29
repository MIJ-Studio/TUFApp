import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tufapp/ui/widgets/motion.dart';

/// Cards follow the Material 3 interaction states: keyboard focus, a focus ring and state layers.
void main() {
  Future<void> pump(WidgetTester tester, {VoidCallback? onTap}) => tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            child: HoverCard(onTap: onTap, child: const Text('card')),
          ),
        ),
      ),
    ),
  );

  double stateLayer(WidgetTester tester) {
    final layer = tester.widget<AnimatedContainer>(
      find.descendant(of: find.byType(HoverCard), matching: find.byType(AnimatedContainer)),
    );
    return ((layer.decoration as BoxDecoration?)?.color?.a ?? 0);
  }

  double focusRing(WidgetTester tester) => tester
      .widget<AnimatedOpacity>(find.descendant(of: find.byType(HoverCard), matching: find.byType(AnimatedOpacity)))
      .opacity;

  testWidgets('Tab으로 카드에 가면 포커스 링이 보이고, Enter와 Space로 연다', (tester) async {
    var opened = 0;
    await pump(tester, onTap: () => opened++);
    expect(focusRing(tester), 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(focusRing(tester), 1);
    expect(stateLayer(tester), closeTo(0.10, 0.01), reason: 'M3 포커스 상태 레이어 10%');

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(opened, 2);
  });

  testWidgets('마우스를 올리면 8%, 누르면 10% 상태 레이어', (tester) async {
    await pump(tester, onTap: () {});
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.text('card')));
    await tester.pumpAndSettle();
    expect(stateLayer(tester), closeTo(0.08, 0.01));

    await mouse.down(tester.getCenter(find.text('card')));
    await tester.pumpAndSettle();
    expect(stateLayer(tester), closeTo(0.10, 0.01));
    await mouse.up();
    await tester.pumpAndSettle();
    expect(stateLayer(tester), closeTo(0.08, 0.01));
    expect(focusRing(tester), 0, reason: '마우스로 누를 때는 포커스 링을 그리지 않는다');
  });

  testWidgets('누를 수 없는 카드는 포커스를 받지 않고 상태 레이어도 없다', (tester) async {
    await pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(focusRing(tester), 0);
    expect(stateLayer(tester), 0);
  });
}
