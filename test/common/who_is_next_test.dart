import 'package:jasstafel/common/widgets/who_is_next_button.dart';
import 'package:test/test.dart';

void main() {
  var split = WhoIsNextButton.splitTeamName;
  var guess = WhoIsNextButton.guessPlayerNames;

  test('split team name', () {
    expect(split("Max Matthew"), ['Max', 'Matthew']);
    expect(split(" Max &  Matthew"), ['Max', 'Matthew']);
    expect(split("Max / Matthew "), ['Max', 'Matthew']);
    expect(split("Max Matthew Marc"), ['Max', 'Matthew', 'Marc']);
    expect(split("Max Matthew Marc", limit: 2), ['Max', 'Matthew Marc']);
  });

  test('2 teams spaces', () {
    final players = guess(["Max Matthew", "Peter Paul"]);

    expect(players.length, 4);
    expect(players[0], "Max");
    expect(players[1], "Peter");
    expect(players[2], "Matthew");
    expect(players[3], "Paul");
  });

  test('3 teams spaces', () {
    final players = guess(["Max Matthew", "Peter Paul", "Bonnie Clyde"]);

    expect(players.length, 6);
    expect(players[0], "Max");
    expect(players[1], "Peter");
    expect(players[2], "Bonnie");
    expect(players[3], "Matthew");
    expect(players[4], "Paul");
    expect(players[5], "Clyde");
  });

  test('2 teams ampersand', () {
    final players = guess(["Max & Matthew", "Peter&Paul"]);

    expect(players.length, 4);
    expect(players[0], "Max");
    expect(players[1], "Peter");
    expect(players[2], "Matthew");
    expect(players[3], "Paul");
  });

  test('2 teams minus', () {
    final players = guess(["Max-Matthew", "Peter - Paul"]);

    expect(players.length, 4);
    expect(players[0], "Max");
    expect(players[1], "Peter");
    expect(players[2], "Matthew");
    expect(players[3], "Paul");
  });

  test('2 teams slash', () {
    final players = guess(["Max/Matthew", "Peter / Paul"]);

    expect(players.length, 4);
    expect(players[0], "Max");
    expect(players[1], "Peter");
    expect(players[2], "Matthew");
    expect(players[3], "Paul");
  });

  test('2 teams teamNameShort', () {
    final players = guess(["Smith", "Miller"]);

    expect(players.length, 4);
    expect(players[0], "Smith 1");
    expect(players[1], "Miller 1");
    expect(players[2], "Smith 2");
    expect(players[3], "Miller 2");
  });

  test('2 teams teamNameLong', () {
    final players = guess(["Team blue", "Team red"]);

    expect(players.length, 4);
    expect(players[0], "Team blue 1");
    expect(players[1], "Team red 1");
    expect(players[2], "Team blue 2");
    expect(players[3], "Team red 2");
  });

  test('2 teams teamName number', () {
    final players = guess(["Team 88", "Team 85"]);

    expect(players.length, 4);
    expect(players[0], "Team 88a");
    expect(players[1], "Team 85a");
    expect(players[2], "Team 88b");
    expect(players[3], "Team 85b");
  });

  test('2 teams spaces', () {
    final players = guess([" Max Matthew", "Peter Paul "]);

    expect(players.length, 4);
    expect(players[0], "Max");
    expect(players[1], "Peter");
    expect(players[2], "Matthew");
    expect(players[3], "Paul");
  });

  test('2 teams double name', () {
    final players = guess(["Max A - Matthew B", "Peter K & Paul S"]);

    expect(players.length, 4);
    expect(players[0], "Max A");
    expect(players[1], "Peter K");
    expect(players[2], "Matthew B");
    expect(players[3], "Paul S");
  });

  test('2 teams 3 players each', () {
    final players = guess(["Max Matthew Marc", "Peter Paul Pius"]);

    expect(players.length, 6);
    expect(players[0], "Max");
    expect(players[1], "Peter");
    expect(players[2], "Matthew");
    expect(players[3], "Paul");
    expect(players[4], "Marc");
    expect(players[5], "Pius");
  });

  test('2 teams different number of players', () {
    final players = guess(["Max S Matthew", "Peter Paul"]);

    expect(players.length, 4);
    expect(players[0], "Max");
    expect(players[1], "Peter");
    expect(players[2], "S Matthew");
    expect(players[3], "Paul");
  });

  test('empty names', () {
    final players = guess(["", ""]);

    expect(players.length, 4);
    expect(players[0], "P1");
    expect(players[1], "P2");
    expect(players[2], "P3");
    expect(players[3], "P4");
  });

  test('bad names', () {
    final players = guess(["---", "&&&"]);

    expect(players.length, 4);
    expect(players[0], "--- 1");
    expect(players[1], "&&& 1");
    expect(players[2], "--- 2");
    expect(players[3], "&&& 2");
  });

  test('different separations', () {
    final players = guess(["Al i-Bro", "X Y Z"]);

    expect(players.length, 4);
    expect(players[0], "Al i");
    expect(players[1], "X");
    expect(players[2], "Bro");
    expect(players[3], "Y Z");
  });

  test('3 names', () {
    final players = guess(["Al i Bro", "X Y Z"]);

    expect(players.length, 6);
    expect(players[0], "Al");
    expect(players[1], "X");
    expect(players[2], "i");
    expect(players[3], "Y");
    expect(players[4], "Bro");
    expect(players[5], "Z");
  });

  test('3 names spaces', () {
    final players = guess(["Al & i + Bro", "X - Y - Z"]);

    expect(players.length, 6);
    expect(players[0], "Al");
    expect(players[1], "X");
    expect(players[2], "i");
    expect(players[3], "Y");
    expect(players[4], "Bro");
    expect(players[5], "Z");
  });

  test('2 names spaces', () {
    final players = guess(["Al B - Bro", "Al X - Z"]);

    expect(players.length, 4);
    expect(players[0], "Al B");
    expect(players[1], "Al X");
    expect(players[2], "Bro");
    expect(players[3], "Z");
  });
}
