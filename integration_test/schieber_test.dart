import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jasstafel/common/widgets/board_title.dart';
import 'package:jasstafel/main.dart' as app;
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    app.main();
    await tester.pumpAndSettle();

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
}
