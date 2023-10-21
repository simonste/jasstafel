import 'package:jasstafel/differenzler/data/differenzler_score.dart';
import 'package:jasstafel/settings/differenzler_settings.g.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:test/test.dart';

void main() {
  test('count rows', () {
    var score = DifferenzlerScore();

    score.rows.add(DifferenzlerRow());
    score.rows.last.guesses = [10, 20, 2, 100];
    expect(score.noOfRounds(), 0);
    score.rows.last.pts = [10, 20, 2, 100];
    expect(score.noOfRounds(), 1);
  });

  test('count points', () {
    var score = DifferenzlerScore();

    score.rows.add(DifferenzlerRow());
    score.rows.last.guesses = [10, 20, 2, 50];
    score.rows.last.pts = [15, 22, 6, 52];

    score.rows.add(DifferenzlerRow());
    score.rows.last.guesses = [10, 20, 2, 50];
    score.rows.last.pts = [10, 10, 24, 51];

    expect(score.total(0), 5);
  });

  test('check winner points', () {
    var score = DifferenzlerScore();
    var settings = DifferenzlerSettings();
    settings.players = 3;
    settings.goalType = GoalType.points.index;
    settings.goalPoints = 50;
    score.setSettings(settings);

    score.rows.add(DifferenzlerRow());
    score.rows.last.guesses = [10, 30, 50];
    score.rows.last.pts = [20, 10, 51];
    score.rows.add(DifferenzlerRow());
    score.rows.last.guesses = [10, 20, 50];
    score.rows.last.pts = [16, 70, 51];

    expect(score.winner(), ["Spieler 3"]);
    expect(score.loser(), ["Spieler 2"]);
  });

  test('check two winner points', () {
    var score = DifferenzlerScore();
    var settings = DifferenzlerSettings();
    settings.players = 3;
    settings.goalType = GoalType.points.index;
    settings.goalPoints = 50;
    score.setSettings(settings);

    score.rows.add(DifferenzlerRow());
    score.rows.last.guesses = [10, 30, 50];
    score.rows.last.pts = [20, 10, 51];
    score.rows.add(DifferenzlerRow());
    score.rows.last.guesses = [10, 20, 50];
    score.rows.last.pts = [16, 70, 65];

    expect(score.winner(), ["Spieler 1", "Spieler 3"]);
    expect(score.loser(), ["Spieler 2"]);
  });

  test('check two loser points', () {
    var score = DifferenzlerScore();
    var settings = DifferenzlerSettings();
    settings.players = 3;
    settings.goalType = GoalType.points.index;
    settings.goalPoints = 50;
    score.setSettings(settings);

    score.rows.add(DifferenzlerRow());
    score.rows.last.guesses = [10, 30, 50];
    score.rows.last.pts = [20, 10, 60];
    score.rows.add(DifferenzlerRow());
    score.rows.last.guesses = [10, 20, 50];
    score.rows.last.pts = [16, 70, 110];

    expect(score.winner(), ["Spieler 1"]);
    expect(score.loser(), ["Spieler 2", "Spieler 3"]);
  });

  test('check winner rounds', () {
    var score = DifferenzlerScore();
    var settings = DifferenzlerSettings();
    settings.players = 3;
    settings.goalType = GoalType.rounds.index;
    settings.goalRounds = 2;
    score.setSettings(settings);

    score.rows.add(DifferenzlerRow());
    score.rows.last.guesses = [10, 30, 50];
    score.rows.last.pts = [20, 10, 60];
    expect(score.winner(), []);

    score.rows.add(DifferenzlerRow());
    score.rows.last.guesses = [10, 20, 50];
    score.rows.last.pts = [16, 21, 49];

    expect(score.winner(), ["Spieler 3"]);
    expect(score.loser(), []); // no loser with rounds
  });

  test('count guesses', () {
    var score = DifferenzlerScore();

    score.rows.add(DifferenzlerRow());
    score.rows.last.guesses = [10, 20, 2, 50];
    score.rows.last.pts = [15, 22, 6, 52];

    score.rows.add(DifferenzlerRow());
    score.rows.last.guesses = [10, 20, 2, 50];
    score.rows.last.pts = [10, 10, 24, 51];

    score.rows.add(DifferenzlerRow());
    score.rows.last.guesses = [10, 20, 6, 50]; // ignored

    expect(score.avgGuessed(0), 10);
    expect(score.avgGuessed(1), 20);
    expect(score.avgGuessed(2), 2);
    expect(score.avgGuessed(3), 50);
    expect(score.avgPoints(0), 12.5);
    expect(score.avgPoints(1), 16);
    expect(score.avgPoints(2), 15);
    expect(score.avgPoints(3), 51.5);
  });
}
