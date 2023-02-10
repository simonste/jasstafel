import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/main.dart' as app;
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

String? text(Key key) {
  var textWidget = find.byKey(key).evaluate().single.widget as Text;
  return textWidget.data;
}

extension SchieberHelper on WidgetTester {
  Future<void> launchApp() async {
    app.main();
    // pump three times to assure android app is launched
    await pumpAndSettle();
    await pumpAndSettle();
    await pumpAndSettle();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    await preferences.setString(CommonSettings.keys.appLanguage, "de");
    await preferences.setInt(
        CommonSettings.keys.lastBoard, Board.schieber.index);
  });

  testWidgets('change team name', (tester) async {
    await tester.launchApp();

    expect(find.text('Team 1'), findsOneWidget);

    await tester.tap(find.text('Team 1'));
    await tester.pumpAndSettle();

    // cspell:disable-next
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

    // cspell:disable-next
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

    await tester.tap(find.byKey(const Key("SettingsButton")));
    await tester.pumpAndSettle();
    // cspell:disable-next
    await tester.tap(find.text("verschiedene Zielpunkte"));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip("Zurück")); // cspell:disable-line
    await tester.pumpAndSettle();

    expect(find.text('2500'), findsNWidgets(2));

    var gp0 = find.byKey(const Key("GoalPoints0"));
    var gp1 = find.byKey(const Key("GoalPoints1"));
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

    await tester.tap(find.byKey(const Key("add20_1")));
    await tester.tap(find.byKey(const Key("add20_1")));
    await tester.tap(find.byKey(const Key("add100_1")));
    await tester.tap(find.byKey(const Key("subtract1_1")));
    await tester.pump();
    expect(text(const Key("sum_0")), "0");
    expect(text(const Key("sum_1")), "139");

    await tester.tap(find.byKey(const Key("add100_0")));
    await tester.tap(find.byKey(const Key("add50_0")));
    await tester.tap(find.byKey(const Key("add1_0")));
    await tester.pump();
    expect(text(const Key("sum_0")), "151");
    expect(text(const Key("sum_1")), "139");
  });

  testWidgets('add round', (tester) async {
    await tester.launchApp();

    await tester.tap(find.byKey(const Key("add_1")));
    await tester.pumpAndSettle();
    await tester.tap(find.text("2"));
    await tester.tap(find.text("3"));
    await tester.tap(find.byKey(const Key('dropdownFactor')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4x').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text("Ok"));
    await tester.pumpAndSettle();
    expect(text(const Key("sum_0")), "536");
    expect(text(const Key("sum_1")), "92");
  });

  testWidgets('add match', (tester) async {
    await tester.launchApp();

    await tester.tap(find.byKey(const Key("add_0")));
    await tester.pumpAndSettle();
    await tester.tap(find.text("2"));
    await tester.tap(find.text("Match"));
    await tester.tap(find.text("Ok"));
    await tester.pumpAndSettle();
    expect(text(const Key("sum_0")), "257");
    expect(text(const Key("sum_1")), "0");
  });

  testWidgets('add weis', (tester) async {
    await tester.launchApp();

    await tester.tap(find.byKey(const Key("add_0")));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dropdownFactor')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3x').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text("2"));
    await tester.tap(find.text("∅")); // reset
    await tester.tap(find.text("5"));
    await tester.tap(find.text("1"));
    await tester.tap(find.text("←")); // delete 1
    await tester.tap(find.byKey(const Key("key_0")));
    await tester.tap(find.text("Weis"));
    await tester.pumpAndSettle();
    expect(text(const Key("sum_0")), "150");
    expect(text(const Key("sum_1")), "0");
  });

  testWidgets('profile', (tester) async {
    await tester.launchApp();

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Standard'));
    await tester.pumpAndSettle();

    // cspell:disable-next
    await tester.tap(find.byTooltip('Profil kopieren'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '2nd Profile');
    await tester.pump();
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2nd Profile'));
    await tester.pump();

    await tester.tap(find.byTooltip("Zurück")); // cspell:disable-line
    await tester.pumpAndSettle();
    // cspell:disable-next
    await tester.tap(find.text("Hilfslinien (Z) anzeigen"));
    // cspell:disable-next
    await tester.tap(find.text("verschiedene Zielpunkte"));
    await tester.tap(find.byTooltip("Zurück")); // cspell:disable-line
    await tester.pumpAndSettle();

    expect(find.text('2500'), findsNWidgets(2));

    await tester.tap(find.byKey(const Key("add20_0")));
    await tester.tap(find.byKey(const Key("add50_1")));
    await tester.tap(find.byKey(const Key("add50_1")));
    await tester.pump();
    expect(text(const Key("sum_0")), "20");
    expect(text(const Key("sum_1")), "100");

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2nd Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Standard'));
    await tester.pump();
    await tester.tap(find.byTooltip("Zurück")); // cspell:disable-line
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip("Zurück")); // cspell:disable-line
    await tester.pumpAndSettle();

    expect(find.text('2500'), findsNWidgets(1));
    expect(text(const Key("sum_0")), "0");
    expect(text(const Key("sum_1")), "0");
  });
}
