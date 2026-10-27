import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/schieber/data/schieber_score.dart';
import 'package:jasstafel/settings/schieber_settings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('accepts only the board\'s own settings of the right type', () {
    final accepted = BoardData.acceptedSettings(Board.schieber, {
      'schieber_match': 300, // a game setting
      'schieber_goal_type': 'points', // wrong type
      'schieber_vibrate': false, // local
      'schieber': '{"team":[]}', // the score, not a setting
      'last_board': 3, // not of this board
      'theme_mode': 2,
      'coiffeur_match': 500, // another board's
    });
    expect(accepted, {'schieber_match': 300});
  });

  test('accepts only the values of the enum a setting indexes', () {
    final accepted = BoardData.acceptedSettings(Board.molotow, {
      'molotow_goal_type': 2,
      'molotow_rounded': 3,
      'molotow_players': 5,
    });
    expect(accepted, {
      'molotow_goal_type': 2,
      'molotow_rounded': 3,
      'molotow_players': 5,
    });
    expect(
      BoardData.acceptedSettings(Board.molotow, {
        'molotow_goal_type': 3, // a goal type of a newer app
        'molotow_rounded': -1,
      }),
      isEmpty,
    );
  });

  test('a state the board can\'t take leaves it as it was', () async {
    SharedPreferences.setMockInitialValues({});
    final data = BoardData(
      SchieberSettings(),
      SchieberScore(),
      SchieberSettingsKeys().data,
    );
    data.score.add(157, 0);
    final before = data.currentJson();

    expect(
      () => data.applyRemote('{"team": 5}', {'schieber_match': 300}),
      throwsA(anything),
    );

    expect(data.currentJson(), before);
    expect(data.settings.match, 257);
    await pumpEventQueue();
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt('schieber_match'), isNull);
  });

  test('the local settings come from the settings YAML', () {
    expect(BoardData.localSettingsOf(Board.schieber), {
      'schieber_backside',
      'schieber_touch_screen',
      'schieber_vibrate',
      'schieber_big_score',
      'schieber_draw_Z',
    });
    expect(BoardData.localSettingsOf(Board.coiffeur), {
      'coiffeur_grey_out_completed_rows',
    });
    expect(BoardData.localSettingsOf(Board.differenzler), {
      'differenzler_hide_guess',
    });
    expect(BoardData.localSettingsOf(Board.molotow), isEmpty);
  });

  test('every board has a data key among its defaults', () {
    for (final board in Board.values) {
      expect(
        BoardData.defaultSettings(
          board,
        ).containsKey(BoardData.dataKeyOf(board)),
        isTrue,
        reason: board.name,
      );
    }
  });
}
