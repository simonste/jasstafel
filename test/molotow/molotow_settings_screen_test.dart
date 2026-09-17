import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/molotow/data/molotow_score.dart';
import 'package:jasstafel/molotow/screens/molotow_settings_screen.dart';
import 'package:jasstafel/settings/molotow_settings.g.dart';

import '../helper/settings_screen.dart';

// cspell:ignore Zielpunkte anzahl

void main() {
  Future<void> pump(WidgetTester tester, MolotowSettings settings) =>
      pumpSettingsScreen(
        tester,
        MolotowSettingsScreen(BoardData(settings, MolotowScore(), "")),
      );

  testWidgets('goal fields follow the goal type', (tester) async {
    for (final goal in GoalType.values) {
      await pump(tester, MolotowSettings()..goalType = goal.index);
      expect(
        rowPresent('Zielpunkte'),
        goal == GoalType.points,
        reason: 'goalType $goal',
      );
      expect(
        rowPresent('Anzahl Runden'),
        goal == GoalType.rounds,
        reason: 'goalType $goal',
      );
    }
  });
}
