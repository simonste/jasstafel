import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/coiffeur/data/coiffeur_score.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/history/game_record.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/differenzler/data/differenzler_score.dart';
import 'package:jasstafel/guggitaler/data/guggitaler_score.dart';
import 'package:jasstafel/molotow/data/molotow_score.dart';
import 'package:jasstafel/point_board/data/point_board_score.dart';
import 'package:jasstafel/schieber/data/schieber_score.dart';
import 'package:jasstafel/schlaeger/data/schlaeger_score.dart';
import 'package:jasstafel/settings/coiffeur_settings.g.dart';
import 'package:jasstafel/settings/differenzler_settings.g.dart';
import 'package:jasstafel/settings/guggitaler_settings.g.dart';
import 'package:jasstafel/settings/molotow_settings.g.dart';
import 'package:jasstafel/settings/point_board_settings.g.dart';
import 'package:jasstafel/settings/schieber_settings.g.dart';
import 'package:jasstafel/settings/schlaeger_settings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How each board's games end up in the history.
void main() {
  final records = <GameRecord>[];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    records.clear();
    BoardData.onGameEnded = (record) async => records.add(record);
  });

  tearDown(() => BoardData.onGameEnded = null);

  test('boards with a goal can finish, the others end by reset', () {
    final noGoal = GoalType.noGoal.index;
    final boards = <BoardData, bool>{
      BoardData(SchieberSettings(), SchieberScore(), 'a'): true,
      BoardData(SchieberSettings()..goalType = noGoal, SchieberScore(), 'b'):
          false,
      BoardData(CoiffeurSettings(), CoiffeurScore(), 'c'): true,
      BoardData(MolotowSettings()..goalType = noGoal, MolotowScore(), 'd'):
          false,
      BoardData(
        PointBoardSettings()..goalType = noGoal,
        PointBoardScore(),
        'e',
      ): false,
      BoardData(
        DifferenzlerSettings()..goalType = GoalType.rounds.index,
        DifferenzlerScore(),
        'f',
      ): true,
      BoardData(GuggitalerSettings(), GuggitalerScore(), 'g'): false,
      BoardData(SchlaegerSettings()..goalType = noGoal, SchlaegerScore(), 'h'):
          false,
    };
    for (final MapEntry(key: data, value: hasGoal) in boards.entries) {
      expect(data.hasGoal, hasGoal, reason: '${data.boardType}');
    }
  });

  test('a played board without a goal is finished when reset', () {
    final data = BoardData(
      MolotowSettings()
        ..goalType = GoalType.noGoal.index
        ..players = 3,
      MolotowScore(),
      MolotowSettingsKeys().data,
    );
    data.score.rows.add(MolotowRow([10, 20, 30], isRound: true));
    data.score.rows.add(MolotowRow([-20, null, 50], isRound: false));
    data.reset();

    final record = records.single;
    expect(record.finished, isTrue);
    expect(record.rounds, 1);
    expect(record.names, ['Spieler 1', 'Spieler 2', 'Spieler 3']);
    expect(record.totals, [-10, 20, 80]);
    expect(record.details, {
      'handWeis': [-20, 0, 0],
      'tableWeis': [0, 0, 50],
    });
    // The fewest points lead at Molotow.
    expect(record.winners, ['Spieler 1']);
    expect(record.players, [
      ['Spieler 1'],
      ['Spieler 2'],
      ['Spieler 3'],
    ]);
  });

  test('leaders are those with the best points, none while level', () {
    expect(leadersOf(['A', 'B', 'C'], [10, 30, 30]), ['B', 'C']);
    expect(leadersOf(['A', 'B', 'C'], [10, 30, 30], fewest: true), ['A']);
    expect(leadersOf(['A', 'B'], [20, 20]), isEmpty);
    expect(leadersOf([], []), isEmpty);
  });

  test('each board knows who leads', () {
    final noGoal = GoalType.noGoal.index;

    final schieber = BoardData(
      SchieberSettings()..goalType = noGoal,
      SchieberScore(),
      'a',
    );
    schieber.score.add(100, 57);
    expect(schieber.score.leaders(), ['Team 1']);

    final guggitaler = BoardData(GuggitalerSettings(), GuggitalerScore(), 'g');
    guggitaler.score.rows.add(GuggitalerRow()..domino[0] = -150);
    expect(guggitaler.score.leaders(), ['Spieler 1']);

    final differenzler = BoardData(
      DifferenzlerSettings()..players = 2,
      DifferenzlerScore(),
      'f',
    );
    differenzler.score.rows.add(
      DifferenzlerRow()
        ..guesses[0] = 50
        ..pts[0] = 60
        ..guesses[1] = 40
        ..pts[1] = 97,
    );
    expect(differenzler.score.leaders(), ['Spieler 1']);

    final schlaeger = BoardData(
      SchlaegerSettings()..players = 3,
      SchlaegerScore(),
      'h',
    );
    schlaeger.score.rows.add(SchlaegerRound([0, 3, 1]));
    expect(schlaeger.score.leaders(), ['Spieler 2']);

    final settings = PointBoardSettings()..players = 2;
    final points = BoardData(settings, PointBoardScore(), 'e');
    points.score.rows.add(PointBoardRow([5, 7]));
    expect(points.score.leaders(), ['Spieler 2']);
    settings.goalMax = false;
    expect(points.score.leaders(), ['Spieler 1']);
  });

  test('a board without a goal names its leaders the winners', () {
    final data = BoardData(
      SchieberSettings()..goalType = GoalType.noGoal.index,
      SchieberScore(),
      SchieberSettingsKeys().data,
    );
    data.score.add(57, 100);
    data.reset();
    expect(records.single.finished, isTrue);
    expect(records.single.winners, ['Team 2']);
  });

  test('a board with a goal reset before it has no winner', () {
    final data = BoardData(
      SchieberSettings(),
      SchieberScore(),
      SchieberSettingsKeys().data,
    );
    data.score.add(57, 100);
    data.reset();
    expect(records.single.finished, isFalse);
    expect(records.single.winners, isEmpty);
  });

  test('an empty differenzler is no game and resets', () async {
    final data = await BoardData(
      DifferenzlerSettings(),
      DifferenzlerScore(),
      DifferenzlerSettingsKeys().data,
    ).load();
    expect(data.score.rows, isEmpty);
    expect(data.played, isFalse);
    data.reset();
    expect(records, isEmpty);
  });

  test('a coiffeur reset before the last row is not finished', () {
    final data = BoardData(
      CoiffeurSettings(),
      CoiffeurScore(),
      CoiffeurSettingsKeys().data,
    );
    data.score.teamName = ['Max & Ann', 'Tom & Eva', 'Team 3'];
    data.score.rows[0].pts[0].pts = 57;
    data.reset();

    final record = records.single;
    expect(record.finished, isFalse);
    expect(record.names, ['Max & Ann', 'Tom & Eva']);
    expect(record.totals, [57, 0]);
    expect(record.players, [
      ['Max', 'Ann'],
      ['Tom', 'Eva'],
    ]);
  });

  test('a finished profile opened again is the same game', () async {
    final data = await BoardData(
      SchieberSettings(),
      SchieberScore(),
      SchieberSettingsKeys().data,
    ).load();
    await data.switchProfile('Family');
    data.score.add(2500, 100);
    data.common.timestamps.justFinished();
    data.saveActiveProfile();
    await data.switchProfile('Standard');
    records.clear();

    await data.loadProfile('Family');
    // Recorded again under the same game when saved, not as a new one.
    data.save();
    await pumpEventQueue();
    expect(records.map((r) => r.id).toSet().length, 1);
    expect(records.last.finished, isTrue);
  });
}
