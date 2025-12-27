import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/coiffeur/dialog/coiffeur_type_dialog.dart';

import '../helper/testapp.dart';

extension DialogHelper on WidgetTester {
  Future<InputWrap> openDialog({required bool customFactor}) async {
    var dialogInput = InputWrap();
    await pumpWidget(
      JasstafelTestApp(
        child: Builder(
          builder: (BuildContext context) {
            return Center(
              child: InkWell(
                child: const Text('Foo'),
                onTap: () async {
                  var controller = TextEditingController(text: "Rosen");
                  dialogInput.value = await coiffeurTypeDialogBuilder(
                    context,
                    title: "title",
                    controller: controller,
                    factor: 3,
                    customFactor: customFactor,
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
  testWidgets('return type fixed factor', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(customFactor: false);

    await tester.tap(find.text('Herz'));
    await tester.tap(find.text('Ok'));
    await tester.pump();

    expect(dialogInput.value!.factor, 3);
    expect(dialogInput.value!.type, "Herz");
  });
  testWidgets('return type custom factor', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(customFactor: true);

    await tester.enterText(find.byType(TextField), "Special");
    await tester.tap(find.byKey(const Key("dropdownFactor")));
    await tester.pumpAndSettle();
    await tester.tap(find.text('6').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ok'));
    await tester.pump();

    expect(dialogInput.value!.factor, 6);
    expect(dialogInput.value!.type, "Special");
  });

  testWidgets('return type empty', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(customFactor: true);

    await tester.enterText(find.byType(TextField), "");
    await tester.tap(find.text('Ok'));
    await tester.pump();

    expect(dialogInput.value!.type, "");
  });

  testWidgets('return type tap outside', (WidgetTester tester) async {
    var dialogInput = await tester.openDialog(customFactor: true);

    await tester.startGesture(const Offset(1, 1));
    await tester.pump();

    expect(dialogInput.value, null);
  });
}
