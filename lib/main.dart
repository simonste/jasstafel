import 'package:flutter/material.dart';
import 'package:jasstafel/common/settings_keys.dart';
import 'package:pref/pref.dart';
import 'package:intl/intl.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/coiffeur/screens/coiffeur.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final service = await PrefServiceShared.init(
    defaults: {
      Keys.coiffeurRounded: false,
      Keys.coiffeurBonus: false,
      Keys.coiffeurRows: 11,
      Keys.coiffeur3Teams: false,
      Keys.coiffeurThirdColumn: false,
    },
  );

  runApp(
    PrefService(
      service: service,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Locale getLanguage(context, locale, supportedLocales) {
    var appLanguage = PrefService.of(context).get(Keys.appLanguage);
    if (appLanguage != null) {
      return Locale(appLanguage);
    }
    if (locale == null) {
      return supportedLocales.first;
    }
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        Intl.defaultLocale = supportedLocale.toLanguageTag();
        return supportedLocale;
      }
    }
    return supportedLocales.first;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.app_name,
      theme: ThemeData(brightness: Brightness.dark),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        var language = getLanguage(context, locale, supportedLocales);
        Intl.defaultLocale = language.toLanguageTag();
        return language;
      },
      home: const Coiffeur(),
    );
  }
}
