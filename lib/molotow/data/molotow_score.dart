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
  List<int?> pts = List.filled(8, null);

  MolotowRow(this.pts, {required this.isRound}) {
    for (var i = pts.length; i < 8; i++) {
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
