import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/settings/schieber_settings.g.dart';
import 'package:json_annotation/json_annotation.dart';
part 'schieber_score.g.dart';

@JsonSerializable()
class SchieberRound {
  Map<String, dynamic> toJson() => _$SchieberRoundToJson(this);
  factory SchieberRound.fromJson(Map<String, dynamic> json) =>
      _$SchieberRoundFromJson(json);

  DateTime time = DateTime.now();
  var pts = [0, 0];

  SchieberRound(this.pts);

  int _total() {
    return pts[0] + pts[1];
  }

  bool isRound(int matchPoints) {
    return (_total() % roundPoints(matchPoints) == 0 ||
        (pts[0] == 0 || pts[1] == 0) && (_total() % matchPoints == 0));
  }
}

@JsonSerializable()
class TeamData {
  Map<String, dynamic> toJson() => _$TeamDataToJson(this);
  factory TeamData.fromJson(Map<String, dynamic> json) =>
      _$TeamDataFromJson(json);

  String name;
  bool flip = false;
  bool? hill;

  TeamData([this.name = "Team"]);

  final values = [1, 20, 50, 100, 500];
  var strokes = List.filled(5, 0);

  int sum() {
    var sum = 0;
    for (var i = 0; i < values.length; i++) {
      sum += strokes[i] * values[i];
    }
    return sum;
  }

  void add(int points) {
    int remainingPoints = points + strokes[0];

    for (int i = 4; i > 0; i--) {
      final strokeValue = values[i];
      int tmp = remainingPoints ~/ strokeValue;
      if (remainingPoints < 0 && strokes[i] > tmp.abs()) {
        // remove 'bigger' stroke and add singles afterwards
        tmp = (remainingPoints - 5) ~/ strokeValue;
      }
      strokes[i] += tmp;
      remainingPoints -= tmp * strokeValue;
    }
    strokes[0] = remainingPoints;

    checkOverflow();
  }

  void checkOverflow() {
    if (strokes[1] > 24) {
      strokes[1] -= 5;
      strokes[3] += 1;
    }
    if (strokes[2] > 13) {
      strokes[2] -= 2;
      strokes[3] += 1;
    }
    if (strokes[3] > 19) {
      strokes[3] -= 5;
      strokes[4] += 1;
    }
    if (strokes[0] < -19) {
      strokes[0] += 20;
      strokes[1] -= 1;
    }
    if (strokes[1] < 0) {
      strokes[0] += 10;
      strokes[1] += 2;
      strokes[2] -= 1;
      if (strokes[2] < 0) {
        strokes[2] += 2;
        strokes[3] -= 1;
        if (strokes[3] < 0) {
          strokes[3] += 5;
          strokes[4] -= 1;
        }
      }
    }
  }
}

@JsonSerializable()
class TeamStatistics {
  Map<String, dynamic> toJson() => _$TeamStatisticsToJson(this);
  factory TeamStatistics.fromJson(Map<String, dynamic> json) =>
      _$TeamStatisticsFromJson(json);

  TeamStatistics();

  int wins = 0;
  int hills = 0;
  int weis = 0;
  int matches = 0;
  int pts = 0;
}

@JsonSerializable()
class SchieberStatistics {
  Map<String, dynamic> toJson() => _$SchieberStatisticsToJson(this);
  factory SchieberStatistics.fromJson(Map<String, dynamic> json) =>
      _$SchieberStatisticsFromJson(json);

  SchieberStatistics();

  var team = [TeamStatistics(), TeamStatistics()];
  int duration = 0;
}

@JsonSerializable()
class SchieberBacksideData {
  Map<String, dynamic> toJson() => _$SchieberBacksideDataToJson(this);
  factory SchieberBacksideData.fromJson(Map<String, dynamic> json) =>
      _$SchieberBacksideDataFromJson(json);

  SchieberBacksideData();

  String name = "";
  int strokes = 0;
}

@JsonSerializable()
class SchieberScore implements Score {
  @override
  Map<String, dynamic> toJson() => _$SchieberScoreToJson(this);
  factory SchieberScore.fromJson(Map<String, dynamic> json) =>
      _$SchieberScoreFromJson(json);
  SchieberSettings _settings = SchieberSettings();
  void setSettings(settings) => _settings = settings;

  var team = [TeamData("Team 1"), TeamData("Team 2")];
  List<SchieberRound> rounds = [];

  var statistics = SchieberStatistics();
  var backside = List.filled(6, SchieberBacksideData());

  SchieberScore();

  @override
  void reset(int? duration) {
    statistics.duration += duration ?? 0;
    for (var t = 0; t < team.length; t++) {
      statistics.team[t].pts += team[t].sum();
    }

    for (var t = 0; t < team.length; t++) {
      for (var s = 0; s < team[t].strokes.length; s++) {
        team[t].strokes[s] = 0;
      }
    }
    rounds.clear();
  }

  void add(pts1, pts2) {
    final round = SchieberRound([pts1, pts2]);
    rounds.add(round);
    team[0].add(pts1);
    team[1].add(pts2);

    if (team[0].hill == null || team[1].hill == null) {
      if (team[0].sum() > _settings.goalPoints / 2) {
        team[0].hill = true;
        team[1].hill = false;
      }
      if (team[1].sum() > _settings.goalPoints / 2) {
        team[0].hill = false;
        team[1].hill = true;
      }
    }
  }

  List<SchieberRound> getHistory() {
    return rounds;
  }

  void undo() {
    rounds.removeLast();

    team = [TeamData("Team 1"), TeamData("Team 2")];
    for (var round in rounds) {
      for (var i = 0; i < team.length; i++) {
        team[i].add(round.pts[i]);
      }
    }
  }

  @override
  int noOfRounds() {
    int noOfRounds = 0;
    for (var round in rounds) {
      if (round.isRound(_settings.match)) {
        noOfRounds++;
      }
    }
    return noOfRounds;
  }
}
