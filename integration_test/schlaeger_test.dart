import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'overall_test.dart';

// cspell:ignore: zurück ziel zielpunkte anzahl erreicht gewonnen unten rechts links

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    await preferences.setString(CommonSettings.keys.appLanguage, 'de');
    await preferences.setInt(
        CommonSettings.keys.lastBoard, Board.schlaeger.index);
  });

  testWidgets('change name', (tester) async {
    await tester.launchApp();

    await tester.rename('Spieler 1', 'Simon');

    expect(find.text('Spieler 1'), findsNothing);
    expect(find.text('Simon'), findsOneWidget);
  });

  testWidgets('add points', (tester) async {
    await tester.launchApp();

    await tester.addSchlaegerRound({
      'pts_0': 2,
      'pts_1': 1,
      'pts_2': -1,
      'pts_3': null,
    });

    expect(text(const Key('sum_0')), '2');
    expect(text(const Key('sum_1')), '1');
    expect(text(const Key('sum_2')), '-1');
    expect(find.byKey(const Key('sum_3')), findsNothing);
  });

  testWidgets('3 players lower left', (tester) async {
    await tester.launchApp();

    expect(find.text('Spieler 4'), findsNothing);

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unten Rechts').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unten Links'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    expect(find.text('Spieler 4'), findsNothing);

    await tester.addSchlaegerRound({
      'pts_0': 2,
      'pts_1': 1,
      'pts_2': -1,
    });
  });

  testWidgets('4 players', (tester) async {
    await tester.launchApp();

    expect(find.text('Spieler 4'), findsNothing);

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.slideTo("Anzahl Spieler", 4);
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    expect(find.text('Spieler 4'), findsOneWidget);

    await tester.addSchlaegerRound({
      'pts_0': 1,
      'pts_1': 1,
      'pts_3': 1,
    });

    expect(text(const Key('sum_0')), '1');
    expect(text(const Key('sum_1')), '1');
    expect(text(const Key('sum_2')), '0');
    expect(text(const Key('sum_3')), '1');
  });

  testWidgets('edit round', (tester) async {
    await tester.launchApp();

    await tester.addSchlaegerRound({'pts_0': 3});

    await tester.longPress(find.byKey(const Key('scores_1')));

    await tester.tap(find.descendant(
        of: find.byKey(const Key("pts_1")), matching: find.text("1")));
    await tester.tap(find.descendant(
        of: find.byKey(const Key("pts_0")), matching: find.text("2")));

    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(text(const Key('sum_0')), '2');
    expect(text(const Key('sum_1')), '1');
    expect(text(const Key('sum_2')), '0');
  });

  testWidgets('goal points', (tester) async {
    await tester.launchApp();

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zielpunkte').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '4');
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    await tester.addSchlaegerRound({
      'pts_0': 1,
      'pts_1': -1,
      'pts_2': 2,
    });
    await tester.addSchlaegerRound({
      'pts_0': -1,
      'pts_1': 0,
      'pts_2': 2,
    });

    expect(find.text('Spieler 3 hat die Zielpunkte erreicht!'), findsOneWidget);
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(text(const Key('sum_1')), '-1');
    expect(text(const Key('sum_2')), '4');
  });

  testWidgets('goal rounds', (tester) async {
    await tester.launchApp();

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zielpunkte').first);
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
      await tester.addSchlaegerRound({
        'pts_0': 1,
        'pts_1': 2,
        'pts_2': -1,
      });
    }

    expect(find.text('Spieler 2 hat gewonnen!'), findsOneWidget);
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(text(const Key('sum_1')), '6');
    expect(text(const Key('sum_2')), '-3');
  });
}
