import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/coiffeur/widgets/coiffeur_type_cell.dart';

import '../helper/testapp.dart';

void main() {
  testWidgets('type cell', (WidgetTester tester) async {
    final widget = makeTestable(Builder(builder: (BuildContext context) {
      return CoiffeurTypeCell(11, "Eicheln", context);
    }));

    await tester.pumpWidget(widget);

    expect(find.text('11'), findsOneWidget);
    expect(find.text('Eicheln'), findsOneWidget);

    await tester.longPress(find.text('Eicheln'));
    await tester.pumpAndSettle();
  });
}
