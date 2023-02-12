import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jasstafel/main.dart' as app;

import 'coiffeur_test.dart';

// cspell:ignore:

extension AppHelper on WidgetTester {
  Future<void> launchApp() async {
    app.main();
    // pump three times to assure android app is launched
    await pumpAndSettle();
    await pumpAndSettle();
    await pumpAndSettle();
  }

  Future<void> switchBoard({required String from, required String to}) async {
    await tap(find.text(from).last);
    await pumpAndSettle();
    await tap(find.text(to).last);
    await pumpAndSettle();
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

    await tester.switchBoard(from: 'Schieber', to: 'Coiffeur');

    await tester.addPoints('0:2', 77);
    await tester.pumpAndSettle();

    await tester.switchBoard(from: 'Coiffeur', to: 'Schieber');

    schieberText(Key key) {
      return (find.byKey(key).evaluate().single.widget as Text).data;
    }

    expect(schieberText(const Key('sum_0')), '100');
    expect(schieberText(const Key('sum_1')), '50');

    await tester.switchBoard(from: 'Schieber', to: 'Coiffeur');

    expect(text(const Key('sum_0')), '${3 * 77}');
    expect(text(const Key('sum_1')), '0');
  });
}
