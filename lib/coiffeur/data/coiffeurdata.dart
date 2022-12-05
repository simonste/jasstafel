import 'package:flutter/material.dart';
import 'package:jasstafel/common/data/commondata.dart';
import 'package:jasstafel/common/settings_keys.dart';
import 'package:pref/pref.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoiffeurSettings {
  int rows = 11;
  bool threeTeams = false;
  bool thirdColumn = true;
  bool rounded = false;
  bool customFactor = false;
  int? bonus;

  @override
  String toString() {
    return "$rows,$threeTeams,$thirdColumn,$rounded,$customFactor,$bonus;";
  }

  void fromString(String str) {
    var values = str.split(',');
    rows = int.parse(values[0]);
    threeTeams = values[1] == "true";
    thirdColumn = values[2] == "true";
    rounded = values[3] == "true";
    customFactor = values[4] == "true";
    try {
      bonus = int.parse(values[5]);
    } on FormatException {
      bonus = null;
    }
  }

  void toPrefService(BuildContext context) {
    var pref = PrefService.of(context);
    pref.set(Keys.coiffeurRows, rows);
    pref.set(Keys.coiffeur3Teams, threeTeams);
    pref.set(Keys.coiffeurThirdColumn, thirdColumn);
    pref.set(Keys.coiffeurRows, rows);
    pref.set(Keys.coiffeurCustomFactor, customFactor);
  }

  void fromPrefService(BuildContext context) {
    var pref = PrefService.of(context);

    //var s3 = pref.toMap();

    rows = pref.get(Keys.coiffeurRows);
    threeTeams = pref.get(Keys.coiffeur3Teams);
    thirdColumn = pref.get(Keys.coiffeurThirdColumn);
    customFactor = pref.get(Keys.coiffeurCustomFactor);
  }
}

class RowSettings {
  int factor;
  String type;
  List<int?> pts = List.filled(3, null);

  RowSettings(this.factor, this.type);

  @override
  String toString() {
    String str = "$factor,$type,";
    for (var pt in pts) {
      str += "$pt,";
    }
    return str;
  }

  void fromString(String str) {
    var values = str.split(',');
    factor = int.parse(values[0]);
    type = values[1];

    for (var i = 0; i < pts.length; i++) {
      try {
        pts[i] = int.parse(values[i + 2]);
      } on FormatException {
        pts[i] = null;
      }
    }
  }

  void reset() {
    for (var i = 0; i < pts.length; i++) {
      pts[i] = null;
    }
  }
}

class CoiffeurData {
  var commonData = CommonData();
  var settings = CoiffeurSettings();
  List<String> teamName = ["Team 1", "Team 2", "Team 3"];
  var rows = List.filled(13, RowSettings(1, "Wunsch"));

  CoiffeurData() {
    assert(settings.rows <= rows.length);

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

  int total(team) {
    assert(team < 3);
    int sum = 0;
    for (var row in rows) {
      if (row.pts[team] != null) {
        sum += row.factor * row.pts[team]!;
      } else if (team == 2 &&
          !settings.threeTeams &&
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

  int _rowDiff(row) {
    return row.factor * (row.pts[0]! - row.pts[1]!);
  }

  int rounds() {
    int rounds = 0;
    for (var row in rows) {
      for (var team in row.pts) {
        if (team != null) rounds++;
      }
    }
    return rounds;
  }

  @override
  String toString() {
    String str = commonData.toString();
    str += settings.toString();
    str += "${teamName[0]},${teamName[1]},${teamName[2]};";
    for (var row in rows) {
      str += "$row;";
    }
    return str;
  }

  void fromString(String? str) {
    if (str != null) {
      var data = str.split(';');
      data.removeLast();

      commonData.fromString(data[0]);
      settings.fromString(data[1]);
      var tn = data[2].split(',');
      for (var i = 0; i < teamName.length; i++) {
        teamName[i] = tn[i];
      }
      for (var i = 0; i < rows.length; i++) {
        rows[i].fromString(data[i + 3]);
      }
    }
  }

  void save() async {
    String data = toString();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(Keys.coiffeur, data);
  }

  Future<CoiffeurData> load() async {
    var s = await SharedPreferences.getInstance();
    fromString(s.getString(Keys.coiffeur));
    return this;
  }
}
