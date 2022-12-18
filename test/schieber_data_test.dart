import 'package:jasstafel/schieber/data/schieber_data.dart';
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

    expect(sumBefore + 612 == sumAfter, true);
  });

  test('add 213', () {
    var data = TeamData();

    data.add(651);
    final sumBefore = data.sum();
    expect(sumBefore == 651, true);

    data.add(213);
    final sumAfter = data.sum();

    expect(sumBefore + 213 == sumAfter, true);
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

    expect(sumBefore == sumAfter, true);
  });
}
