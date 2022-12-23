import 'package:flutter/material.dart';
import 'package:jasstafel/common/data/commondata.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class BoardData {
  final String dataKey;

  var commonData = CommonData();

  BoardData(this.dataKey);

  String dump();

  void restore(List<String> data);

  @mustCallSuper
  void reset() {
    commonData.reset();
    save();
  }

  void save() async {
    String str = commonData.dump();
    str += dump();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(dataKey, str);
  }

  Future<BoardData> load() async {
    var s = await SharedPreferences.getInstance();

    var str = s.getString(dataKey);
    if (str != null) {
      var d = str.split(';');
      d.removeLast();

      commonData.restore(d[0]);
      restore(d.sublist(1));
    }
    return this;
  }
}
