import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/coiffeur/dialog/coiffeur_type_dialog.dart';

import 'helper/testapp.dart';

void main() {
  const customFactor = true;
  const fixedFactor = false;

  testWidgets('return type fixed factor', (WidgetTester tester) async {
    CoiffeurType? dialogInput;

    await tester.pumpWidget(
        JasstafelTestApp(child: Builder(builder: (BuildContext context) {
      return Center(
        child: InkWell(
          child: const Text('Foo'),
          onTap: () async {
            var controller = TextEditingController(text: "Rosen");
            dialogInput = await coiffeurTypeDialogBuilder(
                context, "title", controller, 3, fixedFactor);
          },
        ),
      );
    })));

    await tester.tap(find.text('Foo'));
    await tester.pump();
    await tester.tap(find.text('Herz'));
    await tester.tap(find.text('Ok'));
    await tester.pump();

    expect(dialogInput!.factor, 3);
    expect(dialogInput!.type, "Herz");
  });
  testWidgets('return type custom factor', (WidgetTester tester) async {
    CoiffeurType? dialogInput;

    await tester.pumpWidget(
        JasstafelTestApp(child: Builder(builder: (BuildContext context) {
      return Center(
        child: InkWell(
          child: const Text('Foo'),
          onTap: () async {
            var controller = TextEditingController(text: "Rosen");
            dialogInput = await coiffeurTypeDialogBuilder(
                context, "title", controller, 3, customFactor);
          },
        ),
      );
    })));

    await tester.tap(find.text('Foo'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), "Special");
    await tester.tap(find.byKey(const Key("dropdownFactor")));
    await tester.pumpAndSettle();
    await tester.tap(find.text('6').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ok'));
    await tester.pump();

    expect(dialogInput!.factor, 6);
    expect(dialogInput!.type, "Special");
  });

  testWidgets('return type empty', (WidgetTester tester) async {
    CoiffeurType? dialogInput;

    await tester.pumpWidget(
        JasstafelTestApp(child: Builder(builder: (BuildContext context) {
      return Center(
        child: InkWell(
          child: const Text('Foo'),
          onTap: () async {
            var controller = TextEditingController(text: "Rosen");
            dialogInput = await coiffeurTypeDialogBuilder(
                context, "title", controller, 3, customFactor);
          },
        ),
      );
    })));

    await tester.tap(find.text('Foo'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), "");
    await tester.tap(find.text('Ok'));
    await tester.pump();

    expect(dialogInput!.type, "");
  });

  testWidgets('return type tap outside', (WidgetTester tester) async {
    CoiffeurType? dialogInput;

    await tester.pumpWidget(
        JasstafelTestApp(child: Builder(builder: (BuildContext context) {
      return Center(
        child: InkWell(
          child: const Text('Foo'),
          onTap: () async {
            var controller = TextEditingController(text: "Rosen");
            dialogInput = await coiffeurTypeDialogBuilder(
                context, "title", controller, 3, customFactor);
          },
        ),
      );
    })));

    await tester.tap(find.text('Foo'));
    await tester.pump();
    await tester.startGesture(const Offset(1, 1));
    await tester.pump();

    expect(dialogInput, null);
  });
}
