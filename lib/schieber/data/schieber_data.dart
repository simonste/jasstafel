import 'dart:math';

import 'package:jasstafel/common/data/commondata.dart';
import 'package:jasstafel/settings/schieber_settings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeamData {
  String name = "Team";
  int points = 0;

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

class SchieberData {
  var commonData = CommonData();
  var settings = SchieberSettings();
  var team = [TeamData(), TeamData()];

  SchieberData() {
    // assert(settings.rows <= rows.length);
  }

  void reset() {
    for (var t = 0; t < team.length; t++) {
      for (var s = 0; s < team[t].strokes.length; s++) {
        team[t].strokes[s] = 0;
      }
    }
  }

  @override
  String toString() {
    String str = commonData.toString();
    str += settings.toString();
    str += "${team[0]},${team[1]};";
    return str;
  }

  void fromString(String? str) {
    if (str != null) {
      var data = str.split(';');
      data.removeLast();

      commonData.fromString(data[0]);
      settings.fromString(data[1]);
      // var tn = data[2].split(',');
      // for (var i = 0; i < team.length; i++) {
      //   team[i] = tn[i];
      // }
    }
  }

  void save() async {
    String data = toString();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(SchieberSettings.keys.data, data);
  }

  Future<SchieberData> load() async {
    var s = await SharedPreferences.getInstance();
    fromString(s.getString(SchieberSettings.keys.data));
    return this;
  }

  int rounds() {
    return 0;
  }
}
