import 'package:flutter/material.dart';
import 'package:jasstafel/common/localization.dart';

class GuggitalerValues {
  static final _values = {5: 9, 10: 9, 20: 4, 40: 1, 50: 1};

  static int get length => _values.length;

  static int points(int i) {
    return _values.keys.toList()[i];
  }

  static int maxPerRound(int i) {
    return _values[points(i)]!;
  }

  static String type(int i, BuildContext context) {
    switch (i) {
      case 0:
        return context.l10n.tricks;
      case 1:
        return context.l10n.schellen;
      case 2:
        return context.l10n.queen;
      case 3:
        return context.l10n.rosesKing;
    }
    return context.l10n.lastTrick;
  }
}
