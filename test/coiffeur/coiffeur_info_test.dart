import 'dart:math';

import 'package:jasstafel/coiffeur/data/coiffeur_hint.dart';
import 'package:jasstafel/coiffeur/data/coiffeur_score.dart';
import 'package:jasstafel/coiffeur/dialog/coiffeur_info.dart';
import 'package:jasstafel/settings/coiffeur_settings.g.dart';
import 'package:test/test.dart';
import 'package:collection/collection.dart';

void main() {
  expectHints(CoiffeurInfo info, List<Hint> expectedHints) {
    final hints = info.getHints();
    expect(hints.length, expectedHints.length);
    for (var i = 0; i < expectedHints.length; i++) {
      final hint = hints[i];
      final expectedHint = expectedHints[i];
      expect(hint.type, expectedHint.type);
      expect(hint.teamName, expectedHint.teamName);
      expect(hint.p2, expectedHint.p2);
      expect(hint.p3, expectedHint.p3);
    }
  }

  expectNoWinner(CoiffeurInfo info) {
    final winners = info.winner();
    expect(winners.winner, []);
    expect(winners.loser, []);
  }

  expectWinner(CoiffeurInfo info, List<int> winner, List<int> loser) {
    final winners = info.winner();
    expect(winners.winner, winner);
    expect(winners.loser, loser);
  }

  var settings = CoiffeurSettings();
  var score = CoiffeurScore();

  setUp(() {
    settings = CoiffeurSettings();
    score = CoiffeurScore();
  });

  test('two teams game over', () {
    settings.rows = 1;
    score.setSettings(settings);

    score.rows[0].pts[0].pts = 200;
    score.rows[0].pts[1].pts = 240;
    final info = CoiffeurInfo(settings, score);

    expectHints(info, []);
    expectWinner(info, [1], [0]);
  });

  test('two teams game over draw', () {
    settings.rows = 1;
    score.setSettings(settings);

    score.rows[0].pts[0].pts = 200;
    score.rows[0].pts[1].pts = 200;
    final info = CoiffeurInfo(settings, score);

    expectHints(info, []);
    expectWinner(info, [0, 1], []);
  });

  test('two teams one game open', () {
    settings.rows = 2;
    score.setSettings(settings);

    score.rows[0].pts[0].pts = 100;
    score.rows[0].pts[1].pts = 200;
    score.rows[1].pts[0].pts = 200;

    final info = CoiffeurInfo(settings, score);

    expectHints(info, [
      Hint.winPointsSingle('Team 2', factor: 2, pts: 150),
    ]);
    expectNoWinner(info);
  });

  test('two teams two games open', () {
    settings.rows = 2;
    score.setSettings(settings);

    score.rows[0].pts[0].pts = 100;
    score.rows[1].pts[0].pts = 100;

    final info = CoiffeurInfo(settings, score);
    expect(info.result[0].pts, 300);

    expectHints(info, [
      Hint.winPoints('Team 2', pts: 100),
      Hint.winWithMatch('Team 2', factor: 2),
    ]);
    expectNoWinner(info);
  });

  test('two teams both can win with matches', () {
    settings.rows = 3;
    score.setSettings(settings);

    final info = CoiffeurInfo(settings, score);

    expectHints(info, [
      Hint.winPoints('Team 1', pts: 257),
      Hint.winPoints('Team 2', pts: 257),
    ]);
    expectNoWinner(info);
  });

  test('two teams win with avg or match', () {
    settings.rows = 3;
    score.setSettings(settings);

    score.rows[0].pts[1].pts = 100;
    score.rows[2].pts[1].pts = 60;
    score.rows[0].pts[0].pts = 130;

    final info = CoiffeurInfo(settings, score);
    expect(info.result[1].max, 280 + 2 * 257);

    expectHints(info, [
      Hint.winPoints('Team 1', pts: 133),
      Hint.winWithMatch('Team 1', factor: 3),
    ]);
    expectNoWinner(info);
  });

  test('two teams avg not losing', () {
    settings.rows = 4;
    score.setSettings(settings);

    score.rows[0].pts[1].pts = 100;
    score.rows[1].pts[1].pts = 40;
    score.rows[1].pts[0].pts = 257;
    score.rows[2].pts[0].pts = 130;

    final info = CoiffeurInfo(settings, score);
    expect(info.result[0].pts, 904);

    expectHints(info, [
      Hint.winPoints('Team 1', pts: 215),
      Hint.pointsNotLose('Team 2', pts: 104),
    ]);
    expectNoWinner(info);
  });

  test('two teams match not losing', () {
    settings.rows = 4;
    score.setSettings(settings);

    score.rows[0].pts[1].pts = 100;
    score.rows[2].pts[1].pts = 140;
    score.rows[1].pts[0].pts = 257;
    score.rows[2].pts[0].pts = 257;
    score.rows[3].pts[0].pts = 140;

    final info = CoiffeurInfo(settings, score);

    expectHints(info, [
      Hint.winWithMatch('Team 1', factor: 1),
      Hint.matchNotLose('Team 2', factor: 4),
      Hint.pointsNotLoseOther('Team 2', pts: 149),
    ]);
    expectNoWinner(info);
  });

  test('two teams lost', () {
    settings.rows = 4;
    score.setSettings(settings);

    score.rows[0].pts[0].pts = 80;
    score.rows[0].pts[1].pts = 70;
    score.rows[1].pts[0].pts = 257;
    score.rows[1].pts[1].pts = 65;
    score.rows[3].pts[0].pts = 257;
    score.rows[3].pts[1].pts = 67;

    final info = CoiffeurInfo(settings, score);
    expect(info.result[1].max, lessThan(info.result[0].min));

    expectHints(info, [
      Hint.lost('Team 2', pts: 285),
    ]);
    expectWinner(info, [0], [1]);
  });

  test('two teams match 157', () {
    settings.match = 157;
    settings.rows = 3;
    score.setSettings(settings);

    score.rows[0].pts[0].pts = 80;
    score.rows[0].pts[1].pts = 70;
    score.rows[1].pts[1].pts = 130;
    score.rows[2].pts[1].pts = 70;

    final info = CoiffeurInfo(settings, score);
    expect(info.result[0].pts, 80);
    expect(info.result[1].pts, 540);

    expectHints(info, [
      Hint.winPoints('Team 1', pts: 92),
      Hint.winWithMatch('Team 1', factor: 3),
    ]);
    expectNoWinner(info);
  });

  test('two teams match 200', () {
    settings.match = 200;
    settings.rows = 4;
    score.setSettings(settings);

    score.rows[1].pts[0].pts = 75;
    score.rows[2].pts[0].pts = 50;
    score.rows[0].pts[1].pts = 40;
    score.rows[2].pts[1].pts = 80;
    score.rows[3].pts[1].pts = 80;

    final info = CoiffeurInfo(settings, score);
    expect(info.result[0].pts, 300);
    expect(info.result[1].pts, 600);

    expectHints(info, [
      Hint.winPoints('Team 1', pts: 140),
      Hint.winWithMatch('Team 1', factor: 4),
    ]);
    expectNoWinner(info);
  });

  test('two teams bonus 500', () {
    settings.bonus = true;
    settings.match = 157;
    settings.rows = 3;
    score.setSettings(settings);

    score.rows[0].pts[0].pts = 80;
    score.rows[0].pts[1].pts = 70;
    score.rows[2].pts[1].match = true;

    final info = CoiffeurInfo(settings, score);
    expect(info.result[0].max, 80 + 5 * 157 + 1000);
    expect(info.result[0].min, 80 - 200);
    expect(info.result[1].pts, 70 + 3 * 157 + 500);

    expectHints(info, [
      Hint.matchNotLose('Team 1', factor: 2),
      Hint.pointsNotLoseOther('Team 1', pts: 49),
    ]);
    expectNoWinner(info);
  });

  test('two teams bonus 50', () {
    settings.bonus = true;
    settings.bonusValue = 50;
    settings.match = 157;
    settings.rows = 4;
    score.setSettings(settings);

    score.rows[1].pts[1].pts = 85;
    score.rows[2].pts[0].pts = 80;
    score.rows[2].pts[1].pts = 110;
    score.rows[3].pts[0].pts = 140;

    final info = CoiffeurInfo(settings, score);
    expect(info.result[0].pts, 800);
    expect(info.result[1].pts, 500);

    expectHints(info, [
      Hint.pointsNotLose('Team 2', pts: 60),
    ]);
    expectNoWinner(info);
  });

  test('two teams bonus', () {
    settings.bonus = true;
    settings.bonusValue = 50;
    settings.match = 157;
    settings.rows = 4;
    score.setSettings(settings);

    score.rows[0].pts[1].scratch();
    score.rows[1].pts[1].pts = 85;
    score.rows[2].pts[0].pts = 80;
    score.rows[2].pts[1].pts = 110;
    score.rows[3].pts[0].pts = 140;

    final info = CoiffeurInfo(settings, score);
    expect(info.result[0].pts, 800);
    expect(info.result[1].pts, 500);

    expectHints(info, [
      Hint.winPoints('Team 1', pts: 126),
      Hint.pointsNotLose('Team 2', pts: 75),
    ]);
    expectNoWinner(info);
  });

  test('two teams bonus win with counter match', () {
    settings.bonus = true;
    settings.match = 157;
    settings.rows = 3;
    score.setSettings(settings);

    score.rows[0].pts[0].pts = 80;
    score.rows[1].pts[0].pts = 80;
    score.rows[2].pts[0].pts = 60;
    score.rows[0].pts[1].pts = 130;
    score.rows[1].pts[1].pts = 150;

    final info = CoiffeurInfo(settings, score);
    expect(info.result[0].pts, lessThan(info.result[1].pts));
    expect(info.result[0].pts, greaterThan(info.result[1].min));

    expectHints(info, [
      Hint.counterMatch('Team 1'),
      Hint.winPointsSingle('Team 2', pts: 0, factor: 3),
    ]);
    expectNoWinner(info);
  });

  test('three teams lost not lose win', () {
    settings.threeTeams = true;
    settings.rows = 3;
    score.setSettings(settings);

    score.rows[0].pts[0].pts = 55;
    score.rows[0].pts[1].pts = 9;
    score.rows[0].pts[2].pts = 150;
    score.rows[2].pts[0].pts = 50;
    score.rows[2].pts[1].pts = 257;
    score.rows[2].pts[2].pts = 257;

    final info = CoiffeurInfo(settings, score);
    expect(info.result[0].max,
        lessThan(max(info.result[1].min, info.result[2].min)));

    expectHints(info, [
      Hint.lost('Team 1', pts: 258),
      Hint.pointsNotLose('Team 2', pts: 71),
      Hint.winWithMatch('Team 3', factor: 2),
    ]);
    expectWinner(info, [], [0]);
  });

  test('three teams counter match needed', () {
    settings.threeTeams = true;
    settings.rows = 4;
    score.setSettings(settings);

    score.rows[0].pts[0].pts = 100;
    score.rows[1].pts[2].pts = 114;
    score.rows[2].pts[0].pts = 70;
    score.rows[2].pts[1].pts = 64;
    score.rows[2].pts[2].pts = 257;
    score.rows[3].pts[0].scratch();
    score.rows[3].pts[1].pts = 152;

    final info = CoiffeurInfo(settings, score);
    expect(info.result[0].pts, 310);
    expect(info.result[1].pts, 800);
    expect(info.result[2].pts, 999);

    expectHints(info, [
      Hint.counterMatch('Team 1'),
      Hint.matchNotLose('Team 1', factor: 2),
      Hint.pointsNotLose('Team 2', pts: 67),
      Hint.winPoints('Team 3', pts: 115),
      Hint.winWithMatch('Team 3', factor: 4),
    ]);
    expectNoWinner(info);
  });

  test('two teams lost can win rounded', () {
    settings.rows = 3;
    score.setSettings(settings);

    score.rows[0].pts[0].pts = 75;
    score.rows[2].pts[0].pts = 75;
    score.rows[0].pts[1].pts = 145;
    score.rows[1].pts[1].pts = 104;
    score.rows[2].pts[1].pts = 154;

    final info = CoiffeurInfo(settings, score);
    expect(info.result[0].max, lessThan(info.result[1].pts));
    expectHints(info, [
      Hint.lost('Team 1', pts: 258),
    ]);
    expectWinner(info, [1], [0]);

    settings.rounded = true;
    score.setSettings(settings);
    final infoRounded = CoiffeurInfo(settings, score);
    expect(infoRounded.result[0].max, greaterThan(infoRounded.result[1].pts));

    expectHints(infoRounded, [
      Hint.winWithMatch('Team 1', factor: 2),
    ]);
    expectNoWinner(infoRounded);
  });

  test('two teams rounded win with counter match', () {
    settings.rounded = true;
    settings.rows = 2;
    score.setSettings(settings);

    score.rows[0].pts[0].pts = 257;
    score.rows[0].pts[1].pts = 70;
    score.rows[1].pts[1].pts = 90;

    final info = CoiffeurInfo(settings, score);
    expect(info.result[0].pts, greaterThan(info.result[1].pts));
    expect(info.result[0].min, lessThan(info.result[1].pts));

    expectHints(info, [
      Hint.winPointsSingle('Team 1', pts: 0, factor: 2),
      Hint.counterMatch('Team 2'),
    ]);
    expectNoWinner(info);
  });

  test('two teams rounded lost when counter 0', () {
    settings.rounded = true;
    settings.counterLoss = 0;
    settings.rows = 2;
    score.setSettings(settings);

    score.rows[0].pts[0].pts = 257;
    score.rows[0].pts[1].pts = 70;
    score.rows[1].pts[1].pts = 90;

    final info = CoiffeurInfo(settings, score);
    expect(info.result[0].pts, greaterThan(info.result[1].pts));
    expect(info.result[0].min, greaterThan(info.result[1].pts));

    expectHints(info, []);
    expectWinner(info, [0], [1]);
  });

  test('two teams rounded bonus win with match', () {
    settings.rounded = true;
    settings.bonus = true;
    settings.match = 157;
    settings.rows = 2;
    score.setSettings(settings);

    score.rows[1].pts[0].pts = 64;
    score.rows[0].pts[1].pts = 131;
    score.rows[1].pts[1].pts = 76;

    final info = CoiffeurInfo(settings, score);
    expect(info.result[0].pts + 16, lessThan(info.result[1].pts));

    expectHints(info, [
      Hint.winWithMatch('Team 1', factor: 1),
    ]);
    expectNoWinner(info);
  });

  test('two teams bonus win with match 2', () {
    settings.rounded = true;
    settings.bonus = true;
    settings.bonusValue = 100;
    settings.match = 157;
    settings.rows = 3;
    score.setSettings(settings);

    score.rows[0].pts[0].pts = 142;
    score.rows[1].pts[0].match = true;
    score.rows[2].pts[0].pts = 114;
    score.rows[1].pts[1].pts = 96;

    final info = CoiffeurInfo(settings, score);
    // can win
    expect(info.result[0].pts, lessThan(info.result[1].max));
    // can not win without match
    expect(info.result[0].pts, greaterThan(info.result[1].pts + 4 * 16));
    // can win with one match
    expect(info.result[0].pts, lessThan(info.result[1].pts + 4 * 16 + 10));

    expectHints(info, [
      Hint.matchNotLose('Team 2', factor: 1),
      Hint.pointsNotLoseOther('Team 2', pts: 15),
    ]);
    expectNoWinner(info);
  });

  test('two teams bonus win with 2 matches', () {
    settings.bonus = true;
    settings.match = 157;
    settings.rows = 4;
    score.setSettings(settings);

    score.rows[0].pts[0].pts = 80;
    score.rows[0].pts[1].match = true;
    score.rows[1].pts[1].pts = 121;
    score.rows[2].pts[1].match = true;
    score.rows[3].pts[1].pts = 141;

    final info = CoiffeurInfo(settings, score);
    // can win
    expect(info.result[0].max, greaterThan(info.result[1].pts));
    // can not win without match
    expect(info.result[0].pts + info.result[0].open.sum * 157,
        lessThan(info.result[1].pts));
    // can not win with one match
    expect(info.result[0].pts + info.result[0].open.sum * 157 + 500,
        lessThan(info.result[1].pts));
    // can win with two matches
    expect(info.result[0].pts + info.result[0].open.sum * 157 + 1000,
        greaterThan(info.result[1].pts));

    expectHints(info, [
      Hint.matchNotLose('Team 1', factor: 4),
      Hint.matchNotLose('Team 1', factor: 2),
      Hint.pointsNotLoseOther('Team 1', pts: 138),
    ]);
    expectNoWinner(info);
  });

  test('two teams requires 2 matches', () {
    settings.rows = 11;
    score.setSettings(settings);

    score.rows[0].pts[0].scratch();
    score.rows[0].pts[1].scratch();
    score.rows[1].pts[0].pts = 87;
    score.rows[1].pts[1].pts = 126;
    score.rows[2].pts[0].pts = 110;
    score.rows[2].pts[1].pts = 65;
    score.rows[3].pts[0].pts = 120;
    score.rows[3].pts[1].pts = 123;
    score.rows[4].pts[0].pts = 79;
    score.rows[4].pts[1].pts = 74;
    //score.rows[5].pts[0].pts;
    score.rows[5].pts[1].pts = 92;
    score.rows[6].pts[0].pts = 97;
    score.rows[6].pts[1].pts = 257;
    score.rows[7].pts[0].pts = 138;
    score.rows[7].pts[1].pts = 113;
    score.rows[8].pts[0].pts = 143;
    score.rows[8].pts[1].pts = 257;
    //score.rows[9].pts[0].pts;
    score.rows[9].pts[1].pts = 140;
    score.rows[10].pts[0].pts = 140;
    score.rows[10].pts[1].pts = 123;

    final info = CoiffeurInfo(settings, score);
    // can win
    expect(info.result[0].max, greaterThan(info.result[1].pts));

    expectHints(info, [
      Hint.winPoints('Team 1', pts: 228),
    ]);
    expectNoWinner(info);
  });
}
