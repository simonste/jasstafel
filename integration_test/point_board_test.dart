import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'overall_test.dart';

// cspell:ignore: spielername runde eingeben zurück punkte

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    await preferences.setString(CommonSettings.keys.appLanguage, 'de');
    await preferences.setInt(
        CommonSettings.keys.lastBoard, Board.pointBoard.index);
  });

  testWidgets('change name', (tester) async {
    await tester.launchApp();

    await tester.tap(find.text('Spieler 1'));
    await tester.pumpAndSettle();

    expect(find.text('Spielername'), findsWidgets);
    await tester.enterText(find.byType(TextField), 'Simon');
    await tester.pump();

    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    expect(find.text('Spieler 1'), findsNothing);
    expect(find.text('Simon'), findsOneWidget);
  });

  testWidgets('add points', (tester) async {
    await tester.launchApp();

    await tester.tap(find.byTooltip('Runde eingeben'));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('pts_0')), '10');
    await tester.enterText(find.byKey(const Key('pts_1')), '20');
    await tester.enterText(find.byKey(const Key('pts_2')), '30');
    await tester.pump();
    await tester.tap(find.byKey(const Key('pts_3')));
    await tester.pump();
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(text(const Key('sum_0')), '10');
    expect(text(const Key('sum_1')), '20');
    expect(text(const Key('sum_2')), '30');
    expect(text(const Key('sum_3')), '97');
  });
  testWidgets('rounded', (tester) async {
    await tester.launchApp();

    await tester.tapSetting(['Punkte auf 10er Runden']);

    await tester.tap(find.byTooltip('Runde eingeben'));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('pts_0')), '14');
    await tester.enterText(find.byKey(const Key('pts_1')), '23');
    await tester.enterText(find.byKey(const Key('pts_2')), '26');
    await tester.pump();
    await tester.tap(find.byKey(const Key('pts_3')));
    await tester.pump();
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(text(const Key('sum_0')), '1');
    expect(text(const Key('sum_1')), '2');
    expect(text(const Key('sum_2')), '3');
    expect(text(const Key('sum_3')), '9');
  });

  testWidgets('only 2 players', (tester) async {
    await tester.launchApp();

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.slideTo(find.byType(Slider), 2);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    expect(find.text('Spieler 3'), findsNothing);

    await tester.tap(find.byTooltip('Runde eingeben'));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('pts_0')), '77');
    await tester.pump();
    await tester.tap(find.byKey(const Key('pts_1')));
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(text(const Key('sum_0')), '77');
    expect(text(const Key('sum_1')), '80');
  });

  testWidgets('edit round', (tester) async {
    await tester.launchApp();

    await tester.tap(find.byTooltip('Runde eingeben'));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('pts_0')), '157');
    await tester.pump();
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('0').first);

    await tester.enterText(find.byKey(const Key('pts_2')), '157');
    await tester.pump();
    await tester.enterText(find.byKey(const Key('pts_0')), '');
    await tester.pump();
    await tester.tap(find.byKey(const Key('pts_1')));
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(text(const Key('sum_0')), '0');
    expect(text(const Key('sum_1')), '0');
    expect(text(const Key('sum_2')), '157');
    expect(text(const Key('sum_3')), '0');
  });
}
