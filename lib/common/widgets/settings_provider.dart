import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides access to SharedPreferences throughout the widget tree.
///
/// Usage:
/// ```dart
/// final preferences = SettingsProvider.of(context);
/// ```
///
/// main() installs this once with the singleton returned by
/// SharedPreferences.getInstance(), so in the running app the instance never
/// changes and [updateShouldNotify] never fires. The widget is here so that
/// tests can pump a screen over their own SharedPreferences.
class SettingsProvider extends InheritedWidget {
  final SharedPreferences preferences;

  const SettingsProvider({
    super.key,
    required this.preferences,
    required super.child,
  });

  /// Gets the SharedPreferences instance from the nearest SettingsProvider
  /// ancestor.
  ///
  /// Throws if no SettingsProvider is found.
  static SharedPreferences of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<SettingsProvider>()!;
    return provider.preferences;
  }

  @override
  bool updateShouldNotify(covariant SettingsProvider oldWidget) =>
      preferences != oldWidget.preferences;
}
