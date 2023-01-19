import 'package:jasstafel/schieber/data/schieber_score.dart';
import 'package:test/test.dart';

void main() {
  test('add 612', () {
    var data = TeamData();

    data.strokes[0] = -13;
    data.strokes[1] = 6;
    data.strokes[2] = 2;
    data.strokes[3] = 1;
    data.strokes[4] = 0;

    final sumBefore = data.sum();
    data.add(612);
    final sumAfter = data.sum();

    expect(sumBefore + 612, sumAfter);
  });

  test('add 213', () {
    var data = TeamData();

    data.add(651);
    final sumBefore = data.sum();
    expect(sumBefore, 651);

    data.add(213);
    final sumAfter = data.sum();

    expect(sumBefore + 213, sumAfter);
  });

  test('overflow', () {
    var data = TeamData();

    data.strokes[0] = 24;
    data.strokes[1] = 26;
    data.strokes[2] = 15;
    data.strokes[3] = 20;
    data.strokes[4] = 0;

    final sumBefore = data.sum();
    data.checkOverflow();
    final sumAfter = data.sum();

    expect(sumBefore, sumAfter);
  });

  test('strokes', () {
    var data = TeamData();

    data.add(281);

    expect(data.sum(), 281);
    expect(data.strokes[0], 11);
    expect(data.strokes[1], 1);
    expect(data.strokes[2], 1);
    expect(data.strokes[3], 2);
    expect(data.strokes[4], 0);
  });

  test('minus1', () {
    var data = TeamData();

    var p0 = 666;
    data.add(p0);

    for (var i = 1; i < p0; i++) {
      data.add(-1);
      expect(data.sum(), p0 - i);
      expect(data.strokes[0] > -20, true);
      for (var stroke in data.strokes.sublist(1)) {
        assert(stroke >= 0);
      }
    }
  });

  test('remove 123', () {
    var data = TeamData();

    data.add(651);
    final sumBefore = data.sum();
    expect(sumBefore, 651);

    data.add(-123);
    final sumAfter = data.sum();

    expect(sumBefore - 123, sumAfter);
  });

  test('strokes remove', () {
    var data = TeamData();

    data.strokes[0] = -1;
    data.strokes[1] = 8;
    data.strokes[2] = 6;
    data.strokes[3] = 2;
    data.strokes[4] = 1;
    final sumBefore = data.sum();

    data.add(-281);

    expect(data.sum(), sumBefore - 281);
    expect(data.strokes[0], -12);
    expect(data.strokes[1], 7);
    expect(data.strokes[2], 5);
    expect(data.strokes[3], 0);
    expect(data.strokes[4], 1);
  });

  test('strokes remove weis', () {
    var data = TeamData();

    data.strokes[0] = 6;
    data.strokes[1] = 0;
    data.strokes[2] = 1;
    data.strokes[3] = 2;
    data.strokes[4] = 0;
    final sumBefore = data.sum();

    data.add(-100);

    expect(data.sum(), sumBefore - 100);
    expect(data.strokes[0], 6);
    expect(data.strokes[1], 0);
    expect(data.strokes[2], 1);
    expect(data.strokes[3], 1);
    expect(data.strokes[4], 0);
  });

  test('strokes remove 199', () {
    var data = TeamData();

    data.strokes[0] = 3;
    data.strokes[1] = 2;
    data.strokes[2] = 3;
    data.strokes[3] = 3;
    data.strokes[4] = 0;
    final sumBefore = data.sum();

    data.add(-199);

    expect(data.sum(), sumBefore - 199);
    expect(data.strokes[0], 4);
    expect(data.strokes[1], 2);
    expect(data.strokes[2], 3);
    expect(data.strokes[3], 1);
    expect(data.strokes[4], 0);
  });
}
