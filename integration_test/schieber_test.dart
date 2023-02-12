import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'overall_test.dart';

// cspell:ignore: zurück punkte verschiedene zielpunkte kopieren profil sieg
// cspell:ignore: teamname hilfslinien anzeigen bergpreis gewonnen anzahl alles
// cspell:ignore: aktuelle runde stiche

String? text(Key key, {int? elementNo}) {
  var elements = find.byKey(key).evaluate();
  Text textWidget;
  if (elementNo == null) {
    textWidget = elements.single.widget as Text;
  } else {
    textWidget = elements.elementAt(elementNo).widget as Text;
  }
  return textWidget.data;
}

extension SchieberHelper on WidgetTester {
  Future<void> addPoints(List<String> keys,
      {String? factor, bool? weis}) async {
    for (final key in keys) {
      await tap(find.byKey(Key(key)));
      await pumpAndSettle();
    }
    if (factor != null) {
      await tap(find.byKey(const Key('dropdownFactor')));
      await pumpAndSettle();
      await tap(find.text(factor).last);
      await pumpAndSettle();
    }
    await tap(find.text((weis ?? false) ? 'Weis' : 'Ok'));
    await pumpAndSettle();
  }

  Future<void> delete(String buttonText) async {
    await tap(find.byKey(const Key('delete')));
    await pumpAndSettle();
    await tap(find.text(buttonText));
    await pumpAndSettle();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    await preferences.setString(CommonSettings.keys.appLanguage, 'de');
    await preferences.setInt(
        CommonSettings.keys.lastBoard, Board.schieber.index);
  });

  testWidgets('change team name', (tester) async {
    await tester.launchApp();

    expect(find.text('Team 1'), findsOneWidget);

    await tester.tap(find.text('Team 1'));
    await tester.pumpAndSettle();

    expect(find.text('Teamname'), findsWidgets);
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Super Team');
    await tester.pump();

    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    expect(find.text('Team 1'), findsNothing);
    expect(find.text('Super Team'), findsOneWidget);
  });

  testWidgets('do not accept empty team name', (tester) async {
    await tester.launchApp();

    expect(find.text('Team 2'), findsOneWidget);
    await tester.tap(find.text('Team 2'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    expect(find.text('Team 2'), findsOneWidget);
  });

  testWidgets('change goal points', (tester) async {
    await tester.launchApp();

    expect(find.text('2500'), findsOneWidget);

    await tester.tap(find.text('2500'));
    await tester.pumpAndSettle();

    expect(find.text('Punkte'), findsWidgets);
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), '2121');
    await tester.pump();

    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    expect(find.text('2500'), findsNothing);
    expect(find.text('2121'), findsOneWidget);
  });

  testWidgets('change goal points 2', (tester) async {
    await tester.launchApp();

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('verschiedene Zielpunkte'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    expect(find.text('2500'), findsNWidgets(2));

    var gp0 = find.byKey(const Key('GoalPoints0'));
    var gp1 = find.byKey(const Key('GoalPoints1'));
    expect(gp0, findsOneWidget);
    expect(gp1, findsOneWidget);

    await tester.tap(gp0);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '2121');
    await tester.pump();
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    await tester.tap(gp1);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1212');
    await tester.pump();
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(find.text('1212'), findsOneWidget);
    expect(find.text('2121'), findsOneWidget);
  });

  testWidgets('add points touch', (tester) async {
    await tester.launchApp();

    await tester.tap(find.byKey(const Key('add20_1')));
    await tester.tap(find.byKey(const Key('add20_1')));
    await tester.tap(find.byKey(const Key('add100_1')));
    await tester.tap(find.byKey(const Key('subtract1_1')));
    await tester.pump();
    expect(text(const Key('sum_0')), '0');
    expect(text(const Key('sum_1')), '139');

    await tester.tap(find.byKey(const Key('add100_0')));
    await tester.tap(find.byKey(const Key('add50_0')));
    await tester.tap(find.byKey(const Key('add1_0')));
    await tester.pump();
    expect(text(const Key('sum_0')), '151');
    expect(text(const Key('sum_1')), '139');
  });

  testWidgets('add round', (tester) async {
    await tester.launchApp();

    await tester.addPoints(['add_1', 'key_2', 'key_3'], factor: '4x');

    expect(text(const Key('sum_0')), '536');
    expect(text(const Key('sum_1')), '92');
  });

  testWidgets('add match', (tester) async {
    await tester.launchApp();

    await tester.addPoints(['add_0', 'key_2', 'key_Match']);

    expect(text(const Key('sum_0')), '257');
    expect(text(const Key('sum_1')), '0');
  });

  testWidgets('add weis', (tester) async {
    await tester.launchApp();

    await tester.addPoints(
        ['add_0', 'key_2', 'key_∅', 'key_5', 'key_1', 'key_←', 'key_0'],
        factor: '3x', weis: true);

    expect(text(const Key('sum_0')), '150');
    expect(text(const Key('sum_1')), '0');
  });

  testWidgets('profile', (tester) async {
    await tester.launchApp();

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Standard'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Profil kopieren'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '2nd Profile');
    await tester.pump();
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2nd Profile'));
    await tester.pump();

    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hilfslinien (Z) anzeigen'));
    await tester.tap(find.text('verschiedene Zielpunkte'));
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    expect(find.text('2500'), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('add20_0')));
    await tester.tap(find.byKey(const Key('add50_1')));
    await tester.tap(find.byKey(const Key('add50_1')));
    await tester.pump();
    expect(text(const Key('sum_0')), '20');
    expect(text(const Key('sum_1')), '100');

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2nd Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Standard'));
    await tester.pump();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    expect(find.text('2500'), findsNWidgets(1));
    expect(text(const Key('sum_0')), '0');
    expect(text(const Key('sum_1')), '0');
  });

  testWidgets('check winner', (tester) async {
    await tester.launchApp();

    await tester.tap(find.text('2500'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '400');
    await tester.pump();
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    await tester.addPoints(['add_1', 'key_7', 'key_3'], factor: '3x');

    expect(find.text('Bergpreis'), findsOneWidget);
    await tester.tap(find.text('Team 2').last);
    await tester.pumpAndSettle();

    expect(text(const Key('sum_0')), '252');
    expect(text(const Key('sum_1')), '219');

    await tester.addPoints(['add_0', 'flip', 'key_Match']);

    expect(find.text('Gewonnen!'), findsOneWidget);
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('statistics')));
    await tester.pumpAndSettle();

    expect(text(const Key('Bergpreis_1'), elementNo: 0), '');
    expect(text(const Key('Bergpreis_2'), elementNo: 0), '✓');
    expect(text(const Key('Sieg_1')), '✓');
    expect(text(const Key('Sieg_2')), '');

    expect(text(const Key('Bergpreis_1'), elementNo: 1), '0');
    expect(text(const Key('Bergpreis_2'), elementNo: 1), '1');
    expect(text(const Key('Siege_1')), '1');
    expect(text(const Key('Siege_2')), '0');

    await tester.tap(find.text('Ok'));
  });

  testWidgets('check winner rounds', (tester) async {
    await tester.launchApp();

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zielpunkte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anzahl Runden').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('0 / 8'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '2');
    await tester.pump();
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    await tester.addPoints(['add_1', 'key_7', 'key_8']);
    await tester.addPoints(['add_0', 'key_5', 'key_8']);

    expect(find.text('Gewonnen!'), findsOneWidget);
  });
  testWidgets('delete button', (tester) async {
    await tester.launchApp();

    await tester.tap(find.byKey(const Key('add20_1')));
    await tester.addPoints(['add_0', 'key_6', 'key_2']);

    await tester.delete('Alles');

    expect(text(const Key('sum_0')), '0');
    expect(text(const Key('sum_1')), '0');
  });

  testWidgets('delete only current round', (tester) async {
    await tester.launchApp();

    await tester.addPoints(['add_0', 'key_Match'], factor: '7x');
    await tester.addPoints(['add_0', 'key_1', 'key_3', 'key_5'], factor: '6x');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    await tester.delete('Aktuelle Runde');

    expect(text(const Key('sum_0')), '0');
    expect(text(const Key('sum_1')), '0');

    await tester.tap(find.byKey(const Key('statistics')));
    await tester.pumpAndSettle();

    expect(text(const Key('Stiche_1'), elementNo: 0), '0');
    expect(text(const Key('Stiche_2'), elementNo: 0), '0');
    expect(text(const Key('Sieg_1')), '');
    expect(text(const Key('Sieg_2')), '');

    expect(text(const Key('Stiche_1'), elementNo: 1), '2609');
    expect(text(const Key('Stiche_2'), elementNo: 1), '132');
    expect(text(const Key('Siege_1')), '1');
    expect(text(const Key('Siege_2')), '0');

    await tester.tap(find.text('Ok'));
  });

  testWidgets('delete everything', (tester) async {
    await tester.launchApp();

    await tester.addPoints(['add_0', 'key_Match'], factor: '7x');
    await tester.addPoints(['add_0', 'key_1', 'key_3', 'key_5'], factor: '6x');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    await tester.delete('Alles');

    expect(text(const Key('sum_0')), '0');
    expect(text(const Key('sum_1')), '0');

    await tester.tap(find.byKey(const Key('statistics')));
    await tester.pumpAndSettle();

    expect(text(const Key('Stiche_1'), elementNo: 0), '0');
    expect(text(const Key('Stiche_2'), elementNo: 0), '0');
    expect(text(const Key('Sieg_1')), '');
    expect(text(const Key('Sieg_2')), '');

    expect(text(const Key('Stiche_1'), elementNo: 1), '0');
    expect(text(const Key('Stiche_2'), elementNo: 1), '0');
    expect(text(const Key('Siege_1')), '0');
    expect(text(const Key('Siege_2')), '0');

    await tester.tap(find.text('Ok'));
  });
}
