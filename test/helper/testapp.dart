import 'package:flutter/material.dart';
import 'package:jasstafel/common/localization.dart';

class JasstafelTestApp extends MaterialApp {
  JasstafelTestApp({super.key, child})
      : super(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            localeResolutionCallback: (locale, supportedLocales) {
              return supportedLocales.first;
            },
            home: Material(child: child));
}