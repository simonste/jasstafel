import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jasstafel/common/widgets/board_title.dart';
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'overall_test.dart';

/// The theme the board is actually built with.
ThemeData boardTheme(WidgetTester tester) =>
    Theme.of(tester.firstElement(find.byType(TitleBar)));

/// The color the app bar is painted in, which differs per theme.
Color appBarColor(WidgetTester tester) {
  final material = tester.firstWidget<Material>(
    find.descendant(of: find.byType(TitleBar), matching: find.byType(Material)),
  );
  return material.color!;
}

ThemeMode? appThemeMode() {
  final materialApp =
      find.byType(MaterialApp).evaluate().single.widget as MaterialApp;
  return materialApp.themeMode;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    await preferences.setString(CommonSettings.keys.appLanguage, 'de');
  });

  testWidgets('switch to light mode', (tester) async {
    await tester.launchApp();

    expect(appThemeMode(), ThemeMode.dark);
    expect(boardTheme(tester).brightness, Brightness.dark);
    expect(appBarColor(tester), Colors.grey.shade900);

    await tester.openSettings();
    await tester.selectSetting('Design', 'Hell');
    await tester.closeSettings();

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getInt(CommonSettings.keys.themeMode),
      ThemeMode.light.index,
    );

    expect(appThemeMode(), ThemeMode.light);
    expect(boardTheme(tester).brightness, Brightness.light);
    expect(boardTheme(tester).scaffoldBackgroundColor, Colors.white);
    expect(appBarColor(tester), Colors.blue);
  });

  testWidgets('follow a light system theme', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.launchApp();

    await tester.openSettings();
    await tester.selectSetting('Design', 'System');
    await tester.closeSettings();

    expect(appThemeMode(), ThemeMode.system);
    expect(boardTheme(tester).brightness, Brightness.light);
    expect(appBarColor(tester), Colors.blue);
  });
}
