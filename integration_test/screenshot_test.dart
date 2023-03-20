import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'overall_test.dart';

// cspell:ignore: auswertungsspalte runde eingeben handweis tischweis hilfslinien anzeigen

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

    await tester.tap(find.byTooltip('Runde eingeben'));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('pts_0')), '51');
    await tester.enterText(find.byKey(const Key('pts_1')), '0');
    await tester.enterText(find.byKey(const Key('pts_2')), '66');
    await tester.pump();
    await tester.tap(find.byKey(const Key('pts_3')));
    await tester.pump();
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    await tester.takeScreenshot(binding, 'molotow1');
  });
}
