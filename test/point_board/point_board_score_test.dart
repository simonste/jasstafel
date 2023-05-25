import 'package:jasstafel/point_board/data/point_board_score.dart';
import 'package:jasstafel/settings/point_board_settings.g.dart';
import 'package:test/test.dart';

void main() {
  test('count rows', () {
    var score = PointBoardScore();

    score.rows.add(PointBoardRow([null, 10, 0]));
    score.rows.add(PointBoardRow([44, 33, 55, 25]));
    score.rows.add(PointBoardRow([null, null, 20]));

    expect(score.noOfRounds(), 3);
  });

  test('count points', () {
    var score = PointBoardScore();

    score.rows.add(PointBoardRow([]));
    score.rows.add(PointBoardRow([]));
    score.rows.add(PointBoardRow([5]));

    expect(score.total(0), 5);
  });

  test('count points rounded', () {
    var score = PointBoardScore();
    var settings = PointBoardSettings();
    settings.rounded = true;
    score.setSettings(settings);

    score.rows.add(PointBoardRow([]));
    score.rows.add(PointBoardRow([]));
    score.rows.add(PointBoardRow([54]));

    expect(score.total(0), 5);
  });

  test('check winner points', () {
    var score = PointBoardScore();
    var settings = PointBoardSettings();
    settings.players = 3;
    settings.goalType = 1;
    settings.goalPoints = 100;
    score.setSettings(settings);

    score.rows.add(PointBoardRow([10, 50, 10]));
    score.rows.add(PointBoardRow([54, 60, 20]));

    expect(score.winner(), ["Spieler 2"]);
  });

  test('check two winner points', () {
    var score = PointBoardScore();
    var settings = PointBoardSettings();
    settings.players = 3;
    settings.goalType = 1;
    settings.goalPoints = 100;
    score.setSettings(settings);

    score.rows.add(PointBoardRow([10, 50, 10]));
    score.rows.add(PointBoardRow([54, 60, 100]));

    expect(score.winner(), ["Spieler 2", "Spieler 3"]);
  });

  test('check winner points minimum', () {
    var score = PointBoardScore();
    var settings = PointBoardSettings();
    settings.players = 3;
    settings.goalType = 1;
    settings.goalPoints = 100;
    settings.goalMax = false;
    score.setSettings(settings);

    score.rows.add(PointBoardRow([10, 50, 10]));
    score.rows.add(PointBoardRow([54, 60, 20]));

    expect(score.winner(), ["Spieler 3"]);
  });

  test('check winner rounds', () {
    var score = PointBoardScore();
    var settings = PointBoardSettings();
    settings.players = 3;
    settings.goalType = 2;
    settings.goalRounds = 3;
    score.setSettings(settings);

    score.rows.add(PointBoardRow([10, 50, 10]));
    score.rows.add(PointBoardRow([54, 60, 20]));

    expect(score.winner(), []);

    score.rows.add(PointBoardRow([74, 10, 20]));

    expect(score.winner(), ["Spieler 1"]);
  });
}
