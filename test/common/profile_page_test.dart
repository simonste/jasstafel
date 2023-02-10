import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/widgets/profile_page.dart';
import 'package:jasstafel/schieber/data/schieber_score.dart';
import 'package:jasstafel/settings/schieber_settings.g.dart';

import '../helper/testapp.dart';

// cspell:ignore: profil kopieren löschen

bool radioSelected(Key key) {
  var radioFinder = find.byKey(key);
  expect(radioFinder, findsOneWidget);
  var radio = radioFinder.evaluate().single.widget as Radio<String>;
  return (radio.value == radio.groupValue);
}

void main() {
  testWidgets('copy profile', (WidgetTester tester) async {
    var data = BoardData(SchieberSettings(), SchieberScore(), "");

    final widget = makeTestableExpanded(ProfilePage(data, () {}));
    await tester.pumpWidget(widget);

    expect(find.text('Standard'), findsOneWidget);
    expect(data.profiles.list.length, 1);
    await tester.tap(find.byTooltip('Profil kopieren'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), "Profile 2");
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(data.profiles.list.length, 2);
    expect(find.text('Profile 2'), findsOneWidget);
    expect(radioSelected(const Key("Standard_Radio")), true);
    expect(radioSelected(const Key("Profile 2_Radio")), false);
  });

  testWidgets('rename active profile', (WidgetTester tester) async {
    var data = BoardData(SchieberSettings(), SchieberScore(), "");

    final widget = makeTestableExpanded(ProfilePage(data, () {}));
    await tester.pumpWidget(widget);

    expect(find.text('Standard'), findsOneWidget);
    await tester.longPress(find.text('Standard'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), "Standard 2");
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(find.text('Standard'), findsNothing);
    expect(find.text('Standard 2'), findsOneWidget);
    expect(data.profiles.active, "Standard 2");
    expect(radioSelected(const Key("Standard 2_Radio")), true);
  });

  testWidgets('rename other profile', (WidgetTester tester) async {
    var data = BoardData(SchieberSettings(), SchieberScore(), "");
    data.profiles.list.add("Foo:Bar");

    final widget = makeTestableExpanded(ProfilePage(data, () {}));
    await tester.pumpWidget(widget);

    expect(find.text('Foo'), findsOneWidget);
    await tester.longPress(find.text('Foo'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), "Foo 2");
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(find.text('Foo'), findsNothing);
    expect(find.text('Foo 2'), findsOneWidget);
    expect(data.profiles.active, "Standard");
    expect(radioSelected(const Key("Standard_Radio")), true);
    expect(radioSelected(const Key("Foo 2_Radio")), false);
  });

  testWidgets('delete profile', (WidgetTester tester) async {
    var data = BoardData(SchieberSettings(), SchieberScore(), "");
    data.profiles.list.add("Foo:Bar");

    final widget = makeTestableExpanded(ProfilePage(data, () {}));
    await tester.pumpWidget(widget);

    expect(find.text('Foo'), findsOneWidget);
    expect(data.profiles.list.length, 2);
    await tester.tap(find.byTooltip('Profil löschen'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(find.text('Foo'), findsNothing);
    expect(data.profiles.list.length, 1);
  });
}
