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
        CommonSettings.keys.lastBoard, Board.coiffeur.index);
  });
  testWidgets('first test', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('Schellen'), findsOneWidget);

    await tester.longPress(find.text('Eicheln'));
    await tester.pump();

    // cspell:disable-next
    expect(find.text('Welcher Jass zählt 1fach?'), findsWidgets);

    await tester.tap(find.text('Schaufel'));
    await tester.pump();

    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(find.text('Eicheln'), findsNothing);
    expect(find.text('Schaufel'), findsOneWidget);
  });
}
