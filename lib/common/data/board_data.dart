import 'package:jasstafel/common/data/common_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SpecificData {
  void reset();
  void restore(List<String> data);
  String dump();
  int rounds();
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
    String str = commonData.dump();
    str += data.dump();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(dataKey, str);
  }

  Future<BoardData> load() async {
    var s = await SharedPreferences.getInstance();

    var str = s.getString(dataKey);
    if (str != null && str.isNotEmpty) {
      var d = str.split(';');
      d.removeLast();

      commonData.restore(d[0]);
      data.restore(d.sublist(1));
    }
    return this;
  }
}
