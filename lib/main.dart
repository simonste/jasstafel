import 'package:flutter/material.dart';
import 'package:jasstafel/common/widgets/board_title.dart';
import 'package:jasstafel/schieber/screens/schieber.dart';
import 'package:jasstafel/settings/coiffeur_settings.g.dart';
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:jasstafel/settings/schieber_settings.g.dart';
import 'package:pref/pref.dart';
import 'package:intl/intl.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/coiffeur/screens/coiffeur.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final service = await PrefServiceShared.init(
      defaults: CommonSettings.defaults
        ..addAll(CoiffeurSettings.defaults)
        ..addAll(SchieberSettings.defaults));

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
    var appLanguage =
        PrefService.of(context).get(CommonSettings.keys.appLanguage);
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
    getLastOpenedBoard() {
      final lastBoard = Board
          .values[PrefService.of(context).get(CommonSettings.keys.lastBoard)];
      switch (lastBoard) {
        case Board.coiffeur:
          return const Coiffeur();
        case Board.schieber:
          return const Schieber();
      }
    }

    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.app_name,
      theme: ThemeData(brightness: Brightness.dark, canvasColor: Colors.black),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        var language = getLanguage(context, locale, supportedLocales);
        Intl.defaultLocale = language.toLanguageTag();
        return language;
      },
      home: getLastOpenedBoard(),
    );
  }
}
