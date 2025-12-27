import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/guggitaler/data/guggitaler_score.dart';
import 'package:jasstafel/guggitaler/data/guggitaler_values.dart';
import 'package:test/test.dart';

void main() {
  List<List<int?>> setRow(int i, List<int?> row) {
    List<List<int?>> pts = List.generate(
      Players.max,
      (i) => List.filled(GuggitalerValues.length, null),
    );
    for (var p = 0; p < row.length; p++) {
      pts[p][i] = row[p];
    }
    return pts;
  }

  test('count rows', () {
    var score = GuggitalerScore();

    score.rows.add(GuggitalerRow());
    score.rows.last.pts = setRow(0, [2, 5, 2, 0]);
    score.rows.add(GuggitalerRow());
    score.rows.last.pts = setRow(1, [0, 5, 0, 0]);
    expect(score.noOfRounds(), 1);
    score.rows.add(GuggitalerRow());
    score.rows.last.pts = setRow(1, [0, 5, 0, 4]);
    expect(score.noOfRounds(), 2);
  });

  test('count points', () {
    var score = GuggitalerScore();

    score.rows.add(GuggitalerRow());
    score.rows.last.pts = setRow(0, [2, 5, 2, 0]);
    score.rows.add(GuggitalerRow());
    score.rows.last.pts = setRow(1, [0, 5, 0, 0]);

    expect(score.total(0), 10);
    expect(score.total(1), 75);
    expect(score.total(2), 10);
    expect(score.total(3), 0);
  });
}
