import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/common/widgets/board_title.dart';
import 'package:jasstafel/common/widgets/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helper/testapp.dart';

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
}
