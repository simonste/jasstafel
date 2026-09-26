import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/settings/coiffeur_settings.g.dart';
import 'package:jasstafel/settings/molotow_settings.g.dart';
import 'package:jasstafel/settings/point_board_settings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

extension CoiffeurRounding on CoiffeurSettings {
  RoundingMode get roundingMode => RoundingMode.values[rounded];
  set roundingMode(RoundingMode mode) => rounded = mode.index;
}

extension MolotowRounding on MolotowSettings {
  RoundingMode get roundingMode => RoundingMode.values[rounded];
  set roundingMode(RoundingMode mode) => rounded = mode.index;
}

extension PointBoardRounding on PointBoardSettings {
  RoundingMode get roundingMode => RoundingMode.values[rounded];
  set roundingMode(RoundingMode mode) => rounded = mode.index;
}

const _roundedKeys = [
  'coiffeur_rounded',
  'molotow_rounded',
  'point_board_rounded',
];

int _roundingIndex(bool rounded) =>
    (rounded ? RoundingMode.round : RoundingMode.none).index;

Future<void> migrateRoundedPreferences(SharedPreferences preferences) async {
  for (final key in _roundedKeys) {
    // getBool would throw once the value is an int
    final value = preferences.get(key);
    if (value is bool) {
      await preferences.remove(key);
      await preferences.setInt(key, _roundingIndex(value));
    }
  }
}

/// Saved profiles keep the settings as json, so they need it too.
void migrateRoundedJson(Map<String, dynamic> json) {
  for (final key in _roundedKeys) {
    final value = json[key];
    if (value is bool) {
      json[key] = _roundingIndex(value);
    }
  }
}
