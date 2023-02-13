import 'package:jasstafel/molotow/data/molotow_score.dart';
import 'package:jasstafel/settings/molotow_settings.g.dart';
import 'package:test/test.dart';

void main() {
  test('count rows', () {
    var score = MolotowScore();

    score.rows.add(MolotowRow([null, 10, 0], isRound: false));
    score.rows.add(MolotowRow([44, 33, 55, 25], isRound: true));
    score.rows.add(MolotowRow([null, null, 20], isRound: false));

    expect(score.noOfRounds(), 1);
  });

  test('count points', () {
    var score = MolotowScore();

    score.rows.add(MolotowRow([], isRound: false));
    score.rows.add(MolotowRow([], isRound: true));
    score.rows.add(MolotowRow([5], isRound: false));

    expect(score.total(0), 5);
  });

  test('count points rounded', () {
    var score = MolotowScore();
    var settings = MolotowSettings();
    settings.rounded = true;
    score.setSettings(settings);

    score.rows.add(MolotowRow([], isRound: false));
    score.rows.add(MolotowRow([], isRound: true));
    score.rows.add(MolotowRow([54], isRound: false));

    expect(score.total(0), 5);
  });
}
