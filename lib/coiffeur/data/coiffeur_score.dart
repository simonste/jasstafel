import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/settings/coiffeur_settings.g.dart';
import 'package:json_annotation/json_annotation.dart';
part 'coiffeur_score.g.dart';

@JsonSerializable()
class RowSettings {
  factory RowSettings.fromJson(Map<String, dynamic> json) =>
      _$RowSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$RowSettingsToJson(this);

  int factor;
  String type;
  List<int?> pts = List.filled(3, null);

  RowSettings(this.factor, this.type);

  void reset() {
    for (var i = 0; i < pts.length; i++) {
      pts[i] = null;
    }
  }

  bool scratched(int team) {
    return pts[team] == -3513;
  }

  void scratch(int team) {
    pts[team] = -3513;
  }
}

@JsonSerializable()
class CoiffeurScore implements Score {
  @override
  Map<String, dynamic> toJson() => _$CoiffeurScoreToJson(this);
  factory CoiffeurScore.fromJson(Map<String, dynamic> json) =>
      _$CoiffeurScoreFromJson(json);
  CoiffeurSettings _settings = CoiffeurSettings();
  void setSettings(settings) => _settings = settings;

  List<String> teamName = ["Team 1", "Team 2", "Team 3"];
  var rows = List.filled(13, RowSettings(1, "Wunsch"));

  CoiffeurScore() {
    rows[0] = (RowSettings(1, "Eicheln"));
    rows[1] = (RowSettings(2, "Schellen"));
    rows[2] = (RowSettings(3, "Rosen"));
    rows[3] = (RowSettings(4, "Schilten"));
    rows[4] = (RowSettings(5, "Obenabe"));
    rows[5] = (RowSettings(6, "Ondenufe"));
    rows[6] = (RowSettings(7, "Slalom"));
    rows[7] = (RowSettings(8, "Gusti"));
    rows[8] = (RowSettings(9, "Wunsch"));
    rows[9] = (RowSettings(10, "Wunsch"));
    rows[10] = (RowSettings(11, "Coiffeur"));
    rows[11] = (RowSettings(12, "Wunsch"));
    rows[12] = (RowSettings(13, "Wunsch"));
  }

  @override
  void reset(int? duration) {
    for (var row in rows) {
      row.reset();
    }
  }

  int total(team) {
    assert(team < 3);
    int sum = 0;
    for (var row in rows) {
      if (_pts(row, team) != null) {
        sum += row.factor * _pts(row, team)!;
        if (_settings.bonus && row.pts[team]! == _settings.match) {
          sum += _bonus(row.factor);
        }
      } else if (team == 2 &&
          !_settings.threeTeams &&
          row.pts[0] != null &&
          row.pts[1] != null) {
        sum += _rowDiff(row);
      }
    }
    return sum;
  }

  int? diff(i) {
    if (rows[i].pts[0] != null && rows[i].pts[1] != null) {
      return _rowDiff(rows[i]);
    }
    return null;
  }

  int? points(int rowNumber, int team) {
    return _pts(rows[rowNumber], team);
  }

  bool match(int rowNumber, int team) {
    return _settings.bonus && rows[rowNumber].pts[team] == _settings.match;
  }

  int _rowDiff(RowSettings row) {
    var diff = row.factor * (_pts(row, 0)! - _pts(row, 1)!);
    if (_settings.bonus) {
      if (row.pts[0] == _settings.match) {
        diff += _bonus(row.factor);
      }
      if (row.pts[1] == _settings.match) {
        diff -= _bonus(row.factor);
      }
    }
    return diff;
  }

  int _bonus(int factor) {
    if (_settings.bonus) {
      assert(_settings.match == 157);
      final bonus = _settings.bonusValue - 100 * factor;
      if (_settings.rounded) {
        return (bonus / 10).round();
      } else {
        return bonus;
      }
    }
    return 0;
  }

  int? _pts(RowSettings row, int team) {
    final pts = row.pts[team];
    if (row.scratched(team)) {
      return 0;
    }
    if (pts != null && _settings.rounded) {
      return (pts / 10).round();
    }
    return pts;
  }

  @override
  int noOfRounds() {
    int rounds = 0;
    var teams = _settings.threeTeams ? 3 : 2;
    for (var r = 0; r < _settings.rows; r++) {
      for (var t = 0; t < teams; t++) {
        if (rows[r].pts[t] != null) rounds++;
      }
    }
    return rounds;
  }
}
