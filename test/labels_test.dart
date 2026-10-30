import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tufapp/ui/widgets/labels.dart';
import 'package:tufapp/ui/widgets/pass_badges.dart';

/// Labels share one size and shape wherever they are placed.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: SizedBox(width: 600, child: child)),
    ),
  );

  testWidgets('칩은 줄 안에서도, 넓은 Wrap 안에서도 내용만큼의 크기에 높이 20이다', (tester) async {
    await pump(
      tester,
      Column(
        children: [
          const Row(children: [PassFlagChip(label: 'WF')]),
          const Wrap(children: [PassFlagChip(label: 'v2')]),
          Wrap(
            children: [InfoChip(label: '+11.97', color: Colors.green)],
          ),
        ],
      ),
    );
    for (final text in ['WF', 'v2', '+11.97']) {
      final chip = tester.getSize(find.ancestor(of: find.text(text), matching: find.byType(InfoChip)));
      expect(chip.height, InfoChip.height, reason: text);
      expect(chip.width, lessThan(100), reason: '$text: 줄 전체로 늘어나지 않는다');
    }
  });
}
