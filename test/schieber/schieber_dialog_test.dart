import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/schieber/data/schieber_score.dart';
import 'package:jasstafel/schieber/dialog/schieber_dialog.dart';

import '../../integration_test/overall_test.dart';
import '../helper/testapp.dart';

extension DialogHelper on WidgetTester {
  Future<InputWrap> openDialog({required int matchPoints}) async {
    var dialogInput = InputWrap();
    await pumpWidget(
        JasstafelTestApp(child: Builder(builder: (BuildContext context) {
      return Center(
        child: InkWell(
          child: const Text('Foo'),
          onTap: () async {
            dialogInput.value = await schieberDialogBuilder(
                context, 0, matchPoints, TeamData());
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
  testWidgets('add round', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(matchPoints: 257);

    await tester.addSchieberPoints(['key_4', 'key_2']);

    expect(dialogInput.value!.points1, 42);
    expect(dialogInput.value!.points2, 115);
  });

  testWidgets('add round 3x', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(matchPoints: 257);

    await tester.addSchieberPoints(['key_4', 'key_2'], factor: '3x');

    expect(dialogInput.value!.points1, 3 * 42);
    expect(dialogInput.value!.points2, 3 * 115);
  });

  testWidgets('add match', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(matchPoints: 257);

    await tester.addSchieberPoints(['key_4', 'key_Match'], factor: '2x');

    expect(dialogInput.value!.points1, 2 * 257);
    expect(dialogInput.value!.points2, 0);
  });

  testWidgets('add weis', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(matchPoints: 257);

    await tester
        .addSchieberPoints(['key_4', 'key_0'], factor: '2x', weis: true);

    expect(dialogInput.value!.points1, 2 * 40);
    expect(dialogInput.value!.points2, 0);
  });

  testWidgets('add negative', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(matchPoints: 257);

    await tester.addSchieberPoints(['key_6', 'key_3', 'key_+/-'], factor: '2x');

    expect(dialogInput.value!.points1, -2 * 63);
    expect(dialogInput.value!.points2, 0);
  });

  testWidgets('add match 514', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(matchPoints: 514);

    await tester.addSchieberPoints(['key_4', 'key_Match'], factor: '2x');

    expect(dialogInput.value!.points1, 2 * 514);
    expect(dialogInput.value!.points2, 0);
  });

  testWidgets('add round 514', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(matchPoints: 514);

    await tester.addSchieberPoints(['key_4', 'key_8']);

    expect(dialogInput.value!.points1, 48);
    expect(dialogInput.value!.points2, 314 - 48);
  });

  testWidgets('tap outside', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(matchPoints: 257);

    await tester.startGesture(const Offset(1, 1));
    await tester.pump();

    expect(dialogInput.value, null);
  });
}
