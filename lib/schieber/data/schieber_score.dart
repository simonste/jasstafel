import 'package:flutter/material.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/dialog/winner_dialog.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/settings/schieber_settings.g.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:collection/collection.dart';
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
  int goalPoints = 2500;
  bool? hill;
  bool? win;
  bool flip = false;

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

  void reset() {
    team = [TeamStatistics(), TeamStatistics()];
    duration = 0;
  }

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
  int goalRounds = 8;
  List<SchieberRound> rounds = [];

  var statistics = SchieberStatistics();
  var backside = List.filled(6, SchieberBacksideData());

  SchieberScore();

  @override
  void reset(int? duration) {
    statistics.duration += duration ?? 0;
    final match = matches();
    final weis = weisPoints();
    for (var t = 0; t < team.length; t++) {
      statistics.team[t].pts += team[t].sum();
      statistics.team[t].matches += match[t];
      statistics.team[t].weis += weis[t];
      if (team[t].hill == true) {
        statistics.team[t].hills++;
      }
      if (team[t].win == true) {
        statistics.team[t].wins++;
      }
    }

    for (var t = 0; t < team.length; t++) {
      for (var s = 0; s < team[t].strokes.length; s++) {
        team[t].strokes[s] = 0;
        team[t].hill = null;
        team[t].win = null;
      }
    }
    rounds.clear();
  }

  void add(pts1, pts2) {
    final round = SchieberRound([pts1, pts2]);
    rounds.add(round);
    team[0].add(pts1);
    team[1].add(pts2);
  }

  List<SchieberRound> getHistory() {
    return rounds;
  }

  List<SchieberRound> _consolidateRounds() {
    SchieberRound? previousRound;

    List<SchieberRound> consRounds = [];

    List<int> ptsBuffer = [0, 0];
    for (var round in rounds) {
      final bufferContainsRound = (ptsBuffer.sum > 0 &&
          ((ptsBuffer.sum % _settings.match == 0) ||
              (ptsBuffer.sum % roundPoints(_settings.match)) == 0));
      final previousPointsLongAgo = (previousRound != null &&
          round.time.difference(previousRound.time).inSeconds.abs() > 5);
      final currentIsRound = (ptsBuffer.sum > 0 &&
          ((round._total() % _settings.match == 0) ||
              (round._total() % roundPoints(_settings.match)) == 0));

      if (bufferContainsRound || previousPointsLongAgo || currentIsRound) {
        consRounds.add(SchieberRound(ptsBuffer));
        ptsBuffer = [0, 0];
      }
      ptsBuffer[0] += round.pts[0];
      ptsBuffer[1] += round.pts[1];
      previousRound = round;
    }
    if (previousRound != null) {
      consRounds.add(SchieberRound(ptsBuffer));
    }

    return consRounds;
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
    for (var round in _consolidateRounds()) {
      if (round.isRound(_settings.match)) {
        noOfRounds++;
      }
    }
    return noOfRounds;
  }

  List<int> matches() {
    var matches = [0, 0];
    for (var round in _consolidateRounds()) {
      if (round.isRound(_settings.match)) {
        for (var i = 0; i < team.length; i++) {
          var other = (i + 1) % 2;
          if (round.pts[other] == 0) {
            matches[i]++;
          }
        }
      }
    }
    return matches;
  }

  List<int> weisPoints() {
    var weisPts = [0, 0];
    for (var round in _consolidateRounds()) {
      if (!round.isRound(_settings.match)) {
        for (var i = 0; i < team.length; i++) {
          if (round.pts[i] % 20 == 0 || round.pts[i] % 50 == 0) {
            weisPts[i] += round.pts[i];
          }
        }
      }
    }
    return weisPts;
  }

  @override
  List<String> winner() {
    List<String> winners = [];

    for (final t in team) {
      if (t.win ?? false) {
        winners.add(t.name);
      }
    }
    // if winners already known
    if (winners.isNotEmpty) return winners;

    if (_settings.goalTypePoints) {
      for (final t in team) {
        if (t.sum() > t.goalPoints) {
          winners.add(t.name);
          t.win = true;
        }
      }
    } else {
      if (noOfRounds() >= goalRounds) {
        for (final i in [0, 1]) {
          if (team[i].sum() >= team[(i + 1) % 2].sum()) {
            winners.add(team[i].name);
            team[i].win = true;
          }
        }
      }
    }
    return winners;
  }

  @override
  void setWinner(String teamName) {
    for (var t in team) {
      if (t.name != teamName) {
        t.win = false;
      }
    }
  }

  void checkHill(BuildContext context) {
    final hillers = passedHill();
    if (hillers.length == 2) {
      setHiller(String teamName) {
        for (var t in team) {
          if (t.name != teamName) {
            t.hill = false;
          }
        }
      }

      Future.delayed(
          Duration.zero,
          () => hillDialog(
              context: context,
              hillers: hillers,
              setHillerFunction: setHiller));
    }
  }

  List<String> passedHill() {
    for (final t in team) {
      if (t.hill ?? false) {
        return [];
      }
    }

    List<String> hillers = [];
    if (_settings.goalTypePoints) {
      for (final t in team) {
        if (t.sum() > t.goalPoints / 2) {
          hillers.add(t.name);
          t.hill = true;
        }
      }
    } else {
      if (noOfRounds() == (goalRounds / 2).ceil()) {
        for (final i in [0, 1]) {
          if (team[i].sum() >= team[(i + 1) % 2].sum()) {
            hillers.add(team[i].name);
            team[i].hill = true;
          }
        }
      }
    }
    if (hillers.isNotEmpty) {
      for (final t in team) {
        t.hill ??= false;
      }
    }
    return hillers;
  }
}
