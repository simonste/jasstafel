import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/settings/differenzler_settings.g.dart';
import 'package:json_annotation/json_annotation.dart';
part 'differenzler_score.g.dart';

@JsonSerializable()
class DifferenzlerRow {
  factory DifferenzlerRow.fromJson(Map<String, dynamic> json) =>
      _$DifferenzlerRowFromJson(json);
  Map<String, dynamic> toJson() => _$DifferenzlerRowToJson(this);

  List<int?> guesses = List.filled(Players.max, null);
  List<int?> pts = List.filled(Players.max, null);

  DifferenzlerRow();

  bool isGuessed(int players) {
    for (var i = 0; i < players; i++) {
      if (guesses[i] == null) {
        return false;
      }
    }
    return true;
  }

  int diff(int player) {
    if (guesses[player] == null) {
      return 0;
    }

    if (pts[player] != null) {
      return (pts[player]! - guesses[player]!).abs();
    }
    return 0;
  }

  int guessed() {
    var total = 0;
    for (var guess in guesses) {
      total += guess ?? 0;
    }
    return total;
  }

  int made() {
    var total = 0;
    for (var pt in pts) {
      total += pt ?? 0;
    }
    return total;
  }
}

@JsonSerializable()
class DifferenzlerScore implements Score {
  @override
  Map<String, dynamic> toJson() => _$DifferenzlerScoreToJson(this);
  factory DifferenzlerScore.fromJson(Map<String, dynamic> json) =>
      _$DifferenzlerScoreFromJson(json);
  DifferenzlerSettings _settings = DifferenzlerSettings();
  void setSettings(settings) => _settings = settings;

  var playerName = List.generate(Players.max, (i) => "Spieler ${i + 1}");
  var rows = <DifferenzlerRow>[];

  DifferenzlerScore();

  @override
  int noOfRounds() {
    var n = rows.length - 1;
    for (var p in rows.last.pts) {
      if (p != null) {
        n++;
        break;
      }
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
    var total = 0;
    for (final row in rows) {
      total += row.diff(player);
    }
    return total;
  }
}
