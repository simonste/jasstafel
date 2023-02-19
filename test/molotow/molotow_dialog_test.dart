import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/molotow/dialog/molotow_dialog.dart';

import '../helper/testapp.dart';

// cspell: ignore: abbrechen

extension DialogHelper on WidgetTester {
  Future<InputWrap> openDialog(
      {required List<String> playerNames, hand = false}) async {
    var dialogInput = InputWrap();
    await pumpWidget(
        JasstafelTestApp(child: Builder(builder: (BuildContext context) {
      return Center(
        child: InkWell(
          child: const Text('Foo'),
          onTap: () async {
            dialogInput.value = await molotowWeisDialogBuilder(context,
                playerNames: playerNames, hand: hand);
          },
        ),
      );
    })));

    await tap(find.text('Foo'));
    await pump();
    return dialogInput;
  }
}

void main() {
  const playerNames = ["P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8"];

  testWidgets('hand weis', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(
      playerNames: playerNames.sublist(0, 4),
      hand: true,
    );

    expect(find.text('2x'), findsNothing);
    await tester.tap(find.text('P4'));
    await tester.pump();
    await tester.tap(find.text('20'));
    await tester.pump();
    await tester.pump();

    expect(dialogInput.value!.player, "P4");
    expect(dialogInput.value!.points, 20);
  });

  testWidgets('hand weis player 6', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(
      playerNames: playerNames.sublist(4),
      hand: true,
    );

    expect(find.text('P1'), findsNothing);
    expect(find.text('P2'), findsNothing);

    await tester.tap(find.text('P5'));
    await tester.pump();
    await tester.tap(find.text('P6'));
    await tester.pump();
    await tester.tap(find.text('150'));
    await tester.pump();

    expect(dialogInput.value!.player, "P6");
    expect(dialogInput.value!.points, 150);
  });

  testWidgets('check cancel', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(
      playerNames: playerNames,
      hand: false,
    );

    expect(find.text('P1'), findsOneWidget);
    expect(find.text('P8'), findsOneWidget);

    await tester.tap(find.text('20'));
    await tester.pump();
    await tester.tap(find.text('50'));
    await tester.pump();
    await tester.tap(find.text('Abbrechen'));
    await tester.pump();

    expect(dialogInput.value, null);
  });

  testWidgets('table weis', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(
      playerNames: playerNames.sublist(0, 4),
      hand: false,
    );

    expect(find.text('2x'), findsOneWidget);
    await tester.tap(find.text('P3'));
    await tester.pump();
    await tester.tap(find.text('150'));
    await tester.pump();

    expect(dialogInput.value!.player, "P3");
    expect(dialogInput.value!.points, 150);
  });

  testWidgets('table weis 2x', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(
      playerNames: playerNames.sublist(0, 4),
      hand: false,
    );

    await tester.tap(find.text('P3'));
    await tester.pump();
    await tester.tap(find.text('2x'));
    await tester.pump();
    expect(find.text('50'), findsNothing);
    expect(find.text('2x 50'), findsOneWidget);
    await tester.tap(find.text('2x'));
    await tester.pump();
    expect(find.text('50'), findsOneWidget);
    expect(find.text('2x 50'), findsNothing);
    await tester.tap(find.text('2x'));
    await tester.pump();
    await tester.tap(find.text('2x 20'));
    await tester.pump();

    expect(dialogInput.value!.player, "P3");
    expect(dialogInput.value!.points, 40);
  });
}
