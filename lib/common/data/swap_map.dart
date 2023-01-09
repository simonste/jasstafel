import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:jasstafel/common/data/common_data.dart';
import 'package:jasstafel/common/widgets/who_is_next_widget.dart';

class SwapMap {
  final WhoIsNextData _data;
  List _list;
  int? selected; // index of _list

  // arrange order
  // 1 2
  // 3 4
  //
  // play order
  // 1 4
  // 2 3

  SwapMap.simple(List<String> pl)
      : _data = WhoIsNextData(pl, 0, WhoIsNext(), () {}),
        _list = _defaultList(pl.length);

  SwapMap(this._data) : _list = _defaultList(_data.players.length) {
    try {
      _list = json.decode(_data.whoIsNext.swapPlayers).cast<int>();
    } catch (e) {
      _list = _defaultList(_data.players.length);
    }
    if (_list.length != _data.players.length) {
      _list = _defaultList(_data.players.length);
    }
    if (_data.whoIsNext.whoBeginsOffset != null) {
      var selectedPlayer = (_data.rounds + _data.whoIsNext.whoBeginsOffset!) %
          _data.players.length;
      selected = _defaultList(_data.players.length).indexOf(selectedPlayer);
    }
  }

  List<String> _reorder() {
    List<String> newList = List.from(_data.players);

    for (var i = 0; i < _data.players.length; i++) {
      newList[i] = _data.players[_list[i]];
    }
    return newList;
  }

  Map<Key, Widget> get() {
    var newList = _reorder();

    Map<Key, Widget> map = {};
    for (var i = 0; i < _data.players.length; i++) {
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

  void _save() {
    if (selected == null) {
      _data.whoIsNext.whoBeginsOffset = null;
    } else {
      var selectedPlayer = _defaultList(_data.players.length)[selected!];
      var roundOffset = selectedPlayer - _data.rounds;
      _data.whoIsNext.whoBeginsOffset = roundOffset;
    }
    _data.whoIsNext.swapPlayers = _list.toString();
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
