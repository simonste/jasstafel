import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Starts the app over, the way the restart plugin does on a device, so that
/// MyApp reads the stored settings again.
///
/// The tree is torn down first: main() rebuilds the root with the same const
/// MyApp instance, which on its own would leave the element untouched.
Future<void> restartApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.launchApp();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const restartChannel = MethodChannel('restart');
  final restartCalls = <String>[];

  setUp(() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    await preferences.setString(CommonSettings.keys.appLanguage, 'de');

    // the settings screen restarts the app on a theme change; keep that from
    // tearing down the test and restart by hand instead
    restartCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(restartChannel, (call) async {
          restartCalls.add(call.method);
          return <String, dynamic>{'success': true, 'mode': 'platformDefault'};
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(restartChannel, null);
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
    expect(restartCalls, ['restartApp']);

    await restartApp(tester);

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
    await restartApp(tester);

    expect(appThemeMode(), ThemeMode.system);
    expect(boardTheme(tester).brightness, Brightness.light);
    expect(appBarColor(tester), Colors.blue);
  });
}
