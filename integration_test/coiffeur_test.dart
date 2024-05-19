import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/data/common_data.dart';
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'overall_test.dart';

// cspell:ignore: zurück zählt fach auswertungsspalte eigene multiplikatoren
// cspell:ignore: punkte verwenden prämie ändern abbrechen gewonnen anzahl
// cspell:ignore: beide haben konter

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    await preferences.setString(CommonSettings.keys.appLanguage, 'de');
    await preferences.setInt(
        CommonSettings.keys.lastBoard, Board.coiffeur.index);
  });

  testWidgets('change type', (tester) async {
    await tester.launchApp();

    expect(find.text('Schellen'), findsOneWidget);

    await tester.longPress(find.text('Eicheln'));
    await tester.pump();

    expect(find.text('Welcher Jass zählt 1fach?'), findsWidgets);

    await tester.tap(find.text('Schaufel'));
    await tester.pump();

    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(find.text('Eicheln'), findsNothing);
    expect(find.text('Schaufel'), findsOneWidget);
  });

  testWidgets('add points', (tester) async {
    await tester.launchApp();

    await tester.addCoiffeurPoints('1:2', 56);
    await tester.addCoiffeurPoints('0:5', 50, tapKey: '157-x');

    expect(cellText(const Key('sum_0')), '${6 * 107}');
    expect(cellText(const Key('sum_1')), '${3 * 56}');
    expect(find.byKey(const Key('2:3')), findsNothing);
  });

  testWidgets('third column', (tester) async {
    await tester.launchApp();

    await tester.tapSetting(['Auswertungsspalte']);

    expect(find.text('0'), findsNWidgets(3));

    await tester.addCoiffeurPoints('1:3', 90);
    await tester.addCoiffeurPoints('0:8', 80, tapKey: '157-x');
    await tester.addCoiffeurPoints('0:3', 77);

    expect(cellText(const Key('sum_0')), '${9 * 77 + 4 * 77}');
    expect(cellText(const Key('sum_1')), '${4 * 90}');
    expect(cellText(const Key('sum_2')), '${4 * -13}');
  });

  testWidgets('3 teams', (tester) async {
    await tester.launchApp();

    await tester.tapSetting(['3 Teams']);

    expect(find.text('Team 3'), findsOneWidget);

    await tester.tap(find.text('Team 3'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Third Team');
    await tester.pump();
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(find.text('Team 3'), findsNothing);
    expect(find.text('Third Team'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(3));

    await tester.addCoiffeurPoints('0:2', 51);
    await tester.addCoiffeurPoints('1:6', 66);
    await tester.addCoiffeurPoints('2:8', 77);

    expect(cellText(const Key('sum_0')), '${3 * 51}');
    expect(cellText(const Key('sum_1')), '${7 * 66}');
    expect(cellText(const Key('sum_2')), '${9 * 77}');
  });

  testWidgets('rounded points', (tester) async {
    await tester.launchApp();

    await tester.tapSetting(['Punkte auf 10er Runden', 'Auswertungsspalte']);

    await tester.addCoiffeurPoints('1:3', 60);
    await tester.addCoiffeurPoints('0:8', 80, tapKey: '157-x');
    await tester.addCoiffeurPoints('0:3', 77);

    expect(cellText(const Key('1:3')), '6');
    expect(cellText(const Key('0:8')), '8');
    expect(cellText(const Key('0:3')), '8');
    expect(cellText(const Key('sum_0')), '${9 * 8 + 4 * 8}');
    expect(cellText(const Key('sum_1')), '${4 * 6}');
    expect(cellText(const Key('sum_2')), '${4 * 2}');

    await tester.switchBoard(to: 'Coiffeur');
    expect(cellText(const Key('1:3')), '6');
  });

  testWidgets('change no of rounds', (tester) async {
    await tester.launchApp();

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.slideTo("Anzahl Runden", 6);
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('1:3')), findsOneWidget);
    expect(find.byKey(const Key('2:3')), findsNothing);
    expect(find.byKey(const Key('1:6')), findsNothing);
  });

  testWidgets('custom factors', (tester) async {
    await tester.launchApp();

    await tester.addCoiffeurPoints('1:7', 97);
    expect(cellText(const Key('sum_1')), '${8 * 97}');

    await tester.tapSetting(['Eigene Multiplikatoren verwenden']);

    await tester.longPress(find.text('Gusti'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('dropdownFactor')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(cellText(const Key('1:7')), '97');
    expect(cellText(const Key('sum_1')), '${10 * 97}');
  });

  testWidgets('match bonus', (tester) async {
    await tester.launchApp();

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tapInList('Match-Punkte');
    await tester.pump();
    await tester.enterText(find.byType(TextField), '157');
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    await tester.tapInList('Match-Prämie verwenden');
    await tester.tapInList('Auswertungsspalte');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    await tester.addCoiffeurPoints('1:3', 56);
    await tester.addCoiffeurPoints('0:3', 0, tapKey: 'match');
    await tester.pumpAndSettle();

    expect(cellText(const Key('0:3')), 'MATCH');
    expect(cellText(const Key('sum_0')), '${4 * 157 + 500}');
    expect(cellText(const Key('sum_2')), '${4 * 101 + 500}');

    await tester.tapSetting(['Punkte auf 10er Runden']);

    expect(cellText(const Key('0:3')), 'MATCH');
    expect(cellText(const Key('sum_0')), '${4 * 16 + 50}');
    expect(cellText(const Key('sum_2')), '${4 * 10 + 50}');
  });

  testWidgets('toggle bonus', (tester) async {
    await tester.launchApp();

    await tester.addCoiffeurPoints('0:5', 157);
    await tester.addCoiffeurPoints('1:6', 0, tapKey: "match");

    expect(cellText(const Key('0:5')), '157');
    expect(cellText(const Key('1:6')), '257');

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tapInList('Match-Prämie verwenden');
    await tester.pumpAndSettle();
    expect(find.text('Match-Punkte auf 157 ändern?'), findsOneWidget);
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    expect(cellText(const Key('0:5')), '157');
    expect(cellText(const Key('1:6')), 'MATCH');

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tapInList('Match-Prämie verwenden');
    await tester.pump();
    expect(find.text('Match-Punkte auf 257 ändern?'), findsOneWidget);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    expect(cellText(const Key('0:5')), '157');
    expect(cellText(const Key('1:6')), '157');

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tapInList('Match-Prämie verwenden');
    await tester.pump();
    expect(find.text('Match-Punkte auf 257 ändern?'), findsNothing);
    await tester.tapInList('Match-Prämie verwenden');
    await tester.pump();
    expect(find.text('Match-Punkte auf 257 ändern?'), findsOneWidget);
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    expect(cellText(const Key('0:5')), '157');
    expect(cellText(const Key('1:6')), '257');
  });

  testWidgets('match bonus change', (tester) async {
    await tester.launchApp();

    await tester.addCoiffeurPoints('0:7', 88);
    await tester.addCoiffeurPoints('1:7', 0, tapKey: 'match');
    await tester.pumpAndSettle();
    expect(cellText(const Key('sum_0')), '${8 * 88}');
    expect(cellText(const Key('sum_1')), '${8 * 257}');

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tapInList('Match-Punkte');
    await tester.pump();
    await tester.enterText(find.byType(TextField), '157');
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    await tester.tapInList('Match-Prämie verwenden');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    expect(cellText(const Key('1:7')), 'MATCH');
    expect(cellText(const Key('sum_0')), '${8 * 88}');
    expect(cellText(const Key('sum_1')), '${8 * 157 + 500}');

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tapInList('Match-Prämie verwenden');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    await tester.scrollUpTo('Match-Punkte');
    await tester.tapInList('Match-Punkte');
    await tester.pump();
    await tester.enterText(find.byType(TextField), '207');
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    expect(cellText(const Key('1:7')), '207');
    expect(cellText(const Key('sum_0')), '${8 * 88}');
    expect(cellText(const Key('sum_1')), '${8 * 207}');
  });

  testWidgets('toggle bonus 2 decks', (tester) async {
    await tester.launchApp();

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tapInList('Match-Punkte');
    await tester.pump();
    await tester.enterText(find.byType(TextField), '514');
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    await tester.addCoiffeurPoints('0:5', 157);
    await tester.addCoiffeurPoints('1:6', 0, tapKey: "match");

    expect(cellText(const Key('0:5')), '157');
    expect(cellText(const Key('1:6')), '514');

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tapInList('Match-Prämie verwenden');
    await tester.pumpAndSettle();
    expect(find.text('Match-Punkte auf 314 ändern?'), findsOneWidget);
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    expect(cellText(const Key('0:5')), '157');
    expect(cellText(const Key('1:6')), 'MATCH');

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tapInList('Match-Prämie verwenden');
    await tester.pump();
    expect(find.text('Match-Punkte auf 514 ändern?'), findsOneWidget);
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    expect(cellText(const Key('0:5')), '157');
    expect(cellText(const Key('1:6')), '514');
  });

  testWidgets('add points 2 decks', (tester) async {
    await tester.launchApp();

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tapInList('Match-Punkte');
    await tester.pump();
    await tester.enterText(find.byType(TextField), '514');
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    await tester.addCoiffeurPoints('0:5', 50, tapKey: '157-x');

    expect(cellText(const Key('sum_0')), '${6 * 264}');
  });

  testWidgets('ignore hidden cells', (tester) async {
    await tester.launchApp();

    await tester.tapSetting(['3 Teams']);

    await tester.addCoiffeurPoints('0:10', 51);
    await tester.addCoiffeurPoints('1:6', 66);
    await tester.addCoiffeurPoints('2:8', 77);
    expect(cellText(const Key('sum_0')), '${11 * 51}');
    expect(cellText(const Key('sum_1')), '${7 * 66}');
    expect(cellText(const Key('sum_2')), '${9 * 77}');

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tapInList('3 Teams');
    await tester.pump();
    await tester.tapInList('Auswertungsspalte');
    await tester.slideTo("Anzahl Runden", 10);
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    expect(cellText(const Key('sum_0')), '0');
    expect(cellText(const Key('sum_1')), '${7 * 66}');
    expect(cellText(const Key('sum_2')), '0');
  });

  testWidgets('coiffeur info', (tester) async {
    await tester.launchApp();

    await tester.addCoiffeurPoints('0:8', 140);
    await tester.addCoiffeurPoints('1:6', 0, tapKey: "match");

    await tester.tap(find.byKey(const Key('InfoButton')));
    await tester.pumpAndSettle();
    expect(find.text('Team 1'), findsNWidgets(2));
    expect(find.text('Team 2'), findsNWidgets(2));
    expect(find.text('Team 3'), findsNothing);
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    await tester.tapSetting(['3 Teams']);

    await tester.tap(find.byKey(const Key('InfoButton')));
    await tester.pumpAndSettle();
    expect(find.text('Team 1'), findsNWidgets(2));
    expect(find.text('Team 2'), findsNWidgets(2));
    expect(find.text('Team 3'), findsNWidgets(2));
  });

  testWidgets('time stopped', (tester) async {
    clockSpeed = 120;

    minPlayed() {
      final elapsed = cellText(const Key('elapsed'))!;
      return int.parse(elapsed.split(" ")[0]);
    }

    await tester.launchApp();
    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tapInList('Auswertungsspalte');
    await tester.slideTo("Anzahl Runden", 6);
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    await tester.addCoiffeurPoints('0:0', 140);
    final t1 = minPlayed();
    sleep(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(minPlayed(), greaterThan(t1));
    await tester.addCoiffeurPoints('0:1', 140);
    await tester.addCoiffeurPoints('0:2', 140);
    await tester.addCoiffeurPoints('0:3', 140);
    await tester.addCoiffeurPoints('0:4', 140);
    await tester.addCoiffeurPoints('0:5', 140);
    await tester.addCoiffeurPoints('1:5', 110);
    await tester.addCoiffeurPoints('1:4', 110);
    await tester.addCoiffeurPoints('1:3', 110);
    await tester.addCoiffeurPoints('1:2', 110);

    expect(find.text('Gewonnen!'), findsOneWidget);
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    final tEnd = minPlayed();
    sleep(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(minPlayed(), tEnd);

    await tester.addCoiffeurPoints('1:1', 110);
    expect(minPlayed(), greaterThan(tEnd));
  });

  testWidgets('winner both', (tester) async {
    await tester.launchApp();

    for (var i = 0; i < 11; i++) {
      await tester.addCoiffeurPoints('0:$i', 140);
      await tester.addCoiffeurPoints('1:$i', 140);
    }
    expect(find.text('Beide Teams haben gewonnen!'), findsOneWidget);
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
  });

  testWidgets('counter ', (tester) async {
    await tester.launchApp();

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tapInList('Konter-Match-Strafe');
    await tester.pump();
    await tester.enterText(find.byType(TextField), '-500');
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    await tester.slideTo("Anzahl Runden", 6);
    await tester.pump();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    await tester.addCoiffeurPoints('0:0', 0, tapKey: "scratch");
    await tester.addCoiffeurPoints('0:1', 140);
    await tester.addCoiffeurPoints('0:2', 80);
    await tester.addCoiffeurPoints('0:3', 140);
    await tester.addCoiffeurPoints('0:4', 140);
    await tester.addCoiffeurPoints('0:5', 140);
    await tester.addCoiffeurPoints('1:1', 0, tapKey: "match");
    await tester.addCoiffeurPoints('1:2', 120);
    await tester.addCoiffeurPoints('1:3', 60);
    await tester.addCoiffeurPoints('1:4', 100);
    await tester.addCoiffeurPoints('1:5', 0, tapKey: "match");

    expect(find.text('Gewonnen!'), findsOneWidget);
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    await tester.delete('Ok');

    expect(find.text('0'), findsExactly(2));
  });
}
