import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/common/widgets/settings_screen_helpers.dart';

import '../helper/testapp.dart';

void main() {
  testWidgets('a drag settles on the nearest step, not the one below', (
    tester,
  ) async {
    var stored = 6;

    Widget host() => StatefulBuilder(
      builder: (context, setState) => buildSliderTile(
        context,
        title: 'rounds',
        value: stored,
        min: 6,
        max: 13,
        onChanged: (v) => setState(() => stored = v),
        displayValue: (v) => Text('$v'),
      ),
    );

    await tester.pumpWidget(makeTestableExpanded(host()));

    final slider = find.byType(Slider);
    final box = tester.getSize(slider);
    // 7 steps across the track; drag just past four of them, which truncation
    // would report as three
    final perStep = (box.width - 48) / 7;
    await tester.dragFrom(
      tester.getCenter(slider) - Offset((box.width - 48) / 2, 0),
      Offset(perStep * 4.4, 0),
    );
    await tester.pumpAndSettle();

    expect(stored, 10, reason: '6 + 4.4 steps rounds to 10, truncates to 9');
    expect(find.text('10'), findsOneWidget);
  });
}
