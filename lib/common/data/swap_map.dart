import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SwapMap {
  final List<String> _players;
  int rounds = 0;
  List _list;
  int? selected; // index of _list

  // arrange order
  // 1 2
  // 3 4
  //
  // play order
  // 1 4
  // 2 3

  SwapMap(this._players) : _list = _defaultList(_players.length);

  List<String> _reorder() {
    List<String> newList = List.from(_players);

    for (var i = 0; i < _players.length; i++) {
      newList[i] = _players[_list[i]];
    }
    return newList;
  }

  Map<Key, Widget> get() {
    var newList = _reorder();

    Map<Key, Widget> map = {};
    for (var i = 0; i < _players.length; i++) {
      map.putIfAbsent(
          Key("${_list[i]}"),
          () => Text(newList[i],
              style: TextStyle(
                  color: (i == selected) ? Colors.blue : Colors.white)));
    }
    return map;
  }

  void select(Key key) {
    var selectedId = int.tryParse(key.toString()[3]);
    selected = _list.indexOf(selectedId);
    _save();
  }

  void set(List<int> list) {
    if (selected != null) {
      int selectedId = _list[selected!];
      selected = list.indexOf(selectedId);
    }
    _list = list;
    _save();
  }

  Future<void> _save() async {
    final preferences = await SharedPreferences.getInstance();
    if (selected == null) {
      preferences.remove("RoundOffset");
    } else {
      var selectedPlayer = _defaultList(_players.length)[selected!];
      var roundOffset = selectedPlayer - rounds;
      preferences.setInt("RoundOffset", roundOffset);
    }
    preferences.setString("SwapPlayers", _list.toString());
  }

  Future<void> restore(int rounds) async {
    this.rounds = rounds;
    final preferences = await SharedPreferences.getInstance();
    var swap = preferences.getString("SwapPlayers") ?? "";
    try {
      _list = json.decode(swap).cast<int>();
    } catch (e) {
      _list = _defaultList(_players.length);
    }
    if (_list.length != _players.length) {
      _list = _defaultList(_players.length);
    }
    final roundOffset = preferences.getInt("RoundOffset");
    if (roundOffset != null) {
      var selectedPlayer = (rounds + roundOffset) % _players.length;
      selected = _defaultList(_players.length).indexOf(selectedPlayer);
    }
  }

  static List _defaultList(players) {
    switch (players) {
      case 3:
        return [0, 2, 1];
      case 4:
        return [0, 3, 1, 2];
      case 5:
        return [0, 4, 1, 3, 2];
      case 6:
        return [0, 5, 1, 4, 2, 3];
      case 7:
        return [0, 6, 1, 5, 2, 4, 3];
      case 8:
        return [0, 7, 1, 6, 2, 5, 3, 4];
      default:
        return List.generate(players, (i) => i);
    }
  }
}
