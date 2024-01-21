import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:jasstafel/common/data/common_data.dart';
import 'package:jasstafel/common/widgets/who_is_next_widget.dart';

// arrange order
// 1 2        1 2 3
// 3 4        4 5 6
//
// play order
// 1 4        1 6 5
// 2 3        2 3 4

class PlayerId {
  // do not mix up index in play order and arrange order
  final int id;

  PlayerId(this.id);

  @override
  bool operator ==(other) => (other is PlayerId && id == other.id);

  @override
  int get hashCode => id * 42;

  @override
  String toString() {
    return "Pid=$id";
  }

  factory PlayerId.fromJson(Map<String, dynamic> json) {
    String string = json as String;
    return PlayerId(int.tryParse(string[4])!);
  }
}

class SwapMap {
  final WhoIsNextData _data;
  List<PlayerId> _playOrder;
  PlayerId? _selectedPlayer;

  SwapMap.simple(List<String> pl)
      : _data = WhoIsNextData(pl, 0, WhoIsNext(), () {}),
        _playOrder = List.generate(pl.length, (i) => PlayerId(i));

  SwapMap(this._data)
      : _playOrder = List.generate(_data.players.length, (i) => PlayerId(i)) {
    try {
      List<int> restoredPlayOrder =
          json.decode(_data.whoIsNext.swapPlayers).cast<int>();
      if (restoredPlayOrder.length == _data.players.length) {
        _playOrder = restoredPlayOrder.map((e) => PlayerId(e)).toList();
      }
    } catch (e) {
      // use default
    }
    if (_data.whoIsNext.whoBeginsOffset != null) {
      final progress = (_data.rounds + _data.whoIsNext.whoBeginsOffset!) %
          _data.players.length;
      _selectedPlayer = _playOrder[progress];
    }
  }

  Map<int, Widget> get({bool landscape = false}) {
    final arrangeOrder = _arrangeOrder(_data.players.length, landscape);

    Map<int, Widget> map = {};
    for (var i = 0; i < _data.players.length; i++) {
      final arrangeId = _playOrder[arrangeOrder[i]].id;
      final playerName = _data.players[arrangeId];

      map.putIfAbsent(
          _playOrder[arrangeOrder[i]].id,
          () => Text(playerName,
              style: TextStyle(
                  color: (_selectedPlayer != null &&
                          arrangeId == _selectedPlayer!.id)
                      ? Colors.blue
                      : Colors.white)));
    }
    return map;
  }

  void select(PlayerId player) {
    _selectedPlayer = player;
    _save();
  }

  void swap(PlayerId player1, PlayerId player2) {
    final i1 = _playOrder.indexOf(player1);
    final i2 = _playOrder.indexOf(player2);

    final tmp = _playOrder[i1];
    _playOrder[i1] = _playOrder[i2];
    _playOrder[i2] = tmp;
    _save();
  }

  void _save() {
    if (_selectedPlayer == null) {
      _data.whoIsNext.whoBeginsOffset = null;
    } else {
      var roundOffset = _playOrder.indexOf(_selectedPlayer!) - _data.rounds;
      _data.whoIsNext.whoBeginsOffset = roundOffset;
    }

    _data.whoIsNext.swapPlayers =
        _playOrder.map((e) => e.id).toList().toString();
    _data.saveFunction();
  }

  static List _arrangeOrder(players, bool landscape) {
    switch (players) {
      case 3:
        return [0, 2, 1];
      case 4:
        return [0, 3, 1, 2];
      case 5:
        if (landscape) {
          return [0, 4, 3, 1, 2];
        } else {
          return [0, 4, 1, 3, 2];
        }
      case 6:
        if (landscape) {
          return [0, 5, 4, 1, 2, 3];
        } else {
          return [0, 5, 1, 4, 2, 3];
        }
      case 7:
        if (landscape) {
          return [0, 6, 5, 4, 1, 2, 3];
        } else {
          return [0, 6, 1, 5, 2, 4, 3];
        }
      case 8:
        if (landscape) {
          return [0, 7, 6, 5, 1, 2, 3, 4];
        } else {
          return [0, 7, 1, 6, 2, 5, 3, 4];
        }
      default:
        return List.generate(players, (i) => i);
    }
  }
}
