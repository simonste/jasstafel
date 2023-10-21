import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/settings/molotow_settings.g.dart';
import 'package:json_annotation/json_annotation.dart';
part 'molotow_score.g.dart';

@JsonSerializable()
class MolotowRow {
  factory MolotowRow.fromJson(Map<String, dynamic> json) =>
      _$MolotowRowFromJson(json);
  Map<String, dynamic> toJson() => _$MolotowRowToJson(this);

  bool isRound;
  List<int?> pts = List.filled(Players.max, null);

  MolotowRow(this.pts, {required this.isRound}) {
    for (var i = pts.length; i < Players.max; i++) {
      pts.add(null);
    }
  }
}

@JsonSerializable()
class MolotowScore implements Score {
  @override
  Map<String, dynamic> toJson() => _$MolotowScoreToJson(this);
  factory MolotowScore.fromJson(Map<String, dynamic> json) =>
      _$MolotowScoreFromJson(json);
  MolotowSettings _settings = MolotowSettings();
  void setSettings(settings) => _settings = settings;

  var playerName = List.generate(Players.max, (i) => "Spieler ${i + 1}");
  var rows = <MolotowRow>[];

  MolotowScore();

  @override
  int noOfRounds() {
    var n = 0;
    for (final row in rows) {
      if (row.isRound) n++;
    }
    return n;
  }

  @override
  void reset(int? duration) {
    rows.clear();
  }

  @override
  void setWinner(String team) {}

  @override
  int totalPoints() {
    var p = 0;
    for (var i = 0; i < _settings.players; i++) {
      p += total(i);
    }
    return p;
  }

  @override
  List<String> winner() {
    List<String> winners = [];
    bool gameOver = false;
    if (_settings.goalType == GoalType.points.index) {
      for (var i = 0; i < _settings.players; i++) {
        if (total(i) >= _settings.goalPoints) gameOver = true;
      }
    }
    if (_settings.goalType == GoalType.rounds.index &&
        noOfRounds() == _settings.goalRounds) {
      gameOver = true;
    }
    if (gameOver) {
      int best = 10000;
      for (var i = 0; i < _settings.players; i++) {
        final playerPoints = total(i);
        if (playerPoints < best) {
          winners = [playerName[i]];
          best = playerPoints;
        } else if (playerPoints == best) {
          winners.add(playerName[i]);
        }
      }
    }
    return winners;
  }

  @override
  List<String> loser() {
    if (_settings.goalType == GoalType.points.index && winner().isNotEmpty) {
      List<String> losers = [];
      int worst = -10000;
      for (var i = 0; i < _settings.players; i++) {
        final playerPoints = total(i);
        if (playerPoints > worst) {
          losers = [playerName[i]];
          worst = playerPoints;
        } else if (playerPoints == worst) {
          losers.add(playerName[i]);
        }
      }
      return losers;
    }
    return [];
  }

  int total(int player) {
    var p = 0;
    for (final row in rows) {
      p += roundedInt(row.pts[player] ?? 0, _settings.rounded);
    }
    return p;
  }

  int handWeis(int player) {
    var p = 0;
    for (final row in rows) {
      if (!row.isRound && (row.pts[player] ?? 0) < 0) {
        p += roundedInt(row.pts[player] ?? 0, _settings.rounded);
      }
    }
    return p;
  }

  int tableWeis(int player) {
    var p = 0;
    for (final row in rows) {
      if (!row.isRound && (row.pts[player] ?? 0) > 0) {
        p += roundedInt(row.pts[player] ?? 0, _settings.rounded);
      }
    }
    return p;
  }
}
