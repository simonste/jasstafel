enum GoalType { noGoal, points, rounds }

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
  return 157;
}

int roundedInt(int value, bool rounded) {
  final factor = rounded ? 0.1 : 1;
  return (value * factor).round();
}

class Players {
  static int get min => 2;
  static int get max => 8;
}
