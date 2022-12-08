import 'package:jasstafel/coiffeur/data/coiffeurdata.dart';
import 'package:test/test.dart';

void main() {
  test('count rows', () {
    var data = CoiffeurData();

    data.rows[0].pts[1] = 57;
    data.rows[2].pts[0] = 100;
    data.rows[4].pts[0] = 60;
    expect(data.rounds(), 3);

    data.rows[2].pts[2] = 100;
    expect(data.rounds(), 3); // ignore 3rd team

    data.rows[12].pts[0] = 55;
    expect(data.rounds(), 3); // ignore hidden row

    data.settings.rows = 13;
    expect(data.rounds(), 4);

    data.settings.threeTeams = true;
    expect(data.rounds(), 5);
  });

  test('sum points', () {
    var data = CoiffeurData();

    data.rows[0].pts[1] = 57;
    data.rows[2].pts[0] = 100;
    data.rows[4].pts[0] = 60;

    expect(data.total(0), 3 * 100 + 5 * 60);
    expect(data.total(1), 57);
  });

  test('row diff', () {
    var data = CoiffeurData();

    data.rows[0].pts[1] = 57;
    data.rows[2].pts[0] = 100;
    data.rows[2].pts[1] = 60;

    expect(data.diff(2), 3 * 40);

    data.rows[2].pts[1] = 111;
    expect(data.diff(2), 3 * -11);
  });
}
