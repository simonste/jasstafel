import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/common/data/common_data.dart';
import 'package:jasstafel/common/widgets/who_is_next_widget.dart';

import '../helper/testapp.dart';

void main() {
  void expectTextColor(WidgetTester tester, String player, Color color) {
    var textWidget = tester.firstWidget(find.text(player)) as Text;
    expect((textWidget.style as TextStyle).color, color);
  }

  testWidgets('who is next', (WidgetTester tester) async {
    final widget = makeTestable(WhoIsNextWidget(
        WhoIsNextData(['1', '2', '3', '4'], 0, WhoIsNext(), () {})));
    await tester.pumpWidget(widget);

    expectTextColor(tester, '1', Colors.white);
    expectTextColor(tester, '2', Colors.white);
    expectTextColor(tester, '3', Colors.white);
    expectTextColor(tester, '4', Colors.white);

    await tester.longPress(find.text('2'));
    await tester.pumpAndSettle();

    expectTextColor(tester, '2', Colors.blue);
  });
}
