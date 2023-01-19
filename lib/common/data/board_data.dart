import 'dart:convert';

import 'package:jasstafel/coiffeur/data/coiffeur_score.dart';
import 'package:jasstafel/common/data/common_data.dart';
import 'package:jasstafel/schieber/data/schieber_score.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class Score {
  Map<String, dynamic> toJson();

  void reset(int? duration);
  int noOfRounds();
}

class BoardData<T, S extends Score> {
  final String dataKey;
  T settings;
  S score;
  var common = CommonData();

  BoardData(this.settings, this.score, this.dataKey);

  Future<BoardData> load() async {
    final preferences = await SharedPreferences.getInstance();
    final str = preferences.getString(dataKey) ?? "{}";
    if (str.length <= 2) {
      return this;
    }

    Map<String, dynamic> json = jsonDecode(str);
    if (json.containsKey('common')) {
      common = CommonData.fromJson(json['common']);
      json.remove('common');
    }

    if (S is SchieberScore || S.toString() == "SchieberScore") {
      score = SchieberScore.fromJson(json) as S;
    } else if (S.toString() == "CoiffeurScore") {
      score = CoiffeurScore.fromJson(json) as S;
    } else {
      assert(false);
    }

    return this;
  }

  void save() async {
    final preferences = await SharedPreferences.getInstance();

    var json = score.toJson();
    json['common'] = common.toJson();
    final str = jsonEncode(json);
    await preferences.setString(dataKey, str);
  }

  void reset() {
    score.reset(common.timestamps.duration());
    common.reset();
    save();
  }
}
