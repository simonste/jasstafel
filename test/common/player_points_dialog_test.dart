import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/common/dialog/player_points_dialog.dart';
import 'package:jasstafel/common/utils.dart';

import '../helper/testapp.dart';

// cspell: ignore: abbrechen

String inputFieldText(Key key) {
  return (find.byKey(key).evaluate().single.widget as TextField)
      .controller!
      .text;
}

extension DialogHelper on WidgetTester {
  Future<InputWrap> openDialog({
    required List<String> playerNames,
    int? pointsPerRound = 157,
    bool rounded = false,
    List<int?>? previousPts,
  }) async {
    var dialogInput = InputWrap();
    await pumpWidget(
      JasstafelTestApp(
        child: Builder(
          builder: (BuildContext context) {
            return Center(
              child: InkWell(
                child: const Text('Foo'),
                onTap: () async {
                  dialogInput.value = await playerPointsDialogBuilder(
                    context,
                    playerNames: playerNames,
                    pointsPerRound: pointsPerRound,
                    previousPts: previousPts,
                  );
                },
              ),
            );
          },
        ),
      ),
    );

    await tap(find.text('Foo'));
    await pump();
    return dialogInput;
  }
}

void main() {
  var playerNames = List.generate(Players.max, (i) => "P${i + 1}");

  testWidgets('cancel', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(
      playerNames: playerNames.sublist(0, 4),
    );

    await tester.enterText(find.byKey(const Key('pts_1')), '12');
    await tester.pump();
    await tester.tap(find.text('Abbrechen'));
    await tester.pump();

    expect(dialogInput.value, null);
  });

  testWidgets('ok not allowed when not finished', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(
      playerNames: playerNames.sublist(0, 4),
    );

    await tester.enterText(find.byKey(const Key('pts_1')), '12');
    await tester.pump();
    await tester.tap(find.text('Ok'));
    await tester.pump();
    expect(find.text('Ok'), findsOneWidget);
    expect(dialogInput.value, null);
  });

  testWidgets('ok allowed without points per round', (
    WidgetTester tester,
  ) async {
    var dialogInput = await tester.openDialog(
      playerNames: playerNames.sublist(0, 4),
      pointsPerRound: null,
    );

    await tester.enterText(find.byKey(const Key('pts_1')), '12');
    await tester.pump();
    await tester.tap(find.text('Ok'));
    await tester.pump();
    expect(dialogInput.value, [null, 12, null, null]);
  });

  testWidgets('ok not allowed without points per round when empty', (
    WidgetTester tester,
  ) async {
    var dialogInput = await tester.openDialog(
      playerNames: playerNames.sublist(0, 4),
      pointsPerRound: null,
    );

    await tester.tap(find.text('Ok'));
    await tester.pump();
    expect(find.text('Ok'), findsOneWidget);
    expect(dialogInput.value, null);
  });

  testWidgets('ok is allowed on edit', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(
      playerNames: playerNames.sublist(0, 4),
      previousPts: [null, null, 20, 60],
    );

    await tester.tap(find.text('Ok'));
    await tester.pump();
    expect(dialogInput.value, [null, null, 20, 60]);
  });

  testWidgets('add points', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(
      playerNames: playerNames.sublist(0, 4),
    );

    await tester.enterText(find.byKey(const Key('pts_1')), '12');
    await tester.pump();
    await tester.enterText(find.byKey(const Key('pts_3')), '66');
    await tester.pump();
    await tester.enterText(find.byKey(const Key('pts_0')), '55');
    await tester.pump();
    await tester.enterText(find.byKey(const Key('pts_2')), '22');
    await tester.pump();
    await tester.tap(find.text('Ok'));
    await tester.pump();

    expect(dialogInput.value!.length, 4);
    expect(dialogInput.value, [55, 12, 22, 66]);
  });

  testWidgets('add 157', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(
      playerNames: playerNames.sublist(0, 4),
    );

    await tester.enterText(find.byKey(const Key('pts_1')), '157');
    await tester.pump();
    await tester.tap(find.text('Ok'));
    await tester.pump();

    expect(dialogInput.value!.length, 4);
    expect(dialogInput.value, [0, 157, 0, 0]);
  });

  testWidgets('0 remaining', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(
      playerNames: playerNames.sublist(0, 3),
    );

    await tester.enterText(find.byKey(const Key('pts_1')), '88');
    await tester.pump();
    await tester.enterText(find.byKey(const Key('pts_2')), '69');
    await tester.pump();
    await tester.tap(find.text('Ok'));
    await tester.pump();

    expect(dialogInput.value!.length, 3);
    expect(dialogInput.value, [0, 88, 69]);
  });

  testWidgets('press enter', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(
      playerNames: playerNames.sublist(0, 3),
    );

    await tester.enterText(find.byKey(const Key('pts_0')), '50');
    await tester.pump();
    await tester.enterText(find.byKey(const Key('pts_2')), '18');
    await tester.pump();
    expect(inputFieldText(const Key('pts_1')), '');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(inputFieldText(const Key('pts_1')), '89');

    await tester.tap(find.text('Ok'));
    await tester.pump();

    expect(dialogInput.value, [50, 89, 18]);
  });

  testWidgets('edit', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(
      playerNames: playerNames.sublist(0, 4),
      previousPts: [null, null, 20, 60],
    );

    await tester.enterText(find.byKey(const Key('pts_0')), '20');
    await tester.pump();
    expect(find.byKey(const Key('remainingPoints')), findsNothing);
    await tester.tap(find.text('Ok'));
    await tester.pump();
    expect(dialogInput.value, [20, null, 20, 60]);
  });

  testWidgets('edit round', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(
      playerNames: playerNames.sublist(0, 4),
      previousPts: [50, 27, 20, 60],
    );

    await tester.enterText(find.byKey(const Key('pts_0')), '27');
    await tester.pump();
    await tester.enterText(find.byKey(const Key('pts_1')), '50');
    await tester.pump();
    expect(find.byKey(const Key('remainingPoints')), findsOneWidget);
    await tester.tap(find.text('Ok'));
    await tester.pump();
    expect(dialogInput.value, [27, 50, 20, 60]);
  });

  testWidgets('no fix points per round', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(
      playerNames: playerNames.sublist(0, 4),
      pointsPerRound: null,
    );

    await tester.enterText(find.byKey(const Key('pts_0')), '27');
    await tester.pump();
    await tester.enterText(find.byKey(const Key('pts_1')), '50');
    await tester.pump();
    await tester.enterText(find.byKey(const Key('pts_2')), '30');
    await tester.pump();
    expect(find.byKey(const Key('remainingPoints')), findsNothing);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(inputFieldText(const Key('pts_3')), '');
    await tester.enterText(find.byKey(const Key('pts_3')), '0');
    await tester.pump();

    await tester.tap(find.text('Ok'));
    await tester.pump();
    expect(dialogInput.value, [27, 50, 30, 0]);
  });
}
