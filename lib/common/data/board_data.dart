import 'package:jasstafel/common/data/common_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

String joinA(List<dynamic> args) {
  return args.join(";");
}

List<String> splitA(String str) {
  return str.split(";");
}

String joinB(List<dynamic> args) {
  return args.join("|");
}

List<String> splitB(String str) {
  return str.split("|");
}

String joinC(List<dynamic> args) {
  return args.join(",");
}

List<String> splitC(String str) {
  return str.split(",");
}

abstract class SpecificData {
  void reset();
  void restoreHeader(List<String> data);
  List<dynamic> dumpHeader();
  void restoreScore(List<List<String>> data);
  List<ScoreRow> dumpScore();
  int rounds();
}

abstract class ScoreRow {
  void restore(List<String> data);
  List<dynamic> dump();
}

class BoardData<T extends SpecificData> {
  final String dataKey;
  final T data;
  final commonData = CommonData();

  BoardData(this.data, this.dataKey);

  void reset() {
    commonData.reset();
    data.reset();
    save();
  }

  void save() async {
    String str = joinA([joinB(commonData.dump()), joinB(data.dumpHeader())]);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(dataKey, str);

    var score =
        data.dumpScore().map((element) => joinC(element.dump())).toList();
    await preferences.setStringList("${dataKey}_score", score);
  }

  Future<BoardData> load() async {
    var s = await SharedPreferences.getInstance();

    var str = s.getString(dataKey);
    if (str != null && str.isNotEmpty) {
      var d = splitA(str);
      commonData.restore(splitB(d[0]));
      data.restoreHeader(splitB(d[1]));
    }
    var rounds = s.getStringList("${dataKey}_score") ?? [];
    var splitRounds = rounds.map((e) => splitC(e)).toList();
    data.restoreScore(splitRounds);
    return this;
  }
}
