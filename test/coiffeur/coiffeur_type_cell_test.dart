import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/coiffeur/data/coiffeur_score.dart';
import 'package:jasstafel/coiffeur/widgets/coiffeur_type_cell.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/settings/coiffeur_settings.g.dart';

import '../helper/testapp.dart';

void main() {
  testWidgets('change type', (WidgetTester tester) async {
    var data = BoardData(CoiffeurSettings(), CoiffeurScore(), "");
    final widget =
        makeTestable(CoiffeurTypeCell(data: data, row: 0, updateParent: () {}));

    await tester.pumpWidget(widget);

    expect(find.text('1'), findsOneWidget);
    expect(find.text('Eicheln'), findsOneWidget);

    await tester.longPress(find.byType(InkWell));
    await tester.pumpAndSettle();
    expect(find.text('Rosen'), findsOneWidget);
    await tester.tap(find.text('Rosen'));
    expect(find.text('Rosen'), findsNWidgets(2));
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(data.score.rows[0].type, 'Rosen');
  });

  testWidgets('change factor', (WidgetTester tester) async {
    var data = BoardData(CoiffeurSettings(), CoiffeurScore(), "");
    data.settings.customFactor = true;
    final widget =
        makeTestable(CoiffeurTypeCell(data: data, row: 5, updateParent: () {}));

    await tester.pumpWidget(widget);

    expect(find.text('6'), findsOneWidget);
    expect(find.text('Undenufe'), findsOneWidget);

    await tester.longPress(find.byType(InkWell));
    await tester.pumpAndSettle();
    expect(find.text('6'), findsNWidgets(2));
    await tester.tap(find.widgetWithText(DropdownMenuItem<int>, '6'));
    await tester.pump();
    await tester.tap(find.widgetWithText(IndexedSemantics, '11'));
    await tester.pump();

    expect(find.text('11'), findsOneWidget);
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(data.score.rows[5].factor, 11);
  });
}
