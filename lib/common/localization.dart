import 'package:flutter/material.dart';
import 'package:jasstafel/l10n/app_localizations.dart';

export 'package:jasstafel/l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

extension ThemeFontWeightX on BuildContext {
  // Thin weights lack contrast on the light background, so bump them up there.
  FontWeight fontWeight(FontWeight weight) {
    if (Theme.of(this).brightness == Brightness.dark) return weight;
    if (weight.index < FontWeight.w400.index) return FontWeight.w400;
    if (weight == FontWeight.w400) return FontWeight.w600;
    return weight;
  }
}
