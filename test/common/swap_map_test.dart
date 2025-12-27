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
    expect(map2list(sm.get(landscape: true)), ['P1', 'P3', 'P2']);
  });

  test('default 4', () {
    var players = ['P1', 'P2', 'P3', 'P4'];
    var sm = SwapMap.simple(players);

    expect(map2list(sm.get()), ['P1', 'P4', 'P2', 'P3']);
    expect(highlighted(sm.get()), null);
    expect(map2list(sm.get(landscape: true)), ['P1', 'P4', 'P2', 'P3']);
  });

  test('default 5', () {
    var players = ['P1', 'P2', 'P3', 'P4', 'P5'];
    var sm = SwapMap.simple(players);

    expect(map2list(sm.get()), ['P1', 'P5', 'P2', 'P4', 'P3']);
    expect(highlighted(sm.get()), null);
    expect(map2list(sm.get(landscape: true)), ['P1', 'P5', 'P4', 'P2', 'P3']);
  });

  test('default 6', () {
    var players = ['P1', 'P2', 'P3', 'P4', 'P5', 'P6'];
    var sm = SwapMap.simple(players);

    expect(map2list(sm.get()), ['P1', 'P6', 'P2', 'P5', 'P3', 'P4']);
    expect(highlighted(sm.get()), null);
    expect(map2list(sm.get(landscape: true)), [
      'P1',
      'P6',
      'P5',
      'P2',
      'P3',
      'P4',
    ]);
  });
  test('default 7', () {
    var players = ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7'];
    var sm = SwapMap.simple(players);

    expect(map2list(sm.get()), ['P1', 'P7', 'P2', 'P6', 'P3', 'P5', 'P4']);
    expect(highlighted(sm.get()), null);
    expect(map2list(sm.get(landscape: true)), [
      'P1',
      'P7',
      'P6',
      'P5',
      'P2',
      'P3',
      'P4',
    ]);
  });
  test('default 8', () {
    var players = ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7', 'P8'];
    var sm = SwapMap.simple(players);

    expect(map2list(sm.get()), [
      'P1',
      'P8',
      'P2',
      'P7',
      'P3',
      'P6',
      'P4',
      'P5',
    ]);
    expect(highlighted(sm.get()), null);
    expect(map2list(sm.get(landscape: true)), [
      'P1',
      'P8',
      'P7',
      'P6',
      'P2',
      'P3',
      'P4',
      'P5',
    ]);
  });

  test('swap one', () {
    var players = ['P1', 'P2', 'P3', 'P4'];
    var sm = SwapMap.simple(players); // 1 4 2 3
    sm.swap(PlayerId(0), PlayerId(1));
    expect(map2list(sm.get()), ['P2', 'P4', 'P1', 'P3']);
  });

  test('swap two', () {
    var players = ['P1', 'P2', 'P3', 'P4'];
    var sm = SwapMap.simple(players); // 1 4 2 3
    sm.swap(PlayerId(0), PlayerId(1)); // 2 4 1 3
    sm.swap(PlayerId(1), PlayerId(2)); // 3 4 1 2
    expect(map2list(sm.get()), ['P3', 'P4', 'P1', 'P2']);
  });

  test('revert swap', () {
    var players = ['P1', 'P2', 'P3', 'P4'];
    var sm = SwapMap.simple(players); // 1 4 2 3
    sm.swap(PlayerId(1), PlayerId(2));
    sm.swap(PlayerId(1), PlayerId(2));
    expect(map2list(sm.get()), ['P1', 'P4', 'P2', 'P3']);
  });

  test('save & restore', () {
    var data = WhoIsNextData(['P1', 'P2', 'P3', 'P4'], 0, WhoIsNext(), () {});
    var sm = SwapMap(data); // 1 4 2 3
    sm.swap(PlayerId(1), PlayerId(2)); // 1 4 3 2
    sm.swap(PlayerId(0), PlayerId(2)); // 3 4 1 2
    expect(map2list(sm.get()), ['P3', 'P4', 'P1', 'P2']);

    var sm2 = SwapMap(data);
    expect(map2list(sm2.get()), ['P3', 'P4', 'P1', 'P2']);
    expect(highlighted(sm.get()), null);
  });

  test('select', () {
    var players = ['P1', 'P2', 'P3', 'P4'];
    var sm = SwapMap.simple(players);
    sm.select(PlayerId(2));
    expect(highlighted(sm.get()), 'P3');
    sm.swap(PlayerId(2), PlayerId(0));
    expect(highlighted(sm.get()), 'P3');
  });

  test('save & restore selected', () {
    var data = WhoIsNextData(['P1', 'P2', 'P3', 'P4'], 0, WhoIsNext(), () {});
    var sm = SwapMap(data);
    sm.select(PlayerId(1));
    expect(highlighted(sm.get()), 'P2');

    var sm2 = SwapMap(data);
    expect(highlighted(sm2.get()), 'P2');
  });

  test('save & restore selected 2', () {
    var data = WhoIsNextData(['P1', 'P2', 'P3', 'P4'], 0, WhoIsNext(), () {});
    var sm = SwapMap(data);
    sm.swap(PlayerId(2), PlayerId(1)); //pO: P1 P3 P2 P4
    sm.select(PlayerId(2));
    expect(highlighted(sm.get()), 'P3');

    data.rounds = 1;
    var sm2 = SwapMap(data);
    expect(highlighted(sm2.get()), 'P2');

    data.rounds = 2;
    var sm3 = SwapMap(data);
    expect(highlighted(sm3.get()), 'P4');
  });

  test('rounds', () {
    var data = WhoIsNextData(['P1', 'P2', 'P3', 'P4'], 0, WhoIsNext(), () {});
    var sm = SwapMap(data);
    sm.select(PlayerId(0));

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

  test('change selected', () {
    var data = WhoIsNextData(['P1', 'P2', 'P3', 'P4'], 0, WhoIsNext(), () {});
    var sm = SwapMap(data);
    sm.select(PlayerId(0));

    expect(highlighted(SwapMap(data).get()), 'P1');
    data.rounds = 1;
    expect(highlighted(SwapMap(data).get()), 'P2');

    sm.select(PlayerId(0));
    expect(highlighted(sm.get()), 'P1');

    data.rounds = 1;
    expect(highlighted(SwapMap(data).get()), 'P1');
    data.rounds = 7;
    expect(highlighted(SwapMap(data).get()), 'P3');
    data.rounds = 15;
    expect(highlighted(SwapMap(data).get()), 'P3');
  });

  test('selected 6 players', () {
    var data = WhoIsNextData(
      ['P1', 'P2', 'P3', 'P4', 'P5', 'P6'],
      0,
      WhoIsNext(),
      () {},
    );
    var sm = SwapMap(data);
    sm.select(PlayerId(3));
    sm.swap(PlayerId(3), PlayerId(0));
    expect(highlighted(SwapMap(data).get()), 'P4');
    data.rounds = 1;
    expect(highlighted(SwapMap(data).get()), 'P2');
    expect(highlighted(SwapMap(data).get(landscape: true)), 'P2');
    data.rounds = 2;
    expect(highlighted(SwapMap(data).get()), 'P3');
    data.rounds = 3;
    expect(highlighted(SwapMap(data).get()), 'P1');
    data.rounds = 4;
    expect(highlighted(SwapMap(data).get(landscape: true)), 'P5');
  });
}
