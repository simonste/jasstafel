import 'package:flutter/material.dart';
import 'package:jasstafel/common/data/common_data.dart';
import 'package:jasstafel/common/data/swap_map.dart';
import 'package:jasstafel/common/widgets/who_is_next_widget.dart';
import 'package:test/test.dart';

void main() {
  List map2list(Map map) {
    return map.values.map((e) => (e as Text).data).toList();
  }

  String? highlighted(Map map) {
    String? selected;
    map.forEach((key, value) {
      Text text = value as Text;
      if ((text.style as TextStyle).color != Colors.white) {
        selected = text.data;
      }
    });
    return selected;
  }

  test('default 3', () {
    var players = ['P1', 'P2', 'P3'];
    var sm = SwapMap.simple(players);

    expect(map2list(sm.get()), ['P1', 'P3', 'P2']);
    expect(highlighted(sm.get()), null);
  });

  test('default 4', () {
    var players = ['P1', 'P2', 'P3', 'P4'];
    var sm = SwapMap.simple(players);

    expect(map2list(sm.get()), ['P1', 'P4', 'P2', 'P3']);
    expect(highlighted(sm.get()), null);
  });

  test('default 5', () {
    var players = ['P1', 'P2', 'P3', 'P4', 'P5'];
    var sm = SwapMap.simple(players);

    expect(map2list(sm.get()), ['P1', 'P5', 'P2', 'P4', 'P3']);
    expect(highlighted(sm.get()), null);
  });

  test('default 6', () {
    var players = ['P1', 'P2', 'P3', 'P4', 'P5', 'P6'];
    var sm = SwapMap.simple(players);

    expect(map2list(sm.get()), ['P1', 'P6', 'P2', 'P5', 'P3', 'P4']);
    expect(highlighted(sm.get()), null);
  });
  test('default 7', () {
    var players = ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7'];
    var sm = SwapMap.simple(players);

    expect(map2list(sm.get()), ['P1', 'P7', 'P2', 'P6', 'P3', 'P5', 'P4']);
    expect(highlighted(sm.get()), null);
  });
  test('default 8', () {
    var players = ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8'];
    var sm = SwapMap.simple(players);

    expect(
        map2list(sm.get()), ['P1', 'P8', 'P2', 'P7', 'P3', 'P6', 'P4', 'P5']);
    expect(highlighted(sm.get()), null);
  });

  test('swap one', () {
    var players = ['P1', 'P2', 'P3', 'P4'];
    var sm = SwapMap.simple(players);

    sm.set([1, 0, 2, 3]);
    expect(map2list(sm.get()), ['P2', 'P1', 'P3', 'P4']);
  });

  test('swap two', () {
    var players = ['P1', 'P2', 'P3', 'P4'];
    var sm = SwapMap.simple(players);

    sm.set([1, 2, 0, 3]);
    expect(map2list(sm.get()), ['P2', 'P3', 'P1', 'P4']);
  });

  test('revert swap', () {
    var players = ['P1', 'P2', 'P3', 'P4'];
    var sm = SwapMap.simple(players);

    sm.set([0, 2, 1, 3]);
    sm.set([0, 1, 2, 3]);
    expect(map2list(sm.get()), ['P1', 'P2', 'P3', 'P4']);
  });

  test('save & restore', () async {
    var data = WhoIsNextData(['P1', 'P2', 'P3', 'P4'], 0, WhoIsNext(), () {});
    var sm = SwapMap(data);
    sm.set([1, 2, 0, 3]);

    var sm2 = SwapMap(data);
    expect(map2list(sm2.get()), ['P2', 'P3', 'P1', 'P4']);
    expect(highlighted(sm.get()), null);
  });

  test('select', () {
    var players = ['P1', 'P2', 'P3', 'P4'];
    var sm = SwapMap.simple(players);
    sm.set([0, 1, 2, 3]);
    sm.select(const Key("2"));
    expect(highlighted(sm.get()), 'P3');

    sm.set([1, 2, 0, 3]);
    expect(highlighted(sm.get()), 'P3');
  });

  test('save & restore selected', () async {
    var data = WhoIsNextData(['P1', 'P2', 'P3', 'P4'], 0, WhoIsNext(), () {});
    var sm = SwapMap(data);
    sm.select(const Key("1"));
    expect(highlighted(sm.get()), 'P2');

    var sm2 = SwapMap(data);
    expect(highlighted(sm2.get()), 'P2');
  });

  test('save & restore selected 2', () async {
    var data = WhoIsNextData(['P1', 'P2', 'P3', 'P4'], 0, WhoIsNext(), () {});
    var sm = SwapMap(data);
    sm.set([3, 0, 2, 1]);
    sm.select(const Key("2"));
    expect(highlighted(sm.get()), 'P3');

    data.rounds = 1;
    var sm2 = SwapMap(data);
    expect(highlighted(sm2.get()), 'P2');
  });

  test('rounds', () async {
    var data = WhoIsNextData(['P1', 'P2', 'P3', 'P4'], 0, WhoIsNext(), () {});
    var sm = SwapMap(data);
    sm.select(const Key("0"));

    expect(highlighted(SwapMap(data).get()), 'P1');
    data.rounds = 1;
    expect(highlighted(SwapMap(data).get()), 'P2');
    data.rounds = 2;
    expect(highlighted(SwapMap(data).get()), 'P3');
    data.rounds = 3;
    expect(highlighted(SwapMap(data).get()), 'P4');
    data.rounds = 7;
    expect(highlighted(SwapMap(data).get()), 'P4');
    data.rounds = 15;
    expect(highlighted(SwapMap(data).get()), 'P4');
  });

  test('change selected', () async {
    var data = WhoIsNextData(['P1', 'P2', 'P3', 'P4'], 0, WhoIsNext(), () {});
    var sm = SwapMap(data);
    sm.select(const Key("0"));

    expect(highlighted(SwapMap(data).get()), 'P1');
    data.rounds = 1;
    expect(highlighted(SwapMap(data).get()), 'P2');

    sm.select(const Key("0"));
    expect(highlighted(sm.get()), 'P1');

    data.rounds = 1;
    expect(highlighted(SwapMap(data).get()), 'P1');
    data.rounds = 7;
    expect(highlighted(SwapMap(data).get()), 'P3');
    data.rounds = 15;
    expect(highlighted(SwapMap(data).get()), 'P3');
  });
}
