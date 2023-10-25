import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/guggitaler/data/guggitaler_values.dart';
import 'package:jasstafel/settings/guggitaler_settings.g.dart';
import 'package:json_annotation/json_annotation.dart';
part 'guggitaler_score.g.dart';

@JsonSerializable()
class GuggitalerRow {
  factory GuggitalerRow.fromJson(Map<String, dynamic> json) =>
      _$GuggitalerRowFromJson(json);
  Map<String, dynamic> toJson() => _$GuggitalerRowToJson(this);

  List<List<int?>> pts = List.generate(
      Players.max, (i) => List.filled(GuggitalerValues.length, null));

  GuggitalerRow();

  int sum(int player) {
    int sum = 0;
    for (var i = 0; i < GuggitalerValues.length; i++) {
      sum += (pts[player][i] ?? 0) * GuggitalerValues.points(i);
    }
    return sum;
  }

  bool isRound() {
    for (var i = 0; i < GuggitalerValues.length; i++) {
      int a = 0;
      for (var p = 0; p < Players.max; p++) {
        a += pts[p][i] ?? 0;
      }
      if (a.abs() == GuggitalerValues.maxPerRound(i)) {
        return true;
      }
    }
    return false;
  }
}

@JsonSerializable()
class GuggitalerScore implements Score {
  @override
  Map<String, dynamic> toJson() => _$GuggitalerScoreToJson(this);
  factory GuggitalerScore.fromJson(Map<String, dynamic> json) =>
      _$GuggitalerScoreFromJson(json);
  GuggitalerSettings _settings = GuggitalerSettings();
  void setSettings(settings) => _settings = settings;

  var playerName = List.generate(Players.max, (i) => "Spieler ${i + 1}");
  var rows = <GuggitalerRow>[];

  GuggitalerScore();

  @override
  int noOfRounds() {
    int count = 0;
    for (var element in rows) {
      if (element.isRound()) {
        count++;
      }
    }
    return count;
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
    return [];
  }

  @override
  List<String> loser() {
    return [];
  }

  int total(int player) {
    var p = 0;
    for (final row in rows) {
      p += row.sum(player);
    }
    return p;
  }

  int columnSum(int player, int column) {
    var p = 0;
    for (final row in rows) {
      p += row.pts[player][column] ?? 0;
    }
    return p;
  }
}
