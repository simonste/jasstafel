import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/settings/point_board_settings.g.dart';
import 'package:json_annotation/json_annotation.dart';
part 'point_board_score.g.dart';

@JsonSerializable()
class PointBoardRow {
  factory PointBoardRow.fromJson(Map<String, dynamic> json) =>
      _$PointBoardRowFromJson(json);
  Map<String, dynamic> toJson() => _$PointBoardRowToJson(this);

  List<int?> pts = List.filled(Players.max, null);

  PointBoardRow(this.pts) {
    for (var i = pts.length; i < Players.max; i++) {
      pts.add(null);
    }
  }
}

@JsonSerializable()
class PointBoardScore implements Score {
  @override
  Map<String, dynamic> toJson() => _$PointBoardScoreToJson(this);
  factory PointBoardScore.fromJson(Map<String, dynamic> json) =>
      _$PointBoardScoreFromJson(json);
  PointBoardSettings _settings = PointBoardSettings();
  void setSettings(settings) => _settings = settings;

  var playerName = List.generate(Players.max, (i) => "Spieler ${i + 1}");
  var rows = <PointBoardRow>[];

  PointBoardScore();

  @override
  int noOfRounds() {
    return rows.length;
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
      final factor = _settings.goalMax ? 1 : -1;
      int best = -10000;
      for (var i = 0; i < _settings.players; i++) {
        final playerPoints = factor * total(i);
        if (playerPoints > best) {
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
    if (_settings.goalType == GoalType.points.index &&
        !_settings.goalMax &&
        winner().isNotEmpty) {
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
}
