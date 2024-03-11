import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jasstafel/coiffeur/widgets/coiffeur_cell.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/schieber/widgets/schieber_strokes.dart';
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jasstafel/main.dart' as app;

// cspell:ignore: zurück runde eingeben spielername ansage

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

String? cellText(Key key) {
  var coiffeurCellWidget =
      find.byKey(key).evaluate().single.widget as CoiffeurCell;
  return coiffeurCellWidget.text;
}

extension AppHelper on WidgetTester {
  Future<void> launchApp() async {
    app.main();
    // pump three times to assure android app is launched
    await pumpAndSettle();
    await pumpAndSettle();
    await pumpAndSettle();
  }

  Future<void> switchBoard({required String to}) async {
    await tap(find.byType(DropdownButton<Board>));
    await pumpAndSettle();
    await tap(find.text(to).last);
    await pumpAndSettle();
  }

  Future<void> delete(String buttonText) async {
    final settingFinder = find.byKey(const Key('delete'));
    if (!any(settingFinder)) {
      await tap(find.byType(PopupMenuButton));
      await pumpAndSettle();
    }
    await tap(settingFinder);
    await pumpAndSettle();
    await tap(find.text(buttonText));
    await pumpAndSettle();
  }

  Future<void> scrollTo(String text) async {
    final settingFinder = find.text(text);
    if (!any(settingFinder) || !any(settingFinder.hitTestable())) {
      await scrollUntilVisible(
        settingFinder,
        100.0,
        scrollable: find.byType(Scrollable),
      );
      await pumpAndSettle();
    }
  }

  Future<void> scrollUpTo(String text) async {
    final settingFinder = find.text(text);
    if (!any(settingFinder)) {
      await scrollUntilVisible(
        settingFinder,
        -100.0,
        scrollable: find.byType(Scrollable),
      );
      await pumpAndSettle();
    }
  }

  Future<void> tapInList(String text) async {
    await scrollTo(text);
    await tap(find.text(text));
    await pumpAndSettle();
  }

  Future<void> tapSetting(List<String> settings) async {
    final settingFinder = find.byKey(const Key('SettingsButton'));
    if (!any(settingFinder)) {
      await tap(find.byType(PopupMenuButton));
      await pumpAndSettle();
    }
    await tap(settingFinder);
    await pumpAndSettle();
    for (String setting in settings) {
      await tapInList(setting);
    }
    await tap(find.byTooltip('Zurück'));
    await pumpAndSettle();
  }

  Future<void> addCoiffeurPoints(String teamRow, int points,
      {String? tapKey}) async {
    await tap(find.byKey(Key(teamRow)));
    await pumpAndSettle();
    await enterText(find.byType(TextField), '$points');
    await pump();
    if (tapKey != null) {
      await tap(find.byKey(Key(tapKey)));
    }
    if (tapKey != 'scratch') {
      await tap(find.text('Ok'));
    }
    await pumpAndSettle();
  }

  Future<void> addSchieberPoints(List<String> keys,
      {String? factor, bool? weis}) async {
    for (final key in keys) {
      await tap(find.byKey(Key(key)));
      await pumpAndSettle();
    }
    if (factor != null) {
      await tap(find.text(factor).last);
      await pumpAndSettle();
    }
    await tap(find.text((weis ?? false) ? 'Weis' : 'Ok'));
    await pumpAndSettle();
  }

  Future<int> backsideStrokes(int player, int num) async {
    for (var i = 0; i < num; i++) {
      await tap(find.byKey(Key('add$player:$player')));
    }
    await pumpAndSettle();

    var strokeWidgets = find.descendant(
        of: find.byKey(Key('column$player')),
        matching: find.byType(SchieberStrokes));

    var totalStrokes = 0;
    for (var element in strokeWidgets.evaluate()) {
      totalStrokes += (element.widget as SchieberStrokes).strokes;
    }
    return totalStrokes;
  }

  Future<void> rename(String from, String to) async {
    await tap(find.text(from));
    await pumpAndSettle();
    expect(find.text('Spielername'), findsWidgets);
    await enterText(find.byType(TextField), to);
    await pump();
    await tap(find.text('Ok'));
    await pumpAndSettle();
  }

  Future<void> addRound(Map<String, int?> points) async {
    await tap(find.byTooltip('Runde eingeben'));
    await pump();
    for (var key in points.keys) {
      if (points[key] != null) {
        await enterText(find.byKey(Key(key)), '${points[key]}');
      } else {
        await tap(find.byKey(Key(key)));
      }
      await pump();
    }
    await tap(find.text('Ok'));
    await pumpAndSettle();
  }

  Future<void> addDifferenzlerGuessPoints(String playerName, int guess) async {
    await tap(find.byTooltip('Ansage von $playerName'));
    await pump();
    await enterText(find.byType(TextField), '$guess');
    await pump();
    await tap(find.text('Ok'));
    await pumpAndSettle();
  }

  Future<void> scrollNumberPicker(String key, int value) async {
    final picker =
        find.byKey(Key(key)).evaluate().single.widget as NumberPicker;
    final center = getCenter(find.byKey(Key(key)));
    final offsetY = (picker.value - value) * picker.itemHeight;
    final TestGesture testGesture = await startGesture(center);
    await testGesture.moveBy(Offset(0.0, offsetY));
    await pump();
  }

  Future<void> addGuggitalerPoints(
      String player, Map<String, int?> picker) async {
    await tap(find.byTooltip('Runde eingeben'));
    await pump();
    await tap(find.text(player).last);
    for (var key in picker.keys) {
      if (picker[key] != null) {
        await scrollNumberPicker(key, picker[key]!);
      }
    }
    await tap(find.text('Ok'));
    await pumpAndSettle();
  }

  Future<void> addSchlaegerRound(Map<String, int?> points) async {
    await tap(find.byTooltip('Runde eingeben'));
    await pump();
    for (var key in points.keys) {
      if (points[key] != null) {
        await tap(find.descendant(
          of: find.byKey(Key(key)),
          matching: find.text("${points[key]}"),
        ));
      }
      await pump();
    }
    await tap(find.text('Ok'));
    await pumpAndSettle();
  }

  Future<void> slideTo(String text, int value) async {
    await scrollTo(text);
    final slider = find.byType(Slider);
    final prefSlider = slider.evaluate().single.widget as Slider;
    const sliderPadding = 24;
    final totalWidth = getSize(slider).width - 2 * sliderPadding;
    final range = prefSlider.max - prefSlider.min;
    final distancePerIncrement = (totalWidth / range);
    final ticksFromCenter = prefSlider.value - prefSlider.min - (range / 2);
    final currentOffsetFromCenter = ticksFromCenter * distancePerIncrement;
    final sliderPos = getCenter(slider) + Offset(currentOffsetFromCenter, 0);
    final slideTicks = value - prefSlider.value;
    final offsetFromCurrent = slideTicks * distancePerIncrement;
    // overshoot seems to be necessary
    final overshoot = offsetFromCurrent.sign * 0.1 * distancePerIncrement;
    await dragFrom(sliderPos, Offset(offsetFromCurrent + overshoot, 0));
    await pumpAndSettle();
    expect((slider.evaluate().single.widget as Slider).value, value);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    await preferences.setString(CommonSettings.keys.appLanguage, 'de');
  });

  testWidgets('switch board', (tester) async {
    await tester.launchApp();

    await tester.tap(find.byKey(const Key('add100_0')));
    await tester.tap(find.byKey(const Key('add50_1')));

    await tester.switchBoard(to: 'Coiffeur');

    await tester.addCoiffeurPoints('0:2', 77);
    await tester.pumpAndSettle();

    await tester.switchBoard(to: 'Schieber');

    expect(text(const Key('sum_0')), '100');
    expect(text(const Key('sum_1')), '50');

    await tester.switchBoard(to: 'Coiffeur');

    expect(cellText(const Key('sum_0')), '${3 * 77}');
    expect(cellText(const Key('sum_1')), '0');
  });
}
