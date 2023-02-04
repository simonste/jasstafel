import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jasstafel/coiffeur/widgets/coiffeur_cell.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/main.dart' as app;
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

// cspell:ignore: zurück zählt fach auswertungsspalte eigene multiplikatoren
// cspell:ignore: punkte verwenden prämie ändern abbrechen

String? text(Key key) {
  var coiffeurCellWidget =
      find.byKey(key).evaluate().single.widget as CoiffeurCell;
  Container container;
  if (coiffeurCellWidget.child is InkWell) {
    container = (coiffeurCellWidget.child as InkWell).child as Container;
  } else {
    container = coiffeurCellWidget.child as Container;
  }
  if (container.child is AutoSizeText) {
    return (container.child as AutoSizeText).data;
  }
  return (container.child as Text).data;
}

extension CoiffeurHelper on WidgetTester {
  Future<void> addPoints(String teamRow, int points, {String? tapKey}) async {
    await tap(find.byKey(Key(teamRow)));
    await pumpAndSettle();
    await enterText(find.byType(TextField), '$points');
    await pump();
    if (tapKey != null) {
      await tap(find.byKey(Key(tapKey)));
    }
    await tap(find.text('Ok'));
    await pumpAndSettle();
  }

  Future<void> slideTo(Finder slider, int value) async {
    final prefSlider = slider.evaluate().single.widget as Slider;
    final totalWidth = getSize(slider).width;
    final range = prefSlider.max - prefSlider.min;
    final calculatedOffset = (value - prefSlider.value) * (totalWidth / range);
    await dragFrom(getCenter(slider), Offset(calculatedOffset, 0));
  }
}

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
    app.main();
    await tester.pumpAndSettle();

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
    app.main();
    await tester.pumpAndSettle();

    await tester.addPoints('1:2', 56);
    await tester.addPoints('0:5', 50, tapKey: '157-x');

    expect(text(const Key('sum_0')), '${6 * 107}');
    expect(text(const Key('sum_1')), '${3 * 56}');
    expect(find.byKey(const Key('2:3')), findsNothing);
  });

  testWidgets('third column', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auswertungsspalte'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    expect(find.text('0'), findsNWidgets(3));

    await tester.addPoints('1:3', 90);
    await tester.addPoints('0:8', 80, tapKey: '157-x');
    await tester.addPoints('0:3', 77);

    expect(text(const Key('sum_0')), '${9 * 77 + 4 * 77}');
    expect(text(const Key('sum_1')), '${4 * 90}');
    expect(text(const Key('sum_2')), '${4 * -13}');
  });

  testWidgets('3 teams', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3 Teams'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

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

    await tester.addPoints('0:2', 51);
    await tester.addPoints('1:6', 66);
    await tester.addPoints('2:8', 77);

    expect(text(const Key('sum_0')), '${3 * 51}');
    expect(text(const Key('sum_1')), '${7 * 66}');
    expect(text(const Key('sum_2')), '${9 * 77}');
  });

  testWidgets('rounded points', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Punkte auf 10er Runden'));
    await tester.tap(find.text('Auswertungsspalte'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    await tester.addPoints('1:3', 60);
    await tester.addPoints('0:8', 80, tapKey: '157-x');
    await tester.addPoints('0:3', 77);

    expect(text(const Key('1:3')), '6');
    expect(text(const Key('0:8')), '8');
    expect(text(const Key('0:3')), '8');
    expect(text(const Key('sum_0')), '${9 * 8 + 4 * 8}');
    expect(text(const Key('sum_1')), '${4 * 6}');
    expect(text(const Key('sum_2')), '${4 * 2}');
  });

  testWidgets('change no of rounds', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.slideTo(find.byType(Slider), 6);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('1:3')), findsOneWidget);
    expect(find.byKey(const Key('2:3')), findsNothing);
    expect(find.byKey(const Key('1:6')), findsNothing);
  });

  testWidgets('custom factors', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.addPoints('1:7', 97);
    expect(text(const Key('sum_1')), '${8 * 97}');

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eigene Multiplikatoren verwenden'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Gusti'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('dropdownFactor')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(text(const Key('1:7')), '97');
    expect(text(const Key('sum_1')), '${10 * 97}');
  });

  testWidgets('match bonus', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Match-Punkte'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '157');
    await tester.tap(find.text('Ok'));
    await tester.pump();
    await tester.tap(find.text('Match-Prämie verwenden'));
    await tester.tap(find.text('Auswertungsspalte'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    await tester.addPoints('1:3', 56);
    await tester.addPoints('0:3', 0, tapKey: 'match');
    await tester.pumpAndSettle();

    expect(text(const Key('0:3')), 'MATCH');
    expect(text(const Key('sum_0')), '${4 * 157 + 500}');
    expect(text(const Key('sum_2')), '${4 * 101 + 500}');

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Punkte auf 10er Runden'));
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    expect(text(const Key('0:3')), 'MATCH');
    expect(text(const Key('sum_0')), '${4 * 16 + 50}');
    expect(text(const Key('sum_2')), '${4 * 10 + 50}');
  });

  testWidgets('toggle bonus', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.addPoints('0:5', 157);
    await tester.addPoints('1:6', 0, tapKey: "match");

    expect(text(const Key('0:5')), '157');
    expect(text(const Key('1:6')), '257');

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Match-Prämie verwenden'));
    await tester.pumpAndSettle();
    expect(find.text('Match-Punkte auf 157 ändern?'), findsOneWidget);
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    expect(text(const Key('0:5')), '157');
    expect(text(const Key('1:6')), 'MATCH');

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Match-Prämie verwenden'));
    await tester.pump();
    expect(find.text('Match-Punkte auf 257 ändern?'), findsOneWidget);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    expect(text(const Key('0:5')), '157');
    expect(text(const Key('1:6')), '157');

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Match-Prämie verwenden'));
    await tester.pump();
    expect(find.text('Match-Punkte auf 257 ändern?'), findsNothing);
    await tester.tap(find.text('Match-Prämie verwenden'));
    await tester.pump();
    expect(find.text('Match-Punkte auf 257 ändern?'), findsOneWidget);
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    expect(text(const Key('0:5')), '157');
    expect(text(const Key('1:6')), '257');
  });

  testWidgets('match bonus change', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.addPoints('0:7', 88);
    await tester.addPoints('1:7', 0, tapKey: 'match');
    await tester.pumpAndSettle();
    expect(text(const Key('sum_0')), '${8 * 88}');
    expect(text(const Key('sum_1')), '${8 * 257}');

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Match-Punkte'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '157');
    await tester.tap(find.text('Ok'));
    await tester.pump();
    await tester.tap(find.text('Match-Prämie verwenden'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    expect(text(const Key('1:7')), 'MATCH');
    expect(text(const Key('sum_0')), '${8 * 88}');
    expect(text(const Key('sum_1')), '${8 * 157 + 500}');

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Match-Prämie verwenden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Match-Punkte'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '207');
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    expect(text(const Key('1:7')), '207');
    expect(text(const Key('sum_0')), '${8 * 88}');
    expect(text(const Key('sum_1')), '${8 * 207}');
  });

  testWidgets('ignore hidden cells', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3 Teams'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    await tester.addPoints('0:10', 51);
    await tester.addPoints('1:6', 66);
    await tester.addPoints('2:8', 77);
    expect(text(const Key('sum_0')), '${11 * 51}');
    expect(text(const Key('sum_1')), '${7 * 66}');
    expect(text(const Key('sum_2')), '${9 * 77}');

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3 Teams'));
    await tester.pump();
    await tester.tap(find.text('Auswertungsspalte'));
    await tester.slideTo(find.byType(Slider), 10);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    expect(text(const Key('sum_0')), '0');
    expect(text(const Key('sum_1')), '${7 * 66}');
    expect(text(const Key('sum_2')), '0');
  });

  testWidgets('coiffeur info', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.addPoints('0:8', 140);
    await tester.addPoints('1:6', 0, tapKey: "match");

    await tester.tap(find.byKey(const Key('InfoButton')));
    await tester.pumpAndSettle();
    expect(find.text('Team 1'), findsNWidgets(2));
    expect(find.text('Team 2'), findsNWidgets(2));
    expect(find.text('Team 3'), findsNothing);
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('SettingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3 Teams'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('InfoButton')));
    await tester.pumpAndSettle();
    expect(find.text('Team 1'), findsNWidgets(2));
    expect(find.text('Team 2'), findsNWidgets(2));
    expect(find.text('Team 3'), findsNWidgets(2));
  });
}
