import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'overall_test.dart';

// cspell:ignore: auswertungsspalte runde handweis tischweis hilfslinien
// cspell:ignore: anzeigen rückseite verwenden punkte zurück

bool driverTest = false;

extension AppHelper on WidgetTester {
  Future<void> takeScreenshot(
      IntegrationTestWidgetsFlutterBinding? binding, name) async {
    if (Platform.isAndroid) {
      await pumpAndSettle();
    }
    await pumpAndSettle();
    await binding?.takeScreenshot(name);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding? binding;
  if (driverTest) {
    binding = IntegrationTestWidgetsFlutterBinding();
  } else {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  }

  // remove debug banner for screenshots
  WidgetsApp.debugAllowBannerOverride = false;

  setUp(() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    await preferences.setString(CommonSettings.keys.appLanguage, 'de');
    await preferences.setInt(
        CommonSettings.keys.lastBoard, Board.schieber.index);
  });

  testWidgets('schieber #1', (tester) async {
    await tester.launchApp();
    await binding?.convertFlutterSurfaceToImage();

    await tester.addSchieberPoints(['add_1', 'key_2', 'key_3'], factor: '4x');
    await tester.addSchieberPoints(['add_1', 'key_8', 'key_3'], factor: '2x');
    await tester.addSchieberPoints(['add_1', 'key_8', 'key_3'], factor: '2x');

    await tester.takeScreenshot(binding, 'schieber1');

    await tester.tapSetting(['Hilfslinien (Z) anzeigen']);
    await tester.takeScreenshot(binding, 'schieber2');

    await tester.tapSetting(['Rückseite verwenden']);
    await tester.tap(find.byKey(const Key('backside')));
    await tester.pumpAndSettle();
    expect(await tester.backsideStrokes(0, 2), 2);
    expect(await tester.backsideStrokes(1, 15), 15);
    expect(await tester.backsideStrokes(0, 2), 4);
    expect(await tester.backsideStrokes(2, 2), 2);
    await tester.takeScreenshot(binding, 'schieber3');
  });

  testWidgets('coiffeur #1', (tester) async {
    await tester.launchApp();
    await binding?.convertFlutterSurfaceToImage();
    await tester.switchBoard(from: 'Schieber', to: 'Coiffeur');

    await tester.addCoiffeurPoints('0:0', 0, tapKey: "scratch");
    await tester.addCoiffeurPoints('0:6', 87);
    await tester.addCoiffeurPoints('0:8', 88);
    await tester.addCoiffeurPoints('0:8', 131);
    await tester.addCoiffeurPoints('0:10', 122);
    await tester.addCoiffeurPoints('1:2', 55);
    await tester.addCoiffeurPoints('1:4', 132);
    await tester.addCoiffeurPoints('1:5', 51);
    await tester.addCoiffeurPoints('1:7', 0, tapKey: "match");

    await tester.takeScreenshot(binding, 'coiffeur1');

    await tester.tapSetting(['Auswertungsspalte']);

    changeType(String from, String to) async {
      await tester.longPress(find.text(from).first);
      await tester.pump();
      await tester.tap(find.text(to));
      await tester.pump();
      await tester.tap(find.text('Ok'));
      await tester.pumpAndSettle();
    }

    await changeType('Eicheln', 'Schaufel');
    await changeType('Schellen', 'Kreuz');
    await changeType('Schilten', 'Ecken');
    await changeType('Rosen', 'Herz');
    await changeType('Wunsch', 'Misere');

    await tester.takeScreenshot(binding, 'coiffeur2');
  });

  testWidgets('molotow #1', (tester) async {
    await tester.launchApp();
    await binding?.convertFlutterSurfaceToImage();
    await tester.switchBoard(from: 'Schieber', to: 'Molotow');

    await tester.addRound({
      'pts_0': 14,
      'pts_1': 23,
      'pts_2': 26,
      'pts_3': null,
    });

    await tester.tap(find.byTooltip('Handweis'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spieler 2').last);
    await tester.pump();
    await tester.tap(find.text('50'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Tischweis'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spieler 2').last);
    await tester.pump();
    await tester.tap(find.text('20'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Tischweis'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spieler 4').last);
    await tester.pump();
    await tester.tap(find.text('50'));
    await tester.pumpAndSettle();

    await tester.addRound({
      'pts_0': 51,
      'pts_1': 0,
      'pts_2': 66,
      'pts_3': null,
    });

    await tester.takeScreenshot(binding, 'molotow1');
  });

  testWidgets('differenzler #1', (tester) async {
    await tester.launchApp();
    await binding?.convertFlutterSurfaceToImage();
    await tester.switchBoard(from: 'Schieber', to: 'Differenzler');

    await tester.rename('Spieler 1', 'John');
    await tester.rename('Spieler 2', 'Paul');
    await tester.rename('Spieler 3', 'Ringo');
    await tester.rename('Spieler 4', 'George');

    await tester.addDifferenzlerGuessPoints('John', 66);
    await tester.addDifferenzlerGuessPoints('Paul', 20);
    await tester.addDifferenzlerGuessPoints('Ringo', 0);
    await tester.addDifferenzlerGuessPoints('George', 50);
    await tester.addRound({
      'pts_0': 58,
      'pts_1': 31,
      'pts_2': 0,
      'pts_3': null,
    });

    await tester.addDifferenzlerGuessPoints('John', 12);
    await tester.addDifferenzlerGuessPoints('Paul', 78);
    await tester.addDifferenzlerGuessPoints('Ringo', 44);
    await tester.addDifferenzlerGuessPoints('George', 30);
    await tester.addRound({
      'pts_0': 22,
      'pts_1': 77,
      'pts_2': 12,
      'pts_3': null,
    });

    await tester.addDifferenzlerGuessPoints('John', 0);
    await tester.addDifferenzlerGuessPoints('Paul', 0);
    await tester.addDifferenzlerGuessPoints('Ringo', 70);
    await tester.addDifferenzlerGuessPoints('George', 66);
    await tester.addRound({
      'pts_0': 0,
      'pts_1': 0,
      'pts_2': 99,
      'pts_3': null,
    });

    await tester.addDifferenzlerGuessPoints('John', 33);
    await tester.addDifferenzlerGuessPoints('Paul', 33);
    await tester.addDifferenzlerGuessPoints('George', 33);

    await tester.takeScreenshot(binding, 'differenzler1');
  });

  testWidgets('punktetafel #1', (tester) async {
    await tester.launchApp();
    await binding?.convertFlutterSurfaceToImage();
    await tester.switchBoard(from: 'Schieber', to: 'Punktetafel');

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.slideTo(find.byType(Slider), 6);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Punkte pro Runde'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '9');
    await tester.tap(find.text('Ok'));
    await tester.pump();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    await tester.addRound({
      'pts_0': 1,
      'pts_1': 0,
      'pts_2': 2,
      'pts_3': 0,
      'pts_4': 1,
      'pts_5': null,
    });

    await tester.addRound({
      'pts_0': 0,
      'pts_1': 0,
      'pts_2': 3,
      'pts_3': 3,
      'pts_4': 3,
      'pts_5': null,
    });

    await tester.addRound({
      'pts_0': 2,
      'pts_1': 4,
      'pts_2': 1,
      'pts_3': 0,
      'pts_4': 2,
      'pts_5': null,
    });

    await tester.addRound({
      'pts_0': 7,
      'pts_1': 0,
      'pts_2': 1,
      'pts_3': 0,
      'pts_4': 0,
      'pts_5': null,
    });

    await tester.takeScreenshot(binding, 'punktetafel1');
  });
}
