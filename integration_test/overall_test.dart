import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jasstafel/coiffeur/widgets/coiffeur_cell.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/widgets/board_title.dart';
import 'package:jasstafel/schieber/widgets/schieber_strokes.dart';
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jasstafel/main.dart' as app;

final actionsMenu = find.byKey(const Key('actionsMenu'));
final actionsMenuItems = find.byWidgetPredicate(
  (widget) => widget is PopupMenuItem,
);

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

    // Add timeout to prevent infinite waiting
    const maxWaitTime = Duration(seconds: 60);
    const checkInterval = Duration(milliseconds: 100);
    final startTime = DateTime.now();

    // Initial pump to start the app
    await pump();

    // Wait for TitleBar with shorter intervals and proper error handling
    while (find.byType(TitleBar).evaluate().isEmpty) {
      if (DateTime.now().difference(startTime) > maxWaitTime) {
        // Try to provide diagnostic info
        final allWidgets = find.byType(Widget).evaluate();
        throw TestFailure(
          'App failed to launch within $maxWaitTime. '
          'TitleBar widget was not found. '
          'Found ${allWidgets.length} widgets in tree.',
        );
      }
      await Future.delayed(checkInterval);
      await pump();
    }

    // Final settle to ensure UI is stable.
    await pumpAndSettle();
    await settleViewSize();
  }

  /// Boards ask for a preferred orientation while they build. On a device
  /// whose current orientation is not among them (a tablet in landscape
  /// showing a portrait only board) Android answers with a smaller window,
  /// and that resize only arrives a few frames later.
  Future<void> settleViewSize() async {
    const stableFor = Duration(milliseconds: 500);
    const maxWaitTime = Duration(seconds: 10);
    final startTime = DateTime.now();

    var size = view.physicalSize;
    var lastChange = DateTime.now();
    while (DateTime.now().difference(lastChange) < stableFor) {
      if (DateTime.now().difference(startTime) > maxWaitTime) {
        throw TestFailure('View size did not settle within $maxWaitTime.');
      }
      await pump(const Duration(milliseconds: 50));
      if (view.physicalSize != size) {
        size = view.physicalSize;
        lastChange = DateTime.now();
      }
    }
    await pumpAndSettle();
  }

  Future<void> waitKeyboardGone() async {
    const maxWaitTime = Duration(seconds: 10);
    final startTime = DateTime.now();

    await pump(const Duration(milliseconds: 100));
    while (view.viewInsets.bottom > 0) {
      if (DateTime.now().difference(startTime) > maxWaitTime) {
        throw TestFailure('The keyboard was still there after $maxWaitTime.');
      }
      await pump(const Duration(milliseconds: 50));
    }
    await pumpAndSettle();
  }

  Future<void> switchBoard({required String to}) async {
    final dropdown = find.byType(DropdownButton<Board>);
    // The button renders the selected item, so a single item means the menu
    // is closed. Tapping it can be lost to a resize (see settleViewSize), in
    // which case the menu never opens, hence the retries.
    final menuItems = find.byType(DropdownMenuItem<Board>);
    const maxAttempts = 10;
    var attempts = 0;
    while (menuItems.evaluate().length <= 1) {
      if (attempts++ == maxAttempts) {
        throw TestFailure('Board menu did not open after $maxAttempts taps.');
      }
      await tap(dropdown);
      await pumpAndSettle();
    }

    final finder = find.text(to);
    await scrollTo(finder);
    await tap(finder.last);
    await pumpAndSettle();
    await settleViewSize();
  }

  Future<void> delete(String buttonText) async {
    final settingFinder = find.byKey(const Key('delete'));
    if (!any(settingFinder)) {
      await tap(actionsMenu);
      await pumpAndSettle();
    }
    await tap(settingFinder);
    await pumpAndSettle();
    await tap(find.text(buttonText));
    await pumpAndSettle();
  }

  Future<void> scrollTo(Finder finder) async {
    if (!any(finder) || !any(finder.hitTestable())) {
      await scrollUntilVisible(
        finder,
        100.0,
        scrollable: find.byType(Scrollable).last,
      );
      await pumpAndSettle();
    }
  }

  Future<void> scrollUpTo(Finder finder) async {
    if (!any(finder) || !any(finder.hitTestable())) {
      await scrollUntilVisible(
        finder,
        -100.0,
        scrollable: find.byType(Scrollable),
      );
      await pumpAndSettle();
    }
  }

  Future<void> scroll(Offset offset) async {
    final scrollableFinder = find.byType(Scrollable).last;
    expect(scrollableFinder, findsWidgets);

    await drag(scrollableFinder, offset);
    await pumpAndSettle();
  }

  Future<void> tapInList(String text) async {
    await scrollTo(find.text(text));
    await tap(find.text(text));
    await pumpAndSettle();
  }

  Future<void> openSettings() async {
    final settingFinder = find.byKey(const Key('SettingsButton'));
    if (!any(settingFinder)) {
      await tap(actionsMenu);
      await pumpAndSettle();
    }
    await tap(settingFinder);
    await pumpAndSettle();
  }

  Future<void> closeSettings() async {
    await tap(find.byTooltip('Zurück'));
    await pumpAndSettle();
  }

  Future<void> tapSetting(List<String> settings) async {
    await openSettings();
    for (String setting in settings) {
      await tapInList(setting);
    }
    await closeSettings();
  }

  Future<void> selectSetting(String title, String value) async {
    await scrollTo(find.text(title));
    final row = find.ancestor(
      of: find.text(title),
      matching: find.byType(ListTile),
    );
    await tap(
      find.descendant(of: row, matching: find.byType(DropdownButton<int>)),
    );
    await pumpAndSettle();
    await tap(find.text(value).last);
    await pumpAndSettle();
  }

  Future<void> addCoiffeurPoints(
    String teamRow,
    int points, {
    String? tapKey,
  }) async {
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
    await waitKeyboardGone();
  }

  Future<void> addSchieberPoints(
    List<String> keys, {
    String? factor,
    bool? weis,
  }) async {
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
      matching: find.byType(SchieberStrokes),
    );

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
    await waitKeyboardGone();
  }

  Future<void> addRound(Map<String, int?> points) async {
    await tap(find.byTooltip('Runde eingeben'));
    await pumpAndSettle();
    for (var key in points.keys) {
      await scrollTo(find.byKey(Key(key)));
      if (points[key] != null) {
        await enterText(find.byKey(Key(key)), '${points[key]}');
      } else {
        await tap(find.byKey(Key(key)));
      }
      await pump();
    }
    await tap(find.text('Ok'));
    await pumpAndSettle();
    await waitKeyboardGone();
  }

  Future<void> addDifferenzlerGuessPoints(String playerName, int guess) async {
    await scrollTo(find.byTooltip('Ansage von $playerName'));
    await tap(find.byTooltip('Ansage von $playerName'));
    await pumpAndSettle();
    await enterText(find.byType(TextField), '$guess');
    await pump();
    await tap(find.text('Ok'));
    await pumpAndSettle();
    await waitKeyboardGone();
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
    String player,
    Map<String, int?> picker,
  ) async {
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
        await tap(
          find.descendant(
            of: find.byKey(Key(key)),
            matching: find.text("${points[key]}"),
          ),
        );
      }
      await pump();
    }
    await tap(find.text('Ok'));
    await pumpAndSettle();
  }

  Future<void> slideTo(String text, int value) async {
    await scrollTo(find.text(text));
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
    final overshoot = offsetFromCurrent.sign * 0.4 * distancePerIncrement;
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
