import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/common/widgets/board_title.dart';
import 'package:jasstafel/common/widgets/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helper/testapp.dart';

/// An action that belongs in the menu.
class MenuButton extends IconButton {
  const MenuButton({super.key = const Key('menu')})
    : super(icon: const Icon(Icons.android), onPressed: _nothing);
  static void _nothing() {}
}

/// An action that stays in the bar.
class KeptButton extends IconButton {
  const KeptButton({super.key = const Key('kept')})
    : super(icon: const Icon(Icons.android), onPressed: _nothing);
  static void _nothing() {}
}

void main() {
  testWidgets('actions that do not fit move into the actionsMenu', (
    tester,
  ) async {
    tester.portrait();
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    var tapped = '';
    // shrinkActions mutates the list it is given, so build it per call
    List<Widget> actions() => [
      for (final name in ['one', 'two', 'three'])
        IconButton(
          key: Key(name),
          icon: const Icon(Icons.android),
          onPressed: () => tapped = name,
        ),
    ];

    await tester.pumpWidget(
      SettingsProvider(
        preferences: preferences,
        child: JasstafelTestApp(
          child: Builder(
            builder: (context) => Row(
              children: shrinkActions(
                actions: actions(),
                context: context,
                priority: const [],
              ),
            ),
          ),
        ),
      ),
    );

    // the menu is found by key rather than by type: its value type is inferred
    // from its items, so find.byType(PopupMenuButton) -- which means
    // PopupMenuButton<dynamic> -- does not match it
    expect(find.byKey(const Key('actionsMenu')), findsOneWidget);
    expect(find.byKey(const Key('one')), findsNothing);

    await tester.tap(find.byKey(const Key('actionsMenu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('one')));
    await tester.pumpAndSettle();

    expect(tapped, 'one');
  });

  /// Pumps [actions] into a bar [widthDp] wide with the given placement.
  Future<void> pump(
    WidgetTester tester, {
    required double widthDp,
    required List<Widget> Function() actions,
    List<Type> inMenu = const [],
    List<Type> keep = const [],
  }) async {
    tester.view.physicalSize = Size(widthDp * 4, 2560);
    tester.view.devicePixelRatio = 4;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      SettingsProvider(
        preferences: preferences,
        child: JasstafelTestApp(
          child: Builder(
            builder: (context) => Row(
              children: shrinkActions(
                actions: actions(),
                context: context,
                priority: const [],
                inMenu: inMenu,
                keep: keep,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> others(int count) => [
    for (var i = 0; i < count; i++)
      IconButton(
        key: Key('other$i'),
        icon: const Icon(Icons.android),
        onPressed: () {},
      ),
  ];

  // The title takes 145 dp, a button 48: 260 dp fit two buttons, 360 four.

  testWidgets('an action for the menu goes there with the overflow', (
    tester,
  ) async {
    await pump(
      tester,
      widthDp: 260,
      actions: () => [const MenuButton(), ...others(2)],
      inMenu: const [MenuButton],
    );

    expect(find.byKey(const Key('other1')), findsOneWidget);
    expect(find.byKey(const Key('menu')), findsNothing);
    expect(find.byKey(const Key('other0')), findsNothing);

    await tester.tap(find.byKey(const Key('actionsMenu')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('menu')), findsOneWidget);
    expect(find.byKey(const Key('other0')), findsOneWidget);
  });

  testWidgets('a lone menu entry takes the menu\'s slot instead', (
    tester,
  ) async {
    await pump(
      tester,
      widthDp: 360,
      actions: () => [const MenuButton(), ...others(1)],
      inMenu: const [MenuButton],
    );

    expect(find.byKey(const Key('menu')), findsOneWidget);
    expect(find.byKey(const Key('other0')), findsOneWidget);
    expect(find.byKey(const Key('actionsMenu')), findsNothing);
  });

  testWidgets('a menu entry keeps the tooltip of its button', (tester) async {
    await pump(
      tester,
      widthDp: 260,
      actions: () => [
        IconButton(
          key: const Key('labelled'),
          tooltip: 'Label',
          icon: const Icon(Icons.android),
          onPressed: () {},
        ),
        ...others(2),
      ],
    );

    await tester.tap(find.byKey(const Key('actionsMenu')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('labelled')), findsOneWidget);
    expect(find.byTooltip('Label'), findsOneWidget);
  });

  testWidgets('a kept action stays in the bar whatever the width', (
    tester,
  ) async {
    await pump(
      tester,
      widthDp: 260,
      actions: () => [const KeptButton(), ...others(2)],
      keep: const [KeptButton],
    );

    expect(find.byKey(const Key('kept')), findsOneWidget);
    expect(find.byKey(const Key('actionsMenu')), findsOneWidget);
    expect(find.byKey(const Key('other0')), findsNothing);
    expect(find.byKey(const Key('other1')), findsNothing);
  });
}
