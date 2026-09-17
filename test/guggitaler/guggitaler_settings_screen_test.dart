import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/guggitaler/data/guggitaler_score.dart';
import 'package:jasstafel/guggitaler/screens/guggitaler_settings_screen.dart';
import 'package:jasstafel/settings/guggitaler_settings.g.dart';

import '../helper/settings_screen.dart';

// cspell:ignore Dominopunkte Spieler

void main() {
  Future<void> pump(WidgetTester tester, GuggitalerSettings settings) =>
      pumpSettingsScreen(
        tester,
        GuggitalerSettingsScreen(BoardData(settings, GuggitalerScore(), "")),
      );

  testWidgets('domino point fields follow the domino checkbox', (tester) async {
    await pump(tester, GuggitalerSettings()..domino = false);
    expect(
      textFieldEnabled('Dominopunkte 3 Spieler'),
      false,
      reason: 'disabled, not hidden',
    );
    expect(textFieldEnabled('Dominopunkte 4 Spieler'), false);

    await pump(tester, GuggitalerSettings()..domino = true);
    expect(textFieldEnabled('Dominopunkte 3 Spieler'), true);
    expect(textFieldEnabled('Dominopunkte 4 Spieler'), true);
  });
}
