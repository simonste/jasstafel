import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/widgets/settings_provider.dart';
import 'package:jasstafel/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Answers the calls [WakelockPlus] makes while the app builds.
void stubWakelock() {
  const codec = StandardMessageCodec();
  const api =
      'dev.flutter.pigeon.wakelock_plus_platform_interface'
      '.WakelockPlusApi';
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final reply in {'toggle': null, 'isEnabled': false}.entries) {
    messenger.setMockMessageHandler(
      '$api.${reply.key}',
      (message) async => codec.encodeMessage(<Object?>[reply.value]),
    );
  }
}

extension AppSize on WidgetTester {
  /// Gives the app a screen of [size] logical pixels.
  void setScreenSize(Size size) {
    view.physicalSize = size;
    view.devicePixelRatio = 1.0;
    addTearDown(view.reset);
  }

  /// The screen as the board on top sees it.
  Size boardSize() {
    final scaffold = find.byType(Scaffold).first;
    return MediaQuery.of(element(scaffold)).size;
  }

  Future<void> pumpApp(Map<String, Object> settings) async {
    SharedPreferences.setMockInitialValues(settings);
    final preferences = await SharedPreferences.getInstance();
    await pumpWidget(
      SettingsProvider(preferences: preferences, child: const MyApp()),
    );
    await pumpAndSettle();
  }
}

void main() {
  setUp(stubWakelock);

  testWidgets('a dialog opens although the keyboard insets are negative', (
    tester,
  ) async {
    // what iOS reports while the keyboard animates
    tester.view.viewInsets = const FakeViewPadding(bottom: -120);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: clampViewInsets(MediaQuery.of(context)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) =>
                  const AlertDialog(content: Text('Spielername')),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Spielername'), findsOneWidget);
  });

  testWidgets('the schieber board turns on a screen held in landscape', (
    tester,
  ) async {
    tester.setScreenSize(const Size(1280, 800));

    await tester.pumpApp({});

    expect(tester.boardSize(), const Size(800, 1280));
  });

  testWidgets('the app turns when the screen is turned while it runs', (
    tester,
  ) async {
    tester.setScreenSize(const Size(800, 1280));

    await tester.pumpApp({});
    expect(tester.boardSize(), const Size(800, 1280));

    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpAndSettle();

    expect(tester.boardSize(), const Size(800, 1280));
  });

  testWidgets('a board follows the screen it fits on', (tester) async {
    tester.setScreenSize(const Size(1280, 800));

    await tester.pumpApp({'flutter.lastBoard': Board.coiffeur.index});

    expect(tester.boardSize(), const Size(1280, 800));
  });

  testWidgets('a phone held in landscape turns like any other screen', (
    tester,
  ) async {
    tester.setScreenSize(const Size(914, 411));

    await tester.pumpApp({});

    expect(tester.boardSize(), const Size(411, 914));
  });

  testWidgets('a screen already held as the board wants it stays put', (
    tester,
  ) async {
    tester.setScreenSize(const Size(411, 914));

    await tester.pumpApp({});

    expect(tester.boardSize(), const Size(411, 914));
  });

  testWidgets('the landscape setting turns a board', (tester) async {
    tester.setScreenSize(const Size(800, 1280));

    await tester.pumpApp({
      'flutter.lastBoard': Board.coiffeur.index,
      'flutter.orientation': 2,
    });

    expect(tester.boardSize(), const Size(1280, 800));
  });

  // The app is turned clockwise, so its top is painted along the right of the
  // screen and the keyboard, which covers the bottom of the screen, covers the
  // right of the app.
  test('a quarter turn moves every edge one step', () {
    const data = MediaQueryData(
      size: Size(1280, 800),
      padding: EdgeInsets.only(top: 24),
      viewInsets: EdgeInsets.only(bottom: 300),
    );

    final turned = quarterTurn(data);

    expect(turned.size, const Size(800, 1280));
    expect(turned.padding, const EdgeInsets.only(left: 24));
    expect(turned.viewInsets, const EdgeInsets.only(right: 300));
  });
}
