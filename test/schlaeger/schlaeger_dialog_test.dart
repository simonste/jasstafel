import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/schlaeger/dialog/schlaeger_dialog.dart';
import 'package:jasstafel/schlaeger/screens/schlaeger_settings_screen.dart';

import '../helper/testapp.dart';

// cspell: ignore: abbrechen

String inputFieldText(Key key) {
  return (find.byKey(key).evaluate().single.widget as TextField)
      .controller!
      .text;
}

extension DialogHelper on WidgetTester {
  Future<InputWrap> openDialog(
      {required List<String> playerNames,
      int? pointsPerRound = 157,
      bool rounded = false,
      List<int?>? previousPts}) async {
    var dialogInput = InputWrap();
    await pumpWidget(
        JasstafelTestApp(child: Builder(builder: (BuildContext context) {
      return Center(
        child: InkWell(
          child: const Text('Foo'),
          onTap: () async {
            dialogInput.value = await schlaegerDialogBuilder(
              context,
              playerNames: playerNames,
              pointsPerRound: 3,
              previousPts: previousPts,
            );
          },
        ),
      );
    })));

    await tap(find.text('Foo'));
    await pump();
    return dialogInput;
  }

  Future<void> addSchlaegerPoints(String key, int points) async {
    await tap(find.descendant(
        of: find.byKey(Key(key)), matching: find.text("$points")));
  }
}

void main() {
  var playerNames = List.generate(SchlaegerPlayers.max, (i) => "P${i + 1}");

  testWidgets('cancel', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(
      playerNames: playerNames,
    );

    await tester.addSchlaegerPoints("pts_1", 1);
    await tester.pump();
    await tester.tap(find.text('Abbrechen'));
    await tester.pump();

    expect(dialogInput.value, null);
  });

  testWidgets('ok is allowed on edit', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(
      playerNames: playerNames,
      previousPts: [null, null, 2, 1],
    );

    await tester.tap(find.text('Ok'));
    await tester.pump();
    expect(dialogInput.value, [null, null, 2, 1]);
  });

  testWidgets('add points', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(playerNames: playerNames);

    await tester.addSchlaegerPoints('pts_1', 1);
    await tester.pump();
    await tester.addSchlaegerPoints('pts_3', -1);
    await tester.pump();
    await tester.addSchlaegerPoints('pts_0', 2);
    await tester.pump();
    await tester.tap(find.text('Ok'));
    await tester.pump();

    expect(dialogInput.value!.length, 4);
    expect(dialogInput.value, [2, 1, null, -1]);
  });

  testWidgets('edit', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(
      playerNames: playerNames,
      previousPts: [null, null, 2, 1],
    );

    await tester.addSchlaegerPoints('pts_0', 1);
    await tester.pump();
    await tester.addSchlaegerPoints('pts_2', 1);
    await tester.pump();
    await tester.tap(find.text('Ok'));
    await tester.pump();
    expect(dialogInput.value, [1, null, 1, 1]);
  });

  testWidgets('edit round', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(
      playerNames: playerNames.sublist(0, 4),
      previousPts: [1, null, 2, -1],
    );

    await tester.addSchlaegerPoints('pts_0', 0);
    await tester.pump();
    await tester.addSchlaegerPoints('pts_1', 1);
    await tester.pump();
    await tester.tap(find.text('Ok'));
    await tester.pump();
    expect(dialogInput.value, [0, 1, 2, -1]);
  });
}
