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

/// The most of the screen height a keyboard is taken to cover. A phone held
/// in landscape, where a keyboard covers the most, stays around two thirds.
const maxKeyboardShare = 0.75;

/// Keeps the keyboard insets to what a keyboard can cover.
///
/// iOS derives them from the keyboard frame relative to the view, and while
/// the keyboard animates it reports them negative, which trips the
/// `padding.isNonNegative` assertion in Dialog, or for a frame as covering
/// all but a strip of the screen, which leaves a dialog too little room for
/// its buttons.
MediaQueryData clampViewInsets(MediaQueryData data) {
  final insets = data.viewInsets;
  return data.copyWith(
    viewInsets: EdgeInsets.fromLTRB(
      max(0.0, insets.left),
      max(0.0, insets.top),
      max(0.0, insets.right),
      insets.bottom.clamp(0.0, data.size.height * maxKeyboardShare),
    ),
  );
}

/// Turns a [MediaQueryData] a quarter turn clockwise, to go with a
/// [RotatedBox] of one quarter turn around the app.
///
/// The app then sees the screen as the board wants to be held: its width and
/// height swap, and every edge moves one step, the top of the screen becoming
/// the left of the app. Insets have to travel along, or the status bar would
/// keep a strip free on the wrong side and dialogs would open under the
/// keyboard.
///
/// The app turns itself rather than asking android for an orientation,
/// because android is free to turn that request down. A tablet answers it
/// with a portrait window in the middle of the landscape screen, leaving the
/// board a fraction of it, and phones can behave the same way. Turning it
/// here looks the same as a locked orientation: the board stays with the
/// device, whichever way it is held.
MediaQueryData quarterTurn(MediaQueryData data) {
  EdgeInsets turn(EdgeInsets i) =>
      EdgeInsets.fromLTRB(i.top, i.right, i.bottom, i.left);
  return data.copyWith(
    size: data.size.flipped,
    padding: turn(data.padding),
    viewPadding: turn(data.viewPadding),
    viewInsets: turn(data.viewInsets),
    systemGestureInsets: turn(data.systemGestureInsets),
  );
}

/// Reports which board the app shows, and when a page on top of it closes.
///
/// The preferences are read once when the app starts and boards are switched
/// by replacing the route, so while the app runs the route is what tells them
/// apart. The page that closes is the settings screen, which may have changed
/// what the app reads there.
class BoardObserver extends NavigatorObserver {
  BoardObserver({required this.onBoard, required this.onReturn});

  final ValueChanged<String> onBoard;
  final VoidCallback onReturn;

  String? boardName(Route<dynamic>? route) {
    final name = route?.settings.name;
    final isBoard = Board.values.any((board) => board.name == name);
    return isBoard ? name : null;
  }

  void report(Route<dynamic>? route) {
    final name = boardName(route);
    if (name != null) onBoard(name);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      report(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      report(newRoute);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Dialogs are popup routes and leave the settings alone.
    if (route is PageRoute && boardName(previousRoute) != null) onReturn();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  /// The board on screen, seeded in [build] from the preferences.
  String? board;

  late final observer = BoardObserver(
    onBoard: (name) {
      if (name != board) refresh(() => board = name);
    },
    // build reads the preferences again, there is nothing else to change.
    onReturn: () => refresh(() {}),
  );

  /// Rebuilds after the frame, routes come and go while the navigator builds.
  void refresh(VoidCallback change) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(change);
    });
  }

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
    // The navigator opens on lastBoard, so seeding the board here leaves the
    // observer nothing to report until one is switched.
    board ??= lastBoard;
    WakelockPlus.toggle(enable: settings.keepScreenOn);

    // The schieber board is drawn for a portrait screen, the others follow the
    // setting.
    final wanted = board == Board.schieber.name
        ? Orientation.portrait
        : switch (settings.screenOrientation) {
            1 => Orientation.portrait,
            2 => Orientation.landscape,
            _ => null,
          };

    final themeMode = ThemeMode.values[settings.themeMode];

    return MaterialApp(
      builder: (context, child) {
        var data = clampViewInsets(MediaQuery.of(context));
        final turn = wanted != null && data.orientation != wanted;
        return RotatedBox(
          quarterTurns: turn ? 1 : 0,
          child: MediaQuery(
            data: turn ? quarterTurn(data) : data,
            child: child!,
          ),
        );
      },
      locale: Locale(settings.appLanguage),
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
      navigatorObservers: [observer],
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
