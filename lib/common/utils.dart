enum GoalType { noGoal, points, rounds }

enum RoundingMode { none, round }

int matchPoints(int pointsPerRound) {
  if (pointsPerRound % 157 == 0) {
    int decks = (pointsPerRound / 157).round();
    return pointsPerRound + decks * 100;
  }
  return 257;
}

int roundPoints(int matchPoints) {
  if (matchPoints % 257 == 0) {
    int decks = (matchPoints / 257).round();
    return matchPoints - decks * 100;
  }
  if (400 <= matchPoints && matchPoints < 520) {
    return 314;
  }
  return 157;
}

int roundedInt(int value, RoundingMode mode) {
  switch (mode) {
    case RoundingMode.none:
      return value;
    case RoundingMode.round:
      return (value * 0.1).round();
  }
}

class Players {
  static int get min => 2;
  static int get max => 8;
}
