import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/schlaeger/screens/schlaeger_settings_screen.dart';
import 'package:jasstafel/settings/schlaeger_settings.g.dart';
import 'package:json_annotation/json_annotation.dart';
part 'schlaeger_score.g.dart';

@JsonSerializable()
class SchlaegerRound {
  factory SchlaegerRound.fromJson(Map<String, dynamic> json) =>
      _$SchlaegerRoundFromJson(json);
  Map<String, dynamic> toJson() => _$SchlaegerRoundToJson(this);

  List<int?> pts = List.filled(SchlaegerPlayers.max, null);

  SchlaegerRound(this.pts) {
    for (var i = pts.length; i < SchlaegerPlayers.max; i++) {
      pts.add(null);
    }
  }
}

@JsonSerializable()
class SchlaegerScore implements Score {
  @override
  Map<String, dynamic> toJson() => _$SchlaegerScoreToJson(this);
  factory SchlaegerScore.fromJson(Map<String, dynamic> json) =>
      _$SchlaegerScoreFromJson(json);
  SchlaegerSettings _settings = SchlaegerSettings();
  void setSettings(settings) => _settings = settings;

  var playerName =
      List.generate(SchlaegerPlayers.max, (i) => "Spieler ${i + 1}");
  var rows = <SchlaegerRound>[];

  SchlaegerScore();

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
      int best = -10000;
      for (var i = 0; i < _settings.players; i++) {
        final playerPoints = total(i);
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
    return [];
  }

  int total(int player) {
    var p = 0;
    for (final row in rows) {
      p += roundedInt(row.pts[player] ?? 0, false);
    }
    return p;
  }
}
