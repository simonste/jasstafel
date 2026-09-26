import 'package:jasstafel/common/utils.dart';
import 'package:test/test.dart';

void main() {
  test('round points', () {
    expect(roundPoints(257), 157);
    expect(roundPoints(514), 314);
    expect(roundPoints(771), 471);

    expect(roundPoints(250), 157);
    expect(roundPoints(200), 157);
    expect(roundPoints(250), 157);

    expect(roundPoints(400), 314);
    expect(roundPoints(500), 314);
    expect(roundPoints(510), 314);
  });

  test('match points', () {
    expect(matchPoints(157), 257);
    expect(matchPoints(314), 514);
    expect(matchPoints(471), 771);

    expect(matchPoints(200), 257);
  });

  test('roundedInt', () {
    expect(roundedInt(25, RoundingMode.none), 25);
    expect(roundedInt(48, RoundingMode.none), 48);
    expect(roundedInt(13, RoundingMode.none), 13);
    expect(roundedInt(25, RoundingMode.round), 3);
    expect(roundedInt(48, RoundingMode.round), 5);
    expect(roundedInt(13, RoundingMode.round), 1);
    expect(roundedInt(41, RoundingMode.ceil), 5);
    expect(roundedInt(40, RoundingMode.ceil), 4);
    expect(roundedInt(49, RoundingMode.floor), 4);
    expect(roundedInt(-25, RoundingMode.none), -25);
    expect(roundedInt(-25, RoundingMode.round), -3);
    expect(roundedInt(-25, RoundingMode.ceil), -3);
    expect(roundedInt(-25, RoundingMode.floor), -2);
  });
}
