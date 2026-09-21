import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/point_board/data/point_board_score.dart';
import 'package:jasstafel/point_board/screens/point_board_settings_screen.dart';
import 'package:jasstafel/settings/point_board_settings.g.dart';

import '../helper/settings_screen.dart';

void main() {
  Future<void> pump(WidgetTester tester, PointBoardSettings settings) =>
      pumpSettingsScreen(
        tester,
        PointBoardSettingsScreen(BoardData(settings, PointBoardScore(), "")),
      );

  testWidgets('goal fields follow the goal type', (tester) async {
    for (final goal in GoalType.values) {
      await pump(tester, PointBoardSettings()..goalType = goal.index);
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

  testWidgets('positiveGoal is shown unless there is no goal', (tester) async {
    for (final goal in GoalType.values) {
      await pump(tester, PointBoardSettings()..goalType = goal.index);
      expect(
        rowPresent('Je mehr Punkte desto besser'),
        goal != GoalType.noGoal,
        reason: 'goalType $goal',
      );
    }
  });

  testWidgets('pointsPerRound follows its enable checkbox', (tester) async {
    await pump(tester, PointBoardSettings()..enablePointsPerRound = false);
    expect(
      rowPresent('Punkte pro Runde'),
      true,
      reason: 'disabled, not hidden',
    );
    expect(rowEnabled('Punkte pro Runde'), false);

    await pump(tester, PointBoardSettings()..enablePointsPerRound = true);
    expect(rowEnabled('Punkte pro Runde'), true);
  });
}
