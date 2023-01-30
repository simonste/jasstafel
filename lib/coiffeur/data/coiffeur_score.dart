import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/settings/coiffeur_settings.g.dart';
import 'package:json_annotation/json_annotation.dart';
part 'coiffeur_score.g.dart';

@JsonSerializable()
class CoiffeurPoints {
  factory CoiffeurPoints.fromJson(Map<String, dynamic> json) =>
      _$CoiffeurPointsFromJson(json);
  Map<String, dynamic> toJson() => _$CoiffeurPointsToJson(this);

  CoiffeurPoints();

  bool match = false;
  bool scratched = false;
  int? pts;

  void scratch() {
    scratched = true;
    match = false;
    pts = null;
  }

  bool empty() {
    return pts == null && scratched == false;
  }

  void reset() {
    match = false;
    scratched = false;
    pts = null;
  }
}

@JsonSerializable()
class RowSettings {
  factory RowSettings.fromJson(Map<String, dynamic> json) =>
      _$RowSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$RowSettingsToJson(this);

  int factor;
  String type;
  List<CoiffeurPoints> pts = [
    CoiffeurPoints(),
    CoiffeurPoints(),
    CoiffeurPoints()
  ];

  RowSettings(this.factor, this.type);

  void reset() {
    for (var i = 0; i < pts.length; i++) {
      pts[i].reset();
    }
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
    for (var i = 0; i < _settings.rows; i++) {
      final row = rows[i];
      if (team == 2 && !_settings.threeTeams) {
        if (row.pts[0].pts != null && row.pts[1].pts != null) {
          sum += _rowDiff(row);
        }
      } else if (_pts(row, team) != null) {
        sum += row.factor * _pts(row, team)!;
        if (_settings.bonus && row.pts[team].match) {
          sum += _bonus();
        }
      }
    }
    return sum;
  }

  int? diff(i) {
    if (!rows[i].pts[0].empty() && !rows[i].pts[1].empty()) {
      return _rowDiff(rows[i]);
    }
    return null;
  }

  CoiffeurPoints points(int rowNumber, int team) {
    var pts = CoiffeurPoints();
    pts.pts = _pts(rows[rowNumber], team);
    if (_settings.bonus) {
      // match is only relevant with bonus
      pts.match = rows[rowNumber].pts[team].match;
    }
    pts.scratched = rows[rowNumber].pts[team].scratched;
    return pts;
  }

  int _rowDiff(RowSettings row) {
    var diff = row.factor * (_pts(row, 0)! - _pts(row, 1)!);
    if (_settings.bonus) {
      if (row.pts[0].match) {
        diff += _bonus();
      }
      if (row.pts[1].match) {
        diff -= _bonus();
      }
    }
    return diff;
  }

  int _bonus() {
    if (_settings.bonus) {
      final bonus = _settings.bonusValue;
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
    if (pts.scratched) {
      return 0;
    }
    if (pts.match) {
      pts.pts = _settings.match;
    }
    if (pts.pts != null && _settings.rounded) {
      return (pts.pts! / 10).round();
    }
    return pts.pts;
  }

  @override
  int noOfRounds() {
    int rounds = 0;
    var teams = _settings.threeTeams ? 3 : 2;
    for (var r = 0; r < _settings.rows; r++) {
      for (var t = 0; t < teams; t++) {
        var pts = rows[r].pts[t];
        if (pts.pts != null || pts.scratched) rounds++;
      }
    }
    return rounds;
  }
}
