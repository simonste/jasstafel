import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/schlaeger/data/schlaeger_score.dart';
import 'package:jasstafel/schlaeger/screens/schlaeger_settings_screen.dart';
import 'package:jasstafel/settings/schlaeger_settings.g.dart';

import '../helper/settings_screen.dart';

// cspell:ignore Zielpunkte anzahl feld leeres

void main() {
  Future<void> pump(WidgetTester tester, SchlaegerSettings settings) =>
      pumpSettingsScreen(
        tester,
        SchlaegerSettingsScreen(BoardData(settings, SchlaegerScore(), "")),
      );

  testWidgets('goal fields follow the goal type', (tester) async {
    for (final goal in GoalType.values) {
      await pump(tester, SchlaegerSettings()..goalType = goal.index);
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

  testWidgets('missingPlayer is only enabled below four players', (
    tester,
  ) async {
    await pump(tester, SchlaegerSettings()..players = 4);
    expect(rowPresent('Leeres Feld'), true, reason: 'disabled, not hidden');
    expect(rowEnabled('Leeres Feld'), false);

    await pump(tester, SchlaegerSettings()..players = 3);
    expect(rowEnabled('Leeres Feld'), true);
  });
}
