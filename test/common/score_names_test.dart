import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/coiffeur/data/coiffeur_score.dart';
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
import 'package:jasstafel/settings/schlaeger_settings.g.dart';
import 'package:test/test.dart';

void main() {
  test('schieber names the teams', () {
    final score = SchieberScore();
    score.team[0].name = 'Wir';
    score.team[1].name = 'Ihr';
    score.add(157, 0);
    score.add(60, 97);

    expect(score.names(), ['Wir', 'Ihr']);
    expect(score.totals(), [217, 97]);
  });

  test('coiffeur names two or three teams', () {
    final score = CoiffeurScore();
    final settings = CoiffeurSettings();
    score.setSettings(settings);
    score.rows[0].pts[0].pts = 57;
    score.rows[1].pts[1].pts = 100;
    score.rows[1].pts[2].pts = 30;

    expect(score.names(), ['Team 1', 'Team 2']);
    expect(score.totals(), [57, 200]);

    settings.threeTeams = true;
    expect(score.names(), ['Team 1', 'Team 2', 'Team 3']);
    expect(score.totals(), [57, 200, 60]);
  });

  test('an empty differenzler has no rounds', () {
    final score = DifferenzlerScore();
    score.setSettings(DifferenzlerSettings()..players = 3);
    expect(score.noOfRounds(), 0);
    expect(score.totals(), [0, 0, 0]);
  });

  test('the list boards name the players in play', () {
    final molotow = MolotowScore();
    molotow.setSettings(MolotowSettings()..players = 3);
    molotow.rows.add(MolotowRow([10, 20, 30, 40], isRound: true));
    expect(molotow.names(), ['Spieler 1', 'Spieler 2', 'Spieler 3']);
    expect(molotow.totals(), [10, 20, 30]);

    final pointBoard = PointBoardScore();
    pointBoard.setSettings(PointBoardSettings()..players = 2);
    pointBoard.rows.add(PointBoardRow([5, 7, 9]));
    expect(pointBoard.names(), ['Spieler 1', 'Spieler 2']);
    expect(pointBoard.totals(), [5, 7]);

    final differenzler = DifferenzlerScore();
    differenzler.setSettings(DifferenzlerSettings()..players = 2);
    differenzler.rows.add(
      DifferenzlerRow()
        ..guesses[1] = 40
        ..pts[1] = 52,
    );
    expect(differenzler.names().length, 2);
    expect(differenzler.totals(), [0, 12]);

    final guggitaler = GuggitalerScore();
    guggitaler.setSettings(GuggitalerSettings()..players = 2);
    guggitaler.rows.add(GuggitalerRow()..domino[0] = 15);
    expect(guggitaler.names().length, 2);
    expect(guggitaler.totals(), [15, 0]);

    final schlaeger = SchlaegerScore();
    schlaeger.setSettings(SchlaegerSettings()..players = 3);
    schlaeger.rows.add(SchlaegerRound([1, 2, 3, 4]));
    expect(schlaeger.names().length, 3);
    expect(schlaeger.totals(), [1, 2, 3]);
  });

  test('the weis of each team or player, as details', () {
    final schieber = SchieberScore();
    schieber.add(157, 0);
    schieber.add(50, 0, weis: true);
    schieber.add(0, 100, weis: true);
    expect(schieber.details(), {
      'weis': [50, 100],
    });

    final molotow = MolotowScore();
    molotow.setSettings(MolotowSettings()..players = 3);
    molotow.rows.add(MolotowRow([10, 20, 30, 40], isRound: true));
    molotow.rows.add(MolotowRow([-20, null, 50], isRound: false));
    molotow.rows.add(MolotowRow([null, 20], isRound: false));
    expect(molotow.details(), {
      'handWeis': [-20, 0, 0],
      'tableWeis': [0, 20, 50],
    });

    expect(CoiffeurScore().details(), isEmpty);
    expect(PointBoardScore().details(), isEmpty);
  });

  test('the leaders are those ahead, none while all are level', () {
    final names = ['A', 'B', 'C'];
    expect(leadersOf(names, [10, 30, 30]), ['B', 'C']);
    expect(leadersOf(names, [10, 30, 20], fewest: true), ['A']);
    expect(leadersOf(names, [5, 5, 5]), isEmpty);
    expect(leadersOf(names, []), isEmpty);
  });
}
