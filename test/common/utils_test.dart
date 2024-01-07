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
    expect(roundedInt(25, false), 25);
    expect(roundedInt(48, false), 48);
    expect(roundedInt(13, false), 13);
    expect(roundedInt(25, true), 3);
    expect(roundedInt(48, true), 5);
    expect(roundedInt(13, true), 1);
  });
}
