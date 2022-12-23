import 'dart:math';

import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/settings/schieber_settings.g.dart';

class TeamData {
  String name;
  int points = 0;

  TeamData([this.name = "Team"]);

  final values = [1, 20, 50, 100, 500];
  var strokes = List.filled(5, 0);

  @override
  String toString() {
    String str = "$name,";
    for (var stroke in strokes) {
      str += "$stroke,";
    }
    return str;
  }

  void fromString(String str) {
    var values = str.split(',');
    name = values[0];
    for (var i = 0; i < strokes.length; i++) {
      try {
        strokes[i] = int.parse(values[i + 1]);
      } on FormatException {
        strokes[i] = 0;
      }
    }
  }

  int sum() {
    var sum = 0;
    for (var i = 0; i < values.length; i++) {
      sum += strokes[i] * values[i];
    }
    return sum;
  }

  void add(int points) {
    int remainingPoints = points + strokes[0];
    final int sign = (remainingPoints < 0) ? -1 : 1;

    for (int i = 4; i > 0; i--) {
      int tmp = sign * remainingPoints ~/ values[i];
      if (sign == -1) {
        tmp = min(tmp, strokes[i]);
      }
      strokes[i] += sign * tmp;
      remainingPoints -= sign * tmp * values[i];
    }
    strokes[0] = remainingPoints;
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
  }
}

class SchieberData implements SpecificData {
  var settings = SchieberSettings();
  var team = [TeamData("Team 1"), TeamData("Team 2")];

  SchieberData();
  @override
  void reset() {
    for (var t = 0; t < team.length; t++) {
      for (var s = 0; s < team[t].strokes.length; s++) {
        team[t].strokes[s] = 0;
      }
    }
  }

  @override
  String dump() {
    return "${team[0]};${team[1]};";
  }

  @override
  void restore(List<String> data) {
    for (var i = 0; i < team.length; i++) {
      team[i].fromString(data[i]);
    }
  }

  @override
  int rounds() {
    return 0;
  }
}
