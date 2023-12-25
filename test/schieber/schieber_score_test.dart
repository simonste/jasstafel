import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/schieber/data/schieber_score.dart';
import 'package:jasstafel/settings/schieber_settings.g.dart';
import 'package:test/test.dart';

void main() {
  test('add 612', () {
    var data = TeamData();

    data.strokes[0] = -13;
    data.strokes[1] = 6;
    data.strokes[2] = 2;
    data.strokes[3] = 1;
    data.strokes[4] = 0;

    final sumBefore = data.sum();
    data.add(612);
    final sumAfter = data.sum();

    expect(sumBefore + 612, sumAfter);
  });

  test('add 213', () {
    var data = TeamData();

    data.add(651);
    final sumBefore = data.sum();
    expect(sumBefore, 651);

    data.add(213);
    final sumAfter = data.sum();

    expect(sumBefore + 213, sumAfter);
  });

  test('overflow', () {
    var data = TeamData();

    data.strokes[0] = 24;
    data.strokes[1] = 26;
    data.strokes[2] = 15;
    data.strokes[3] = 20;
    data.strokes[4] = 0;

    final sumBefore = data.sum();
    data.checkOverflow();
    final sumAfter = data.sum();

    expect(sumBefore, sumAfter);
  });

  test('strokes', () {
    var data = TeamData();

    data.add(281);

    expect(data.sum(), 281);
    expect(data.strokes[0], 11);
    expect(data.strokes[1], 1);
    expect(data.strokes[2], 1);
    expect(data.strokes[3], 2);
    expect(data.strokes[4], 0);
  });

  test('minus1', () {
    var data = TeamData();

    var p0 = 666;
    data.add(p0);

    for (var i = 1; i < p0; i++) {
      data.add(-1);
      expect(data.sum(), p0 - i);
      expect(data.strokes[0] > -20, true);
      for (var stroke in data.strokes.sublist(1)) {
        assert(stroke >= 0);
      }
    }
  });

  test('remove 123', () {
    var data = TeamData();

    data.add(651);
    final sumBefore = data.sum();
    expect(sumBefore, 651);

    data.add(-123);
    final sumAfter = data.sum();

    expect(sumBefore - 123, sumAfter);
  });

  test('strokes remove', () {
    var data = TeamData();

    data.strokes[0] = -1;
    data.strokes[1] = 8;
    data.strokes[2] = 6;
    data.strokes[3] = 2;
    data.strokes[4] = 1;
    final sumBefore = data.sum();

    data.add(-281);

    expect(data.sum(), sumBefore - 281);
    expect(data.strokes[0], -12);
    expect(data.strokes[1], 7);
    expect(data.strokes[2], 5);
    expect(data.strokes[3], 0);
    expect(data.strokes[4], 1);
  });

  test('strokes remove weis', () {
    var data = TeamData();

    data.strokes[0] = 6;
    data.strokes[1] = 0;
    data.strokes[2] = 1;
    data.strokes[3] = 2;
    data.strokes[4] = 0;
    final sumBefore = data.sum();

    data.add(-100);

    expect(data.sum(), sumBefore - 100);
    expect(data.strokes[0], 6);
    expect(data.strokes[1], 0);
    expect(data.strokes[2], 1);
    expect(data.strokes[3], 1);
    expect(data.strokes[4], 0);
  });

  test('strokes remove 199', () {
    var data = TeamData();

    data.strokes[0] = 3;
    data.strokes[1] = 2;
    data.strokes[2] = 3;
    data.strokes[3] = 3;
    data.strokes[4] = 0;
    final sumBefore = data.sum();

    data.add(-199);

    expect(data.sum(), sumBefore - 199);
    expect(data.strokes[0], 4);
    expect(data.strokes[1], 2);
    expect(data.strokes[2], 3);
    expect(data.strokes[3], 1);
    expect(data.strokes[4], 0);
  });

  test('consolidate rounds', () {
    var score = SchieberScore();

    score.add(50, 0);
    score.rounds.last.time = DateTime(1999);

    // grouped as round
    score.add(50, 0);
    score.add(50, 0);
    score.add(20, 0);
    score.add(0, 37);

    score.add(0, 20);
    score.rounds.last.time = DateTime(2005);
    score.add(0, 20);
    score.rounds.last.time = DateTime(2005);

    score.add(5 * 66, 5 * (157 - 66));

    expect(score.noOfRounds(), 2);
    expect(score.weisPoints(), [50, 40]);
  });

  test('do not consolidate complete rounds', () {
    var score = SchieberScore();

    score.add(100, 57);
    score.add(262, 52);
    score.add(0, 514);

    expect(score.noOfRounds(), 3);
    expect(score.weisPoints(), [0, 0]);
  });

  test('do not consolidate complete round with previous', () {
    var score = SchieberScore();

    score.add(16, 141);
    score.add(50, 0);
    score.add(262, 52);

    expect(score.noOfRounds(), 2);
    expect(score.weisPoints(), [50, 0]);
  });

  test('hill & winner', () {
    var score = SchieberScore();
    score.team[0].goalPoints = 1000;
    score.team[1].goalPoints = 1000;

    score.add(200, 57);
    score.add(262, 150);
    expect(score.passedHill().isEmpty, true);
    expect(score.winner().isEmpty, true);

    score.add(132, 25);
    expect(score.passedHill()[0], "Team 1");
    expect(score.winner().isEmpty, true);

    score.add(0, 514);
    score.add(0, 257);
    expect(score.winner().length, 1);
    expect(score.winner()[0], "Team 2");
    expect(score.passedHill().isEmpty, true);
    expect(score.team[0].hill, true);
    expect(score.team[1].hill, false);
  });

  test('both passed hill', () {
    var score = SchieberScore();
    score.team[0].goalPoints = 400;
    score.team[1].goalPoints = 400;

    score.add(180, 57);
    score.add(262, 150);
    expect(score.passedHill().length, 2);
  });

  test('both win', () {
    var score = SchieberScore();
    score.team[0].goalPoints = 400;
    score.team[1].goalPoints = 400;

    score.add(180, 57);
    score.add(180, 200);
    score.add(262, 150);
    expect(score.winner().length, 2);
  });

  test('hill & winner rounds', () {
    var score = SchieberScore();
    var settings = SchieberSettings();
    settings.goalType = GoalType.rounds.index;
    score.setSettings(settings);
    score.goalRounds = 3;

    score.add(200, 0);
    score.add(100, 57);
    expect(score.passedHill().isEmpty, true);
    expect(score.winner().isEmpty, true);

    score.add(77, 80);
    expect(score.noOfRounds(), 2);
    expect(score.passedHill()[0], "Team 1");
    expect(score.winner().isEmpty, true);

    score.add(0, 300);
    score.add(60, 97);
    expect(score.winner().length, 1);
    expect(score.winner()[0], "Team 2");
    expect(score.passedHill().isEmpty, true);
    expect(score.team[0].hill, true);
    expect(score.team[1].hill, false);
  });

  test('both passed hill rounds', () {
    var score = SchieberScore();
    var settings = SchieberSettings();
    settings.goalType = GoalType.rounds.index;
    score.setSettings(settings);
    score.goalRounds = 4;

    score.add(200, 114);
    score.add(0, 40);
    score.add(134, 180);
    expect(score.passedHill().length, 2);
  });

  test('both win rounds', () {
    var score = SchieberScore();
    var settings = SchieberSettings();
    settings.goalType = GoalType.rounds.index;
    score.setSettings(settings);
    score.goalRounds = 2;

    score.add(77, 80);
    score.add(20, 0);
    score.add(70, 87);
    expect(score.winner().length, 2);
  });

  test('enforce weis points', () {
    var score = SchieberScore();

    score.add(0, 55, weis: true);
    expect(score.weisPoints(), [0, 55]);
  });
}
