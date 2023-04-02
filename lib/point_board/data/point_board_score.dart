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

  bool isRound;
  List<int?> pts = List.filled(8, null);

  PointBoardRow(this.pts, {required this.isRound}) {
    for (var i = pts.length; i < 8; i++) {
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

  List<String> playerName = [
    "Spieler 1",
    "Spieler 2",
    "Spieler 3",
    "Spieler 4",
    "Spieler 5",
    "Spieler 6",
    "Spieler 7",
    "Spieler 8"
  ];
  var rows = <PointBoardRow>[];

  PointBoardScore();

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
