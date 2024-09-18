import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/differenzler/data/differenzler_score.dart';
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:jasstafel/settings/differenzler_settings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'overall_test.dart';

// cspell:ignore: spielername runde eingeben ansage punkte ansagen verstecken
// cspell:ignore: kein ziel zielpunkte anzahl erreicht gewonnen zurück

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    await preferences.setString(CommonSettings.keys.appLanguage, 'de');
    await preferences.setInt(
        CommonSettings.keys.lastBoard, Board.differenzler.index);
  });

  testWidgets('change name', (tester) async {
    await tester.launchApp();

    await tester.rename('Spieler 1', 'Simon');

    expect(find.text('Spieler 1'), findsNothing);
    expect(find.text('Simon'), findsOneWidget);
  });

  testWidgets('play some rounds', (tester) async {
    await tester.launchApp();

    expect(find.byTooltip('Runde eingeben'), findsNothing);
    await tester.addDifferenzlerGuessPoints('Spieler 2', 55);
    expect(find.byTooltip('Ansage von Spieler 2'), findsNothing);
    await tester.addDifferenzlerGuessPoints('Spieler 1', 0);
    await tester.addDifferenzlerGuessPoints('Spieler 4', 80);
    expect(find.byTooltip('Runde eingeben'), findsNothing);
    await tester.addDifferenzlerGuessPoints('Spieler 3', 0);
    expect(find.byTooltip('Runde eingeben'), findsOneWidget);
    expect(find.text('***'), findsNWidgets(4));

    expect(text(const Key('sum_0')), '0');
    expect(text(const Key('sum_1')), '0');
    expect(text(const Key('sum_2')), '0');
    expect(text(const Key('sum_3')), '0');

    await tester.addRound({
      'pts_0': 20,
      'pts_1': 55,
      'pts_2': 5,
      'pts_3': null,
    });

    expect(text(const Key('guess_0_1')), '0');
    expect(text(const Key('guess_0_2')), '55');
    expect(text(const Key('guess_0_3')), '0');
    expect(text(const Key('guess_0_4')), '80');

    expect(text(const Key('sum_0')), '20');
    expect(text(const Key('sum_1')), '0');
    expect(text(const Key('sum_2')), '5');
    expect(text(const Key('sum_3')), '3');

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

    await tester.addDifferenzlerGuessPoints('Spieler 2', 0);
    expect(find.byTooltip('Ansage von Spieler 2'), findsNothing);
    await tester.addDifferenzlerGuessPoints('Spieler 1', 150);
    expect(find.text('***'), findsNWidgets(2));
    await tester.addRound({'pts_1': 30, 'pts_0': null});
    expect(text(const Key('sum_0')), '23');
    expect(text(const Key('sum_1')), '30');

    await tester.addDifferenzlerGuessPoints('Spieler 1', 44);
    expect(find.byTooltip('Ansage von Spieler 1'), findsNothing);
    expect(find.text('***'), findsOneWidget);
    await tester.addDifferenzlerGuessPoints('Spieler 2', 80);
    await tester.addRound({'pts_0': 44, 'pts_1': null});
    expect(text(const Key('sum_0')), '23');
    expect(text(const Key('sum_1')), '63');
  });

  testWidgets('show guess', (tester) async {
    await tester.launchApp();

    await tester.addDifferenzlerGuessPoints('Spieler 2', 55);
    expect(text(const Key('guess_0_2')), '***');
    await tester.tapSetting(['Ansagen verstecken']);
    expect(text(const Key('guess_0_2')), '55');
    expect(find.byTooltip('Ansage von Spieler 2'), findsNothing);
    await tester.addDifferenzlerGuessPoints('Spieler 1', 4);
    expect(text(const Key('guess_0_1')), '4');
    await tester.addDifferenzlerGuessPoints('Spieler 4', 80);
    expect(text(const Key('guess_0_4')), '80');
    expect(find.byTooltip('Runde eingeben'), findsNothing);
  });

  testWidgets('edit round', (tester) async {
    await tester.launchApp();

    await tester.addDifferenzlerGuessPoints('Spieler 1', 40);
    await tester.addDifferenzlerGuessPoints('Spieler 2', 41);
    await tester.addDifferenzlerGuessPoints('Spieler 3', 42);
    await tester.addDifferenzlerGuessPoints('Spieler 4', 43);
    await tester.addRound({
      'pts_0': 30,
      'pts_1': 40,
      'pts_2': 50,
      'pts_3': null,
    });

    await tester.longPress(find.text('50').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('pts_2')), '42');
    await tester.pump();
    await tester.enterText(find.byKey(const Key('pts_0')), '');
    await tester.pump();
    await tester.tap(find.byKey(const Key('pts_1')));
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(text(const Key('sum_0')), '2');
    expect(text(const Key('sum_1')), '1');
    expect(text(const Key('sum_2')), '0');
    expect(text(const Key('sum_3')), '6');
  });

  testWidgets('goal points', (tester) async {
    await tester.launchApp();

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.slideTo("Anzahl Spieler", 3);
    await tester.tapInList('kein Ziel');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zielpunkte').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zielpunkte').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '50');
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    await tester.addDifferenzlerGuessPoints('Spieler 1', 66);
    await tester.addDifferenzlerGuessPoints('Spieler 2', 20);
    await tester.addDifferenzlerGuessPoints('Spieler 3', 50);
    await tester.addRound({'pts_0': 46, 'pts_1': 30, 'pts_2': null});

    await tester.addDifferenzlerGuessPoints('Spieler 1', 66);
    await tester.addDifferenzlerGuessPoints('Spieler 2', 20);
    await tester.addDifferenzlerGuessPoints('Spieler 3', 50);
    await tester.addRound({'pts_0': 46, 'pts_1': 30, 'pts_2': null});

    expect(
        find.text(
            'Spieler 2 hat gewonnen!\n\nSpieler 3 hat die Zielpunkte erreicht!'),
        findsOneWidget);
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(text(const Key('sum_0')), '40');
    expect(text(const Key('sum_1')), '20');
    expect(text(const Key('sum_2')), '62');
  });

  testWidgets('goal rounds', (tester) async {
    await tester.launchApp();

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.slideTo("Anzahl Spieler", 2);
    await tester.tapInList('kein Ziel');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anzahl Runden').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anzahl Runden').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '3');
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      await tester.addDifferenzlerGuessPoints('Spieler 1', 66 + 2 * i);
      await tester.addDifferenzlerGuessPoints('Spieler 2', 80 - 2 * i);
      await tester.addRound({'pts_0': 50 + 5 * i, 'pts_1': null});
    }

    expect(find.text('Spieler 1 hat gewonnen!'), findsOneWidget);
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(text(const Key('sum_0')), '39');
    expect(text(const Key('sum_1')), '72');
  });

  testWidgets('scrollable', (tester) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    var score = DifferenzlerScore();
    var row = DifferenzlerRow();
    row.guesses = [33, 28, 88, 0];
    row.pts = [20, 40, 85, 12];
    score.rows = List.filled(20, row);

    await preferences.setString(
        DifferenzlerSettings.keys.data, jsonEncode(score.toJson()));

    await tester.launchApp();

    expect(find.byTooltip('Ansage von Spieler 1').hitTestable(), findsNothing);
    expect(find.byTooltip('Ansage von Spieler 2').hitTestable(), findsNothing);
    await tester.addDifferenzlerGuessPoints('Spieler 1', 40);
    expect(find.byTooltip('Ansage von Spieler 1'), findsNothing);
    expect(
        find.byTooltip('Ansage von Spieler 2').hitTestable(), findsOneWidget);
  });
}
