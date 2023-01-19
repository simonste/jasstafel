import 'package:jasstafel/coiffeur/data/coiffeur_score.dart';
import 'package:jasstafel/settings/coiffeur_settings.g.dart';
import 'package:test/test.dart';

void main() {
  test('count rows', () {
    var score = CoiffeurScore();
    var settings = CoiffeurSettings();

    score.rows[0].pts[1] = 57;
    score.rows[2].pts[0] = 100;
    score.rows[4].pts[0] = 60;
    expect(score.noOfRounds(), 3);

    score.rows[2].pts[2] = 100;
    expect(score.noOfRounds(), 3); // ignore 3rd team

    score.rows[12].pts[0] = 55;
    expect(score.noOfRounds(), 3); // ignore hidden row

    settings.rows = 13;
    score.setSettings(settings);
    expect(score.noOfRounds(), 4);

    settings.threeTeams = true;
    score.setSettings(settings);
    expect(score.noOfRounds(), 5);
  });

  test('sum points', () {
    var score = CoiffeurScore();

    score.rows[0].pts[1] = 57;
    score.rows[2].pts[0] = 100;
    score.rows[4].pts[0] = 60;

    expect(score.total(0), 3 * 100 + 5 * 60);
    expect(score.total(1), 57);
  });

  test('row diff', () {
    var score = CoiffeurScore();

    score.rows[0].pts[1] = 57;
    score.rows[2].pts[0] = 100;
    score.rows[2].pts[1] = 60;

    expect(score.diff(2), 3 * 40);

    score.rows[2].pts[1] = 111;
    expect(score.diff(2), 3 * -11);
  });

  test('rounded', () {
    var score = CoiffeurScore();
    var settings = CoiffeurSettings();
    settings.rounded = true;
    score.setSettings(settings);

    score.rows[0].pts[1] = 57;
    score.rows[2].pts[0] = 105;
    score.rows[2].pts[1] = 60;

    expect(score.diff(2), 3 * 5);

    score.rows[2].pts[1] = 112;
    expect(score.diff(2), 0);
  });

  test('bonus', () {
    var score = CoiffeurScore();
    var settings = CoiffeurSettings();
    settings.match = 257;
    settings.bonus = true;
    settings.bonusValue = 500;
    score.setSettings(settings);

    score.rows[0].pts[0] = 60;
    score.rows[0].pts[1] = 88;
    score.rows[2].pts[0] = 257;
    score.rows[2].pts[1] = 60;

    expect(score.points(2, 0), 257);
    expect(score.match(2, 0), true);
    expect(score.diff(2), 3 * 97 + 500);
    expect(score.total(0), 60 + 3 * 157 + 500);
    expect(score.total(2), -28 + 3 * 97 + 500);
  });

  test('bonus rounded', () {
    var score = CoiffeurScore();
    var settings = CoiffeurSettings();
    settings.match = 257;
    settings.bonus = true;
    settings.bonusValue = 300;
    settings.rounded = true;
    score.setSettings(settings);

    score.rows[0].pts[0] = 60;
    score.rows[0].pts[1] = 88;
    score.rows[2].pts[0] = 257;
    score.rows[2].pts[1] = 60;

    expect(score.points(2, 0), 26);
    expect(score.match(2, 0), true);
    expect(score.diff(2), 3 * 10 + 30);
    expect(score.total(0), 6 + 3 * 16 + 30);
    expect(score.total(2), -3 + 3 * 10 + 30);
  });

  test('scratch', () {
    var score = CoiffeurScore();
    score.rows[0].pts[0] = 60;
    score.rows[2].pts[1] = 60;
    score.rows[2].scratch(0);

    expect(score.noOfRounds(), 3);
    expect(score.total(0), 60);
    expect(score.diff(2), -3 * 60);
  });
}
