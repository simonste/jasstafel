import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/common/localization.dart';

class InputWrap<T> {
  T? value;
}

class JasstafelTestApp extends MaterialApp {
  JasstafelTestApp({super.key, child})
    : super(
        theme: ThemeData(
          brightness: Brightness.dark,
          canvasColor: Colors.black,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        localeResolutionCallback: (locale, supportedLocales) {
          return supportedLocales.first;
        },
        home: Material(child: child),
      );
}

Widget makeTestable(widget) {
  return JasstafelTestApp(
    child: Flex(direction: Axis.horizontal, children: [widget]),
  );
}

Widget makeTestableExpanded(widget) {
  return makeTestable(Expanded(child: widget));
}

extension ScreenOrientation on WidgetTester {
  void landscape() {
    view.physicalSize = const Size(800, 600);
  }

  void portrait() {
    view.physicalSize = const Size(600, 800);
  }
}
