import 'package:jasstafel/molotow/data/molotow_score.dart';
import 'package:jasstafel/settings/molotow_settings.g.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:test/test.dart';

void main() {
  test('count rows', () {
    var score = MolotowScore();

    score.rows.add(MolotowRow([null, 10, 0], isRound: false));
    score.rows.add(MolotowRow([44, 33, 55, 25], isRound: true));
    score.rows.add(MolotowRow([null, null, 20], isRound: false));

    expect(score.noOfRounds(), 1);
  });

  test('count points', () {
    var score = MolotowScore();

    score.rows.add(MolotowRow([], isRound: false));
    score.rows.add(MolotowRow([], isRound: true));
    score.rows.add(MolotowRow([5], isRound: false));

    expect(score.total(0), 5);
  });

  test('count points rounded', () {
    var score = MolotowScore();
    var settings = MolotowSettings();
    settings.rounded = true;
    score.setSettings(settings);

    score.rows.add(MolotowRow([], isRound: false));
    score.rows.add(MolotowRow([], isRound: true));
    score.rows.add(MolotowRow([54], isRound: false));

    expect(score.total(0), 5);
  });

  test('check winner points', () {
    var score = MolotowScore();
    var settings = MolotowSettings();
    settings.players = 3;
    settings.goalType = GoalType.points.index;
    settings.goalPoints = 100;
    score.setSettings(settings);

    score.rows.add(MolotowRow([10, 50, 10], isRound: false));
    score.rows.add(MolotowRow([54, 60, 20], isRound: false));

    expect(score.winner(), ["Spieler 3"]);
    expect(score.loser(), ["Spieler 2"]);
  });

  test('check two winner points', () {
    var score = MolotowScore();
    var settings = MolotowSettings();
    settings.players = 3;
    settings.goalType = GoalType.points.index;
    settings.goalPoints = 100;
    score.setSettings(settings);

    score.rows.add(MolotowRow([10, 50, 24], isRound: false));
    score.rows.add(MolotowRow([54, 60, 40], isRound: false));

    expect(score.winner(), ["Spieler 1", "Spieler 3"]);
    expect(score.loser(), ["Spieler 2"]);
  });

  test('check two loser points', () {
    var score = MolotowScore();
    var settings = MolotowSettings();
    settings.players = 3;
    settings.goalType = GoalType.points.index;
    settings.goalPoints = 100;
    score.setSettings(settings);

    score.rows.add(MolotowRow([10, 50, 10], isRound: false));
    score.rows.add(MolotowRow([54, 60, 100], isRound: false));

    expect(score.winner(), ["Spieler 1"]);
    expect(score.loser(), ["Spieler 2", "Spieler 3"]);
  });

  test('check winner rounds', () {
    var score = MolotowScore();
    var settings = MolotowSettings();
    settings.players = 3;
    settings.goalType = GoalType.rounds.index;
    settings.goalRounds = 2;
    score.setSettings(settings);

    score.rows.add(MolotowRow([10, 50, 10], isRound: true));
    score.rows.add(MolotowRow([54, 60, 20], isRound: false));

    expect(score.winner(), []);

    score.rows.add(MolotowRow([74, 10, 20], isRound: true));

    expect(score.winner(), ["Spieler 3"]);
    expect(score.loser(), []); // no loser with rounds
  });

  test('count weis', () {
    var score = MolotowScore();

    score.rows.add(MolotowRow([60, 20], isRound: false));
    score.rows.add(MolotowRow([15, 88, 54], isRound: true));
    score.rows.add(MolotowRow([null, null, -10], isRound: false));

    expect(score.total(0), 75);
    expect(score.total(1), 108);
    expect(score.total(2), 44);
    expect(score.handWeis(0), 0);
    expect(score.handWeis(1), 0);
    expect(score.handWeis(2), -10);
    expect(score.tableWeis(0), 60);
    expect(score.tableWeis(1), 20);
    expect(score.tableWeis(2), 0);
  });
}
