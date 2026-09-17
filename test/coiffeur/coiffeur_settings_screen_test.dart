import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/coiffeur/data/coiffeur_score.dart';
import 'package:jasstafel/coiffeur/screens/coiffeur_settings_screen.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/settings/coiffeur_settings.g.dart';

import '../helper/settings_screen.dart';

// cspell:ignore Auswertungsspalte Prämie verwenden

void main() {
  Future<void> pump(WidgetTester tester, CoiffeurSettings settings) =>
      pumpSettingsScreen(
        tester,
        CoiffeurSettingsScreen(BoardData(settings, CoiffeurScore(), "")),
      );

  testWidgets('thirdColumn is disabled once a third team uses it', (
    tester,
  ) async {
    await pump(tester, CoiffeurSettings()..threeTeams = true);
    expect(
      rowPresent('Auswertungsspalte'),
      true,
      reason: 'disabled, not hidden',
    );
    expect(rowEnabled('Auswertungsspalte'), false);

    await pump(tester, CoiffeurSettings()..threeTeams = false);
    expect(rowEnabled('Auswertungsspalte'), true);
  });

  testWidgets('the bonus value is shown only with the bonus on', (
    tester,
  ) async {
    await pump(tester, CoiffeurSettings()..bonus = false);
    expect(rowPresent('Match-Prämie'), false);

    await pump(tester, CoiffeurSettings()..bonus = true);
    expect(rowPresent('Match-Prämie'), true);
  });

  testWidgets('toggling the bonus persists it', (tester) async {
    final settings = CoiffeurSettings()..bonus = false;
    final data = BoardData(settings, CoiffeurScore(), "");
    await pumpSettingsScreen(tester, CoiffeurSettingsScreen(data));

    await tester.tap(
      find.descendant(
        of: find.widgetWithText(CheckboxListTile, 'Match-Prämie verwenden'),
        matching: find.byType(Checkbox),
      ),
    );
    await tester.pumpAndSettle();

    expect(settings.bonus, true, reason: 'the toggle itself must be stored');
  });
}
