import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/molotow/screens/molotow.dart';
import 'package:jasstafel/point_board/screens/point_board.dart';
import 'package:jasstafel/schieber/screens/schieber.dart';
import 'package:jasstafel/settings/coiffeur_settings.g.dart';
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:jasstafel/settings/schieber_settings.g.dart';
import 'package:pref/pref.dart';
import 'package:wakelock/wakelock.dart';
import 'package:flutter/services.dart';
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

  Locale getLanguage(appLanguage, locale, supportedLocales) {
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
    var settings = CommonSettings();
    settings.fromPrefService(context);
    final lastBoard = Board.values[settings.lastBoard].name;
    if (!Platform.isLinux) {
      Wakelock.toggle(enable: settings.keepScreenOn);
    }

    List<DeviceOrientation> po = [];
    if (settings.screenOrientation == 1 || lastBoard == Board.schieber.name) {
      po = [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown];
    } else if (settings.screenOrientation == 2) {
      po = [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight];
    }
    SystemChrome.setPreferredOrientations(po);

    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appName,
      theme: ThemeData(
          brightness: Brightness.dark,
          canvasColor: Colors.black,
          colorScheme: ColorScheme.dark(
            surface: Colors.grey.shade800, // top bar
            background: Colors.grey.shade600, // progress bar
            primary: Colors.blue.shade200, // buttons / progress bar
            secondary: Colors.blue.shade800, // settings
            tertiary: Colors.grey.shade800, // molotow round
          )),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        var language =
            getLanguage(settings.appLanguage, locale, supportedLocales);
        Intl.defaultLocale = language.toLanguageTag();
        return language;
      },
      routes: {
        Board.schieber.name: (context) => const Schieber(),
        Board.coiffeur.name: (context) => const Coiffeur(),
        Board.molotow.name: (context) => const Molotow(),
        Board.pointBoard.name: (context) => const PointBoard()
      },
      initialRoute: lastBoard,
    );
  }
}
