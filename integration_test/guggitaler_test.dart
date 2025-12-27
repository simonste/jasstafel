import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'overall_test.dart';

// cspell:ignore: spielername runde handweis tischweis zurück punkte
// cspell:ignore: kein ziel zielpunkte anzahl erreicht gewonnen stiche rosen
// cspell:ignore: ober könig letzter eingeben

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    await preferences.setString(CommonSettings.keys.appLanguage, 'de');
    await preferences.setInt(
      CommonSettings.keys.lastBoard,
      Board.guggitaler.index,
    );
  });

  testWidgets('change name', (tester) async {
    await tester.launchApp();

    await tester.rename('Spieler 1', 'Simon');

    expect(find.text('Spieler 1'), findsNothing);
    expect(find.text('Simon'), findsOneWidget);
  });

  testWidgets('add points', (tester) async {
    await tester.launchApp();

    await tester.addGuggitalerPoints("Spieler 1", {'picker_0': 2});

    expect(text(const Key('sum_0')), '10');
    expect(text(const Key('sum_1')), '0');
    expect(text(const Key('sum_2')), '0');
    expect(text(const Key('sum_3')), '0');

    await tester.delete("Ok");
    expect(text(const Key('sum_0')), '0');
  });

  testWidgets('only 2 players', (tester) async {
    await tester.launchApp();

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.slideTo("Anzahl Spieler", 2);
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    expect(find.text('Spieler 3'), findsNothing);
    await tester.addGuggitalerPoints("Spieler 1", {
      'picker_0': 2,
      'picker_1': 1,
      'picker_2': 2,
      'picker_3': 0,
      'picker_4': 1,
    });

    expect(text(const Key('sum_0')), '110');
    expect(text(const Key('sum_1')), '0');
  });

  testWidgets('edit round', (tester) async {
    await tester.launchApp();

    await tester.addGuggitalerPoints("Spieler 3", {
      'picker_1': 1,
      'picker_3': 1,
    });

    expect(text(const Key('sum_2')), '50');
    await tester.longPress(find.text('50').first);
    await tester.pumpAndSettle();
    await tester.scrollNumberPicker('picker_1', 0);
    await tester.scrollNumberPicker('picker_2', 1);
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(text(const Key('sum_2')), '60');

    await tester.longPress(find.text('-').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spieler 1').last);
    await tester.pumpAndSettle();
    await tester.scrollNumberPicker('picker_0', 5);
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(text(const Key('sum_0')), '25');
    expect(text(const Key('sum_2')), '60');
  });

  testWidgets('edit domino', (tester) async {
    await tester.launchApp();

    await tester.tap(find.byTooltip('Domino Runde eingeben'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key("pts_1")));
    await tester.tap(find.byKey(Key("pts_0")));
    await tester.tap(find.byKey(Key("pts_2")));
    await tester.tap(find.byKey(Key("pts_3")));
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    expect(text(const Key('sum_2')), '-55');

    await tester.longPress(find.text('-150').first);
    await tester.enterText(find.byKey(const Key('pts_0')), '-150');
    await tester.pump();
    await tester.enterText(find.byKey(const Key('pts_1')), '-55');
    await tester.pump();
    await tester.enterText(find.byKey(const Key('pts_2')), '-100');
    await tester.pump();
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    expect(text(const Key('sum_2')), '-100');
  });

  testWidgets('full game', (tester) async {
    await tester.launchApp();

    // Stiche
    await tester.addGuggitalerPoints("Spieler 1", {'picker_0': 2});
    await tester.addGuggitalerPoints("Spieler 2", {'picker_0': 2});
    await tester.addGuggitalerPoints("Spieler 3", {'picker_0': 4});
    await tester.addGuggitalerPoints("Spieler 4", {'picker_0': 1});
    expect(text(const Key('sum_1')), '10');

    // Schellen
    await tester.addGuggitalerPoints("Spieler 1", {'picker_1': 4});
    await tester.addGuggitalerPoints("Spieler 2", {'picker_1': 2});
    await tester.addGuggitalerPoints("Spieler 4", {'picker_1': 3});
    expect(text(const Key('sum_1')), '30');

    // Ober
    await tester.addGuggitalerPoints("Spieler 1", {'picker_2': 2});
    await tester.addGuggitalerPoints("Spieler 2", {'picker_2': 1});
    await tester.addGuggitalerPoints("Spieler 3", {'picker_2': 1});
    expect(text(const Key('sum_1')), '50');

    // Rosen König
    await tester.addGuggitalerPoints("Spieler 2", {'picker_3': 1});
    expect(text(const Key('sum_1')), '90');

    // letzter Stich
    await tester.addGuggitalerPoints("Spieler 2", {'picker_4': 1});
    expect(text(const Key('sum_1')), '140');

    // domino
    await tester.tap(find.byTooltip('Domino Runde eingeben'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key("pts_1")));
    await tester.tap(find.byKey(Key("pts_0")));
    await tester.tap(find.byKey(Key("pts_2")));
    await tester.tap(find.byKey(Key("pts_3")));
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    expect(text(const Key('sum_1')), '-10');
  });
}
