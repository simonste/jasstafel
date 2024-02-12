import 'package:jasstafel/schlaeger/data/schlaeger_score.dart';
import 'package:jasstafel/settings/schlaeger_settings.g.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:test/test.dart';

void main() {
  test('count rows', () {
    var score = SchlaegerScore();

    score.rows.add(SchlaegerRound([null, 1, 2]));
    score.rows.add(SchlaegerRound([1, -1, 2]));
    score.rows.add(SchlaegerRound([1, 1, 1]));

    expect(score.noOfRounds(), 3);
  });

  test('count points', () {
    var score = SchlaegerScore();

    score.rows.add(SchlaegerRound([-1]));
    score.rows.add(SchlaegerRound([]));
    score.rows.add(SchlaegerRound([2]));

    expect(score.total(0), 1);
  });

  test('check winner points', () {
    var score = SchlaegerScore();
    var settings = SchlaegerSettings();
    settings.players = 3;
    settings.goalType = GoalType.points.index;
    settings.goalPoints = 9;
    score.setSettings(settings);

    score.rows.add(SchlaegerRound([2, 1, -1]));
    score.rows.add(SchlaegerRound([1, 1, 1]));
    score.rows.add(SchlaegerRound([null, 3, 0]));
    score.rows.add(SchlaegerRound([1, 2, -1]));
    score.rows.add(SchlaegerRound([-1, 2, 1]));

    expect(score.winner(), ["Spieler 2"]);
    expect(score.loser(), []);
  });

  test('check two winner points', () {
    var score = SchlaegerScore();
    var settings = SchlaegerSettings();
    settings.players = 3;
    settings.goalType = GoalType.points.index;
    settings.goalPoints = 5;
    score.setSettings(settings);

    score.rows.add(SchlaegerRound([2, -1, 1]));
    score.rows.add(SchlaegerRound([null, -1, 3]));
    score.rows.add(SchlaegerRound([2, 1, null]));
    score.rows.add(SchlaegerRound([1, 1, 1]));

    expect(score.winner(), ["Spieler 1", "Spieler 3"]);
    expect(score.loser(), []);
  });

  test('check winner rounds', () {
    var score = SchlaegerScore();
    var settings = SchlaegerSettings();
    settings.players = 3;
    settings.goalType = GoalType.rounds.index;
    settings.goalRounds = 3;
    score.setSettings(settings);

    score.rows.add(SchlaegerRound([2, 1, null]));
    score.rows.add(SchlaegerRound([1, -1, 2]));

    expect(score.winner(), []);

    score.rows.add(SchlaegerRound([1, 1, 1]));

    expect(score.winner(), ["Spieler 1"]);
    expect(score.loser(), []); // no loser with rounds
  });
}
