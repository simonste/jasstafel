import 'dart:convert';

import 'package:jasstafel/common/data/common_data.dart';
import 'package:test/test.dart';

void main() {
  test('a new game gets a new id', () {
    final common = CommonData();
    final id = common.gameId;
    expect(id.length, 12);
    expect(CommonData().gameId, isNot(id));

    common.reset();
    expect(common.gameId, isNot(id));
  });

  test('the id survives saving and loading', () {
    final common = CommonData();
    final json = jsonDecode(jsonEncode(common.toJson()));
    expect(CommonData.fromJson(json).gameId, common.gameId);
  });

  test('a game saved without an id gets one', () {
    final json = jsonDecode(jsonEncode(CommonData().toJson()));
    json.remove('gameId');
    expect(CommonData.fromJson(json).gameId.length, 12);
  });
}
