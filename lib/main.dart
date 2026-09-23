import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/widgets/settings_provider.dart';
import 'package:jasstafel/coiffeur/screens/coiffeur.dart';
import 'package:jasstafel/differenzler/screens/differenzler.dart';
import 'package:jasstafel/guggitaler/screens/guggitaler.dart';
import 'package:jasstafel/molotow/screens/molotow.dart';
import 'package:jasstafel/point_board/screens/point_board.dart';
import 'package:jasstafel/schieber/screens/schieber.dart';
import 'package:jasstafel/schlaeger/screens/schlaeger.dart';
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:jasstafel/common/localization.dart';

const _systemUiOverlayStyle = SystemUiOverlayStyle(
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(_systemUiOverlayStyle);

  final preferences = await SharedPreferences.getInstance();

  runApp(SettingsProvider(preferences: preferences, child: const MyApp()));
}

/// Clamps the keyboard insets to zero.
///
/// iOS derives them from the keyboard frame relative to the view and reports
/// them negative while the keyboard animates, which trips the
/// `padding.isNonNegative` assertion in Dialog.
Widget clampViewInsets(BuildContext context, Widget? child) {
  final data = MediaQuery.of(context);
  final insets = data.viewInsets;
  return MediaQuery(
    data: data.copyWith(
      viewInsets: EdgeInsets.fromLTRB(
        max(0.0, insets.left),
        max(0.0, insets.top),
        max(0.0, insets.right),
        max(0.0, insets.bottom),
      ),
    ),
    child: child!,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Locale getLanguage(
    String? appLanguage,
    Locale? locale,
    Iterable<Locale> supportedLocales,
  ) {
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
    settings.fromPreferences(SettingsProvider.of(context));
    final lastBoard = Board.values[settings.lastBoard].name;
    WakelockPlus.toggle(enable: settings.keepScreenOn);

    List<DeviceOrientation> po = [];
    if (settings.screenOrientation == 1 || lastBoard == Board.schieber.name) {
      po = [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown];
    } else if (settings.screenOrientation == 2) {
      po = [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight];
    }
    SystemChrome.setPreferredOrientations(po);

    final themeMode = ThemeMode.values[settings.themeMode];

    return MaterialApp(
      builder: clampViewInsets,
      onGenerateTitle: (context) => context.l10n.appName,
      themeMode: themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        canvasColor: Colors.grey.shade200, // drop down
        dialogTheme: DialogThemeData(backgroundColor: Colors.grey.shade200),
        dividerColor: Colors.grey.shade400,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.white),
          systemOverlayStyle: _systemUiOverlayStyle,
        ),
        colorScheme: ColorScheme.light(
          surface: Colors.grey.shade200, // progress bar
          primary: Colors.blue.shade800, // buttons / progress bar
          secondary: Colors.blue.shade400, // settings
          tertiary: Colors.grey.shade200, // molotow round
          onSurface: Colors.black87,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        canvasColor: Colors.grey.shade800, // drop down
        dialogTheme: DialogThemeData(backgroundColor: Colors.grey.shade800),
        dividerColor: Colors.grey.shade600,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey.shade900,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          systemOverlayStyle: _systemUiOverlayStyle,
        ),
        colorScheme: ColorScheme.dark(
          surface: Colors.grey.shade800, // progress bar
          primary: Colors.blue.shade200, // buttons / progress bar
          secondary: Colors.blue.shade800, // settings
          tertiary: Colors.grey.shade800, // molotow round
          onSurface: Colors.white,
          onPrimary: Colors.black,
          onSecondary: Colors.white,
        ),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        var language = getLanguage(
          settings.appLanguage,
          locale,
          supportedLocales,
        );
        Intl.defaultLocale = language.toLanguageTag();
        return language;
      },
      routes: {
        Board.schieber.name: (context) => const Schieber(),
        Board.coiffeur.name: (context) => const Coiffeur(),
        Board.molotow.name: (context) => const Molotow(),
        Board.pointBoard.name: (context) => const PointBoard(),
        Board.differenzler.name: (context) => const Differenzler(),
        Board.guggitaler.name: (context) => const Guggitaler(),
        Board.schlaeger.name: (context) => const Schlaeger(),
      },
      initialRoute: lastBoard,
    );
  }
}
