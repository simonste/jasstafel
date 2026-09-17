import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/common/widgets/pref_number.dart';
import 'package:jasstafel/common/widgets/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'testapp.dart';

/// Pumps a settings screen with its own empty SharedPreferences.
///
/// The viewport is made tall enough for the whole list to build, so that
/// find.text sees every row rather than only those above the fold.
Future<void> pumpSettingsScreen(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(1000, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    SettingsProvider(
      preferences: preferences,
      child: JasstafelTestApp(child: screen),
    ),
  );
  await tester.pumpAndSettle();
}

/// Whether a row is rendered at all, keyed by its visible title.
///
/// Rows whose condition hides them are absent; rows whose condition only
/// disables them stay present, so [rowEnabled] distinguishes the two.
bool rowPresent(String title) => find.text(title).evaluate().isNotEmpty;

/// Whether the control belonging to [title] accepts input.
///
/// Walks up from the title to whichever tile renders it and reports on that
/// tile's onChanged, which is null exactly when the row is disabled.
bool rowEnabled(String title) {
  final titleFinder = find.text(title);
  expect(
    titleFinder,
    findsOneWidget,
    reason: 'no row titled "$title" is rendered',
  );
  final element = titleFinder.evaluate().single;

  final checkbox = element.findAncestorWidgetOfExactType<CheckboxListTile>();
  if (checkbox != null) return checkbox.onChanged != null;

  final number = element.findAncestorWidgetOfExactType<PrefNumber>();
  if (number != null) return number.onChanged != null;

  final tile = element.findAncestorWidgetOfExactType<ListTile>();
  final trailing = tile?.trailing;
  if (trailing is DropdownButton) {
    // read dynamically: DropdownButton<int>.onChanged cannot be reached
    // through a DropdownButton<dynamic> reference
    return (trailing as dynamic).onChanged != null;
  }
  if (tile != null) return tile.enabled;

  // buildSliderTile renders the title as a sibling of the Slider
  final column = element.findAncestorWidgetOfExactType<Column>();
  if (column != null) {
    final slider = find.descendant(
      of: find.byWidget(column),
      matching: find.byType(Slider),
    );
    if (slider.evaluate().isNotEmpty) {
      return (slider.evaluate().single.widget as Slider).onChanged != null;
    }
  }

  fail('could not determine the enabled state of "$title"');
}

/// Whether the text field labelled [label] accepts input.
bool textFieldEnabled(String label) {
  final field = find.ancestor(
    of: find.text(label),
    matching: find.byType(TextFormField),
  );
  expect(field, findsOneWidget, reason: 'no text field labelled "$label"');
  return (field.evaluate().single.widget as TextFormField).enabled;
}
