import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/schieber/data/schieber_score.dart';
import 'package:jasstafel/schieber/screens/schieber_settings_screen.dart';
import 'package:jasstafel/settings/schieber_settings.g.dart';

import '../helper/settings_screen.dart';

void main() {
  Future<void> pump(WidgetTester tester, SchieberSettings settings) =>
      pumpSettingsScreen(
        tester,
        SchieberSettingsScreen(BoardData(settings, SchieberScore(), "")),
      );

  testWidgets('differentGoals is only enabled for a points goal', (
    tester,
  ) async {
    for (final goal in GoalType.values) {
      await pump(tester, SchieberSettings()..goalType = goal.index);
      expect(
        rowEnabled('verschiedene Zielpunkte'),
        goal == GoalType.points,
        reason: 'goalType $goal',
      );
    }
  });

  testWidgets('backsideColumns follows the backside checkbox', (tester) async {
    await pump(tester, SchieberSettings()..backside = false);
    expect(rowEnabled('Spalten auf der Rückseite'), false);

    await pump(tester, SchieberSettings()..backside = true);
    expect(rowEnabled('Spalten auf der Rückseite'), true);
  });

  testWidgets('vibrate follows the touchscreen checkbox', (tester) async {
    final settings = SchieberSettings();
    final data = BoardData(settings, SchieberScore(), "");
    data.supportsVibration = true;

    settings.touchScreen = false;
    await pumpSettingsScreen(tester, SchieberSettingsScreen(data));
    expect(rowEnabled('Vibration bei Punkteingabe'), false);

    settings.touchScreen = true;
    await pumpSettingsScreen(tester, SchieberSettingsScreen(data));
    expect(rowEnabled('Vibration bei Punkteingabe'), true);
  });

  testWidgets('disabled rows stay visible', (tester) async {
    await pump(tester, SchieberSettings()..backside = false);
    expect(rowPresent('Spalten auf der Rückseite'), true);
  });

  testWidgets('editing match points persists the entered value', (
    tester,
  ) async {
    // 1000 rounds to the same points-per-round the board already has, so the
    // "reset the other field?" confirmation never appears -- the path where
    // the entered value used to be dropped.
    final settings = SchieberSettings()..match = 1000;
    final data = BoardData(settings, SchieberScore(), "");
    await pumpSettingsScreen(tester, SchieberSettingsScreen(data));

    await tester.tap(find.widgetWithText(ListTile, 'Match-Punkte'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '2000');
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(settings.match, 2000);
  });
}
