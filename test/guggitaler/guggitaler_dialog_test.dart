import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/guggitaler/data/guggitaler_score.dart';
import 'package:jasstafel/guggitaler/dialog/guggitaler_dialog.dart';
import 'package:numberpicker/numberpicker.dart';

import '../helper/testapp.dart';

// cspell: ignore: abbrechen wähle zuerst einen

NumberPicker getNumberPicker(Key key) {
  return find.byKey(key).evaluate().single.widget as NumberPicker;
}

extension DialogHelper on WidgetTester {
  scrollNumberPicker(Key key, int scrollTo) async {
    final picker = getNumberPicker(key);
    final center = getCenter(find.byKey(key));
    final offsetY = (picker.value - scrollTo) * picker.itemHeight;
    final TestGesture testGesture = await startGesture(center);
    await testGesture.moveBy(Offset(0.0, offsetY));
    await pump();

    expect(getNumberPicker(key).value, scrollTo);
  }

  Future<InputWrap> openDialog(
      {required List<String> playerNames, GuggitalerRow? row}) async {
    var dialogInput = InputWrap();
    await pumpWidget(
        JasstafelTestApp(child: Builder(builder: (BuildContext context) {
      return Scaffold(
          body: Center(
        child: InkWell(
          child: const Text('Foo'),
          onTap: () async {
            dialogInput.value = await guggitalerDialogBuilder(context,
                playerNames: playerNames, row: row);
          },
        ),
      ));
    })));

    await tap(find.text('Foo'));
    await pump();
    return dialogInput;
  }
}

void main() {
  var playerNames = List.generate(Players.max, (i) => "P${i + 1}");

  testWidgets('Player 2 - 3 Tricks', (WidgetTester tester) async {
    var dialogInput =
        await tester.openDialog(playerNames: playerNames.sublist(0, 4));

    await tester.tap(find.text('P2'));
    await tester.scrollNumberPicker(const Key('picker_0'), 3);
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(dialogInput.value!.player, "P2");
    expect(dialogInput.value!.points, [3, null, null, null, null]);
  });

  testWidgets('Player 3 - 2 queen', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(
      playerNames: playerNames.sublist(0, 4),
    );

    await tester.scrollNumberPicker(const Key('picker_2'), 2);
    await tester.tap(find.text('P3'));
    await tester.pump();
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(dialogInput.value!.player, "P3");
    expect(dialogInput.value!.points, [null, null, 2, null, null]);
  });

  testWidgets('Player 1 - all schellen', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(
      playerNames: playerNames,
    );

    expect(find.text('P1'), findsOneWidget);
    expect(find.text('P8'), findsOneWidget);
    expect(find.text('+/-'), findsOneWidget);

    await tester.tap(find.text('+/-'));
    await tester.tap(find.text('P1'));
    await tester.scrollNumberPicker(const Key('picker_1'), 9);
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(dialogInput.value!.player, "P1");
    expect(dialogInput.value!.points, [null, -9, null, null, null]);
  });

  testWidgets('Player 4 - tick, 2 schellen, 1 queen',
      (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(
      playerNames: playerNames.sublist(0, 4),
    );

    await tester.tap(find.text('P4'));
    await tester.scrollNumberPicker(const Key('picker_0'), 1);
    await tester.scrollNumberPicker(const Key('picker_1'), 2);
    await tester.scrollNumberPicker(const Key('picker_2'), 1);
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(dialogInput.value!.player, "P4");
    expect(dialogInput.value!.points, [1, 2, 1, null, null]);
  });

  testWidgets('cancel', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(
      playerNames: playerNames.sublist(0, 4),
    );

    await tester.tap(find.text('P3'));
    await tester.scrollNumberPicker(const Key('picker_0'), 5);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();

    expect(dialogInput.value, null);
  });

  testWidgets('no player selected', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(
      playerNames: playerNames.sublist(0, 4),
    );

    await tester.scrollNumberPicker(const Key('picker_3'), 1);
    await tester.tap(find.text('Ok'));
    await tester.pump();

    expect(find.text('Wähle zuerst einen Spieler'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('picker_3')), findsOneWidget);
    expect(dialogInput.value, null);
  });

  testWidgets('edit', (WidgetTester tester) async {
    var inputRow = GuggitalerRow();
    inputRow.pts[1][0] = 1; // P2, 1 tricks
    inputRow.pts[2][0] = 3; // P3, 3 tricks
    inputRow.pts[3][0] = 2; // P4, 2 tricks

    var dialogInput = await tester.openDialog(
        playerNames: playerNames.sublist(0, 4), row: inputRow);

    getNumberPicker(const Key('picker_0')).value == 1;
    await tester.tap(find.text('P3'));
    getNumberPicker(const Key('picker_0')).value == 3;
    await tester.tap(find.text('P1'));
    getNumberPicker(const Key('picker_0')).value == 0;
    await tester.tap(find.text('P4'));
    getNumberPicker(const Key('picker_0')).value == 2;

    await tester.scrollNumberPicker(const Key('picker_0'), 4);
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(dialogInput.value!.player, "P4");
    expect(dialogInput.value!.points, [4, null, null, null, null]);
  });
}
