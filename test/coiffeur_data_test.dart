import 'package:jasstafel/coiffeur/data/coiffeur_data.dart';
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

  test('rounded', () {
    var data = CoiffeurData();
    data.settings.rounded = true;

    data.rows[0].pts[1] = 57;
    data.rows[2].pts[0] = 105;
    data.rows[2].pts[1] = 60;

    expect(data.diff(2), 3 * 5);

    data.rows[2].pts[1] = 112;
    expect(data.diff(2), 0);
  });

  test('bonus', () {
    var data = CoiffeurData();
    data.settings.match = 257;
    data.settings.bonus = true;
    data.settings.bonusValue = 500;

    data.rows[0].pts[0] = 60;
    data.rows[0].pts[1] = 88;
    data.rows[2].pts[0] = 257;
    data.rows[2].pts[1] = 60;

    expect(data.points(2, 0), 257);
    expect(data.match(2, 0), true);
    expect(data.diff(2), 3 * 97 + 500);
    expect(data.total(0), 60 + 3 * 157 + 500);
    expect(data.total(2), -28 + 3 * 97 + 500);
  });

  test('bonus rounded', () {
    var data = CoiffeurData();
    data.settings.match = 257;
    data.settings.bonus = true;
    data.settings.bonusValue = 300;
    data.settings.rounded = true;

    data.rows[0].pts[0] = 60;
    data.rows[0].pts[1] = 88;
    data.rows[2].pts[0] = 257;
    data.rows[2].pts[1] = 60;

    expect(data.points(2, 0), 26);
    expect(data.match(2, 0), true);
    expect(data.diff(2), 3 * 10 + 30);
    expect(data.total(0), 6 + 3 * 16 + 30);
    expect(data.total(2), -3 + 3 * 10 + 30);
  });

  test('scratch', () {
    var data = CoiffeurData();
    data.rows[0].pts[0] = 60;
    data.rows[2].pts[1] = 60;
    data.rows[2].scratch(0);

    expect(data.rounds(), 3);
    expect(data.total(0), 60);
    expect(data.diff(2), -3 * 60);
  });
}
