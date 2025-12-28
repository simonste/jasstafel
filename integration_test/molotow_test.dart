import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/molotow/data/molotow_score.dart';
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:jasstafel/settings/molotow_settings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'overall_test.dart';

// cspell:ignore: spielername runde handweis tischweis zurück punkte
// cspell:ignore: kein ziel zielpunkte anzahl erreicht gewonnen

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    await preferences.setString(CommonSettings.keys.appLanguage, 'de');
    await preferences.setInt(
      CommonSettings.keys.lastBoard,
      Board.molotow.index,
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

    await tester.addRound({
      'pts_0': 10,
      'pts_1': 20,
      'pts_2': 30,
      'pts_3': null,
    });

    expect(text(const Key('sum_0')), '10');
    expect(text(const Key('sum_1')), '20');
    expect(text(const Key('sum_2')), '30');
    expect(text(const Key('sum_3')), '97');

    await tester.delete("Ok");
    expect(text(const Key('sum_0')), '0');
  });

  testWidgets('add handweis', (tester) async {
    await tester.launchApp();

    await tester.tap(find.byTooltip('Handweis'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Spieler 2').last);
    await tester.pump();
    await tester.tap(find.text('50'));
    await tester.pumpAndSettle();

    expect(text(const Key('sum_0')), '0');
    expect(text(const Key('sum_1')), '-50');
    expect(text(const Key('sum_2')), '0');
    expect(text(const Key('sum_3')), '0');
  });

  testWidgets('rounded', (tester) async {
    await tester.launchApp();

    await tester.tapSetting(['Punkte auf 10er Runden']);

    await tester.addRound({
      'pts_0': 14,
      'pts_1': 23,
      'pts_2': 26,
      'pts_3': null,
    });

    expect(text(const Key('sum_0')), '1');
    expect(text(const Key('sum_1')), '2');
    expect(text(const Key('sum_2')), '3');
    expect(text(const Key('sum_3')), '9');

    await tester.switchBoard(to: 'Molotow');
    expect(text(const Key('sum_0')), '1');
  });

  testWidgets('only 2 players', (tester) async {
    await tester.launchApp();

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.slideTo("Anzahl Spieler", 2);
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    expect(find.text('Spieler 3'), findsNothing);

    await tester.addRound({'pts_0': 77, 'pts_1': null});

    expect(text(const Key('sum_0')), '77');
    expect(text(const Key('sum_1')), '80');
  });

  testWidgets('edit round', (tester) async {
    await tester.launchApp();

    await tester.addRound({'pts_0': 157});

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

  testWidgets('edit weis', (tester) async {
    await tester.launchApp();

    await tester.launchApp();

    await tester.tap(find.byTooltip('Tischweis'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Spieler 3').last);
    await tester.pump();
    await tester.tap(find.text('20'));
    await tester.pumpAndSettle();

    expect(find.text('-'), findsNWidgets(3));
    await tester.longPress(find.text('-').first);

    await tester.enterText(find.byKey(const Key('pts_1')), '20');
    await tester.pump();
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(find.text('-'), findsNWidgets(2));

    expect(text(const Key('sum_0')), '0');
    expect(text(const Key('sum_1')), '20');
    expect(text(const Key('sum_2')), '20');
    expect(text(const Key('sum_3')), '0');
  });

  testWidgets('goal points', (tester) async {
    await tester.launchApp();

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tapInList('kein Ziel');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zielpunkte').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zielpunkte').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '88');
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    await tester.addRound({'pts_0': 70, 'pts_1': 70, 'pts_2': 17});

    await tester.tap(find.byTooltip('Tischweis'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spieler 2').last);
    await tester.pump();
    await tester.tap(find.text('50'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Spieler 4 hat gewonnen!\n\nSpieler 2 hat die Zielpunkte erreicht!',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(text(const Key('sum_0')), '70');
    expect(text(const Key('sum_1')), '120');
    expect(text(const Key('sum_2')), '17');
    expect(text(const Key('sum_3')), '0');
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
      await tester.tap(find.byTooltip('Handweis'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spieler 1').last);
      await tester.pump();
      await tester.tap(find.text('20'));
      await tester.pumpAndSettle();

      await tester.addRound({'pts_0': 80, 'pts_1': null});
    }

    expect(find.text('Spieler 1 hat gewonnen!'), findsOneWidget);
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(text(const Key('sum_0')), '180');
    expect(text(const Key('sum_1')), '231');
  });

  testWidgets('scrollable', (tester) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    var score = MolotowScore();
    score.rows = List.filled(24, MolotowRow([25, 50, 66, 16], isRound: true));

    await preferences.setString(
      MolotowSettings.keys.data,
      jsonEncode(score.toJson()),
    );

    await tester.launchApp();

    expect(find.byTooltip('Handweis').hitTestable(), findsOneWidget);
    expect(find.byTooltip('Tischweis').hitTestable(), findsOneWidget);
    expect(tester.getCenter(find.byTooltip('Handweis')).dy, greaterThan(500));

    await tester.scroll(const Offset(0, -300));

    expect(find.byTooltip('Handweis').hitTestable(), findsOneWidget);
    expect(find.byTooltip('Tischweis').hitTestable(), findsOneWidget);
    expect(tester.getCenter(find.byTooltip('Handweis')).dy, lessThan(500));

    await tester.scroll(const Offset(0, 300));
    expect(tester.getCenter(find.byTooltip('Handweis')).dy, greaterThan(500));
  });
}
