import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/main.dart';

void main() {
  testWidgets('a dialog opens although the keyboard insets are negative', (
    tester,
  ) async {
    // what iOS reports while the keyboard animates
    tester.view.viewInsets = const FakeViewPadding(bottom: -120);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      MaterialApp(
        builder: clampViewInsets,
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
}
