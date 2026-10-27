import 'package:jasstafel/common/data/common_data.dart';
import 'package:test/test.dart';

void main() {
  test('first points start the clock after a long wait', () {
    final timestamps = Timestamps()
      ..startTime = DateTime.now().subtract(const Duration(minutes: 30));
    timestamps.addPoints(0);
    expect(timestamps.duration(), 0);
  });

  test('first points keep the start of a recent reset', () {
    final timestamps = Timestamps()
      ..startTime = DateTime.now().subtract(const Duration(minutes: 5));
    timestamps.addPoints(0);
    expect(timestamps.duration(), 5);
  });

  test('later points keep the start', () {
    final timestamps = Timestamps()
      ..startTime = DateTime.now().subtract(const Duration(minutes: 30));
    timestamps.addPoints(157);
    expect(timestamps.duration(), 30);
  });

  test('a board without a start gets one', () {
    final timestamps = Timestamps();
    timestamps.addPoints(0);
    expect(timestamps.duration(), 0);
  });
}
