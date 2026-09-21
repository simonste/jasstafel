import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/common/widgets/pref_number.dart';

import '../helper/testapp.dart';

/// Holds the value the way a settings screen does: PrefNumber is stateless and
/// the parent owns both the value and storing it.
class _Host extends StatefulWidget {
  const _Host({required this.onChanged});

  final ValueChanged<int> onChanged;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int value = 1000;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // push the tile towards the bottom of the viewport
        for (var i = 0; i < 12; i++) const ListTile(title: Text('fill')),
        PrefNumber(
          title: const Text('goal points'),
          value: value,
          onChanged: (v) {
            setState(() => value = v);
            widget.onChanged(v);
          },
        ),
      ],
    );
  }
}

void main() {
  testWidgets('stores the value', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    var changedTo = 0;
    await tester.pumpWidget(
      makeTestableExpanded(_Host(onChanged: (v) => changedTo = v)),
    );

    expect(find.text('1000'), findsOneWidget);

    await tester.tap(find.text('goal points'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '-42');
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(changedTo, 42, reason: 'the sign is dropped');
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('stores the value if the tile is unmounted while the dialog is '
      'open', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    var changedTo = 0;
    await tester.pumpWidget(
      makeTestableExpanded(_Host(onChanged: (v) => changedTo = v)),
    );

    await tester.tap(find.text('goal points'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '4');

    // the soft keyboard shrinks the viewport, which unmounts the tile because
    // the list is lazy
    tester.view.physicalSize = const Size(400, 400);
    await tester.pumpAndSettle();
    expect(find.byType(PrefNumber), findsNothing, reason: 'tile is unmounted');

    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(changedTo, 4);
  });
}
