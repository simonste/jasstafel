import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/rounding.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/molotow/data/molotow_score.dart';
import 'package:jasstafel/settings/molotow_settings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bool preferences become rounding modes', () async {
    SharedPreferences.setMockInitialValues({
      'coiffeur_rounded': true,
      'molotow_rounded': false,
      'point_board_rounded': 1,
    });
    final preferences = await SharedPreferences.getInstance();

    await migrateRoundedPreferences(preferences);

    expect(preferences.get('coiffeur_rounded'), RoundingMode.round.index);
    expect(preferences.get('molotow_rounded'), RoundingMode.none.index);
    expect(preferences.get('point_board_rounded'), RoundingMode.round.index);
  });

  test('loading twice keeps the migrated setting', () async {
    SharedPreferences.setMockInitialValues({'molotow_rounded': true});

    for (var i = 0; i < 2; i++) {
      final data = BoardData(MolotowSettings(), MolotowScore(), 'molotow');
      await data.load();
      expect(data.settings.roundingMode, RoundingMode.round);
    }
  });

  test('restoring an old profile migrates it', () async {
    SharedPreferences.setMockInitialValues({});
    final data = BoardData(MolotowSettings(), MolotowScore(), 'molotow');
    final profile = MolotowSettings().toJson();
    profile['molotow'] = jsonEncode(MolotowScore().toJson());
    profile['molotow_rounded'] = true;

    data.fromJson(profile);
    await pumpEventQueue();

    expect(data.settings.roundingMode, RoundingMode.round);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.get('molotow_rounded'), RoundingMode.round.index);
  });
}
