import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/schieber/data/schieber_score.dart';
import 'package:jasstafel/settings/schieber_settings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<BoardData<SchieberSettings, SchieberScore>> loadSchieber() => BoardData(
  SchieberSettings(),
  SchieberScore(),
  SchieberSettingsKeys().data,
).load();

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('switching to a new profile copies the active one', () async {
    final data = await loadSchieber();
    data.settings.match = 300;

    await data.switchProfile('Family');

    expect(data.profiles.active, 'Family');
    expect(data.settings.match, 300);
    expect(data.profileMap().keys, ['Standard', 'Family']);
  });

  test('switching to a profile loads it, the left one is kept', () async {
    final data = await loadSchieber();
    data.settings.match = 300;
    await data.switchProfile('Family');
    data.settings.match = 1000;

    await data.switchProfile('Standard');
    expect(data.settings.match, 300);
    await data.switchProfile('Family');
    expect(data.settings.match, 1000);
  });

  test('the profiles of a board that is not open are read', () async {
    final data = await loadSchieber();
    await data.switchProfile('Family');
    await pumpEventQueue();

    final (active, names) = await BoardData.storedProfiles(Board.schieber);
    expect(active, 'Family');
    expect(names, ['Standard', 'Family']);
  });
}
