import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/common/data/common_data.dart';
import 'package:jasstafel/common/widgets/who_is_next_widget.dart';

import '../helper/testapp.dart';

extension WhoIsNextTestHelper on WidgetTester {
  void expectOrder(List order) {
    var textWidgets = find.byType(Text);
    for (var i = 0; i < order.length; i++) {
      var text = textWidgets.at(i).evaluate().single.widget as Text;
      expect(text.data, order[i]);
    }
  }
}

void main() {
  void expectTextColor(WidgetTester tester, String player, Color color) {
    var textWidget = tester.firstWidget(find.text(player)) as Text;
    expect((textWidget.style as TextStyle).color, color);
  }

  testWidgets('who is next', (WidgetTester tester) async {
    tester.portrait();

    final widget = makeTestable(WhoIsNextWidget(
        WhoIsNextData(['1', '2', '3', '4'], 0, WhoIsNext(), () {})));
    await tester.pumpWidget(widget);

    expectTextColor(tester, '1', Colors.white);
    expectTextColor(tester, '2', Colors.white);
    expectTextColor(tester, '3', Colors.white);
    expectTextColor(tester, '4', Colors.white);

    tester.expectOrder(['1', '4', '2', '3']);

    await tester.longPress(find.text('2'));
    await tester.pumpAndSettle();
    expectTextColor(tester, '2', Colors.blue);

    await tester.drag(find.text('1'), const Offset(50, 0));
    await tester.pumpAndSettle();
    tester.expectOrder(['4', '1', '2', '3']);

    await tester.drag(find.text('3'), const Offset(-50, -50));
    await tester.pumpAndSettle();
    tester.expectOrder(['3', '1', '2', '4']);
  });

  testWidgets('offset', (WidgetTester tester) async {
    tester.portrait();

    var whoIsNext = WhoIsNext();
    whoIsNext.whoBeginsOffset = 1;

    final widget = makeTestable(WhoIsNextWidget(
        WhoIsNextData(['1', '2', '3', '4'], 0, whoIsNext, () {})));
    await tester.pumpWidget(widget);

    expectTextColor(tester, '1', Colors.white);
    expectTextColor(tester, '2', Colors.blue);
    expectTextColor(tester, '3', Colors.white);
    expectTextColor(tester, '4', Colors.white);
  });

  testWidgets('offset round', (WidgetTester tester) async {
    tester.portrait();

    var whoIsNext = WhoIsNext();
    whoIsNext.whoBeginsOffset = 1;

    final widget = makeTestable(WhoIsNextWidget(
        WhoIsNextData(['1', '2', '3', '4'], 2, whoIsNext, () {})));
    await tester.pumpWidget(widget);

    expectTextColor(tester, '1', Colors.white);
    expectTextColor(tester, '2', Colors.white);
    expectTextColor(tester, '3', Colors.white);
    expectTextColor(tester, '4', Colors.blue);

    tester.expectOrder(['1', '4', '2', '3']);
  });

  testWidgets('offset swap', (WidgetTester tester) async {
    tester.portrait();

    var whoIsNext = WhoIsNext();
    whoIsNext.whoBeginsOffset = 1;
    whoIsNext.swapPlayers = "[0, 3, 2, 1]"; // player 2&4 swapped

    final widget = makeTestable(WhoIsNextWidget(
        WhoIsNextData(['1', '2', '3', '4'], 0, whoIsNext, () {})));
    await tester.pumpWidget(widget);

    // offset highlights p2 but p2/p4 are swapped
    expectTextColor(tester, '1', Colors.white);
    expectTextColor(tester, '2', Colors.white);
    expectTextColor(tester, '3', Colors.white);
    expectTextColor(tester, '4', Colors.blue);

    tester.expectOrder(['1', '2', '4', '3']);
  });

  testWidgets('offset swap 6players', (WidgetTester tester) async {
    tester.portrait();

    var whoIsNext = WhoIsNext();
    whoIsNext.whoBeginsOffset = 5;
    whoIsNext.swapPlayers = "[0, 1, 5, 3, 4, 2]"; // player 3&6 swapped

    final widget = makeTestable(WhoIsNextWidget(
        WhoIsNextData(['1', '2', '3', '4', '5', '6'], 0, whoIsNext, () {})));
    await tester.pumpWidget(widget);

    // offset highlights p6 but p3/p6 are swapped
    expectTextColor(tester, '1', Colors.white);
    expectTextColor(tester, '2', Colors.white);
    expectTextColor(tester, '3', Colors.blue);
    expectTextColor(tester, '4', Colors.white);
    expectTextColor(tester, '5', Colors.white);
    expectTextColor(tester, '6', Colors.white);
  });

  testWidgets('landscape offset 6players', (WidgetTester tester) async {
    tester.landscape();

    var whoIsNext = WhoIsNext();
    whoIsNext.whoBeginsOffset = 2;

    final widget = makeTestable(WhoIsNextWidget(
        WhoIsNextData(['1', '2', '3', '4', '5', '6'], 0, whoIsNext, () {})));
    await tester.pumpWidget(widget);

    // offset highlights p3
    expectTextColor(tester, '1', Colors.white);
    expectTextColor(tester, '2', Colors.white);
    expectTextColor(tester, '3', Colors.blue);
    expectTextColor(tester, '4', Colors.white);
    expectTextColor(tester, '5', Colors.white);
    expectTextColor(tester, '6', Colors.white);

    tester.expectOrder(['1', '6', '5', '2', '3', '4']);
  });

  testWidgets('landscape offset swap 6players', (WidgetTester tester) async {
    tester.landscape();

    var whoIsNext = WhoIsNext();
    whoIsNext.whoBeginsOffset = 1;
    whoIsNext.swapPlayers = "[0, 4, 2, 3, 1, 5]"; // player 2&5 swapped

    final widget = makeTestable(WhoIsNextWidget(
        WhoIsNextData(['1', '2', '3', '4', '5', '6'], 0, whoIsNext, () {})));
    await tester.pumpWidget(widget);

    // offset highlights p2 but p2/p5 are swapped
    expectTextColor(tester, '1', Colors.white);
    expectTextColor(tester, '2', Colors.white);
    expectTextColor(tester, '3', Colors.white);
    expectTextColor(tester, '4', Colors.white);
    expectTextColor(tester, '5', Colors.blue);
    expectTextColor(tester, '6', Colors.white);

    tester.expectOrder(['1', '6', '2', '5', '3', '4']);
  });
}
