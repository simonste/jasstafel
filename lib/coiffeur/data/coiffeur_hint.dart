import 'package:flutter/material.dart';
import 'package:jasstafel/common/localization.dart';

enum HintType {
  lost,
  winPoints,
  winWithMatch,
  winPointsSingle,
  pointsNotLose,
  matchNotLose,
  pointsNotLoseOther,
  counterMatch
}

class Hint {
  final HintType type;
  final String teamName;
  final int p2;
  final int p3;

  Hint.lost(this.teamName, {required int pts})
      : type = HintType.lost,
        p2 = pts,
        p3 = 0;
  Hint.winPoints(this.teamName, {required int pts})
      : type = HintType.winPoints,
        p2 = pts,
        p3 = 0;
  Hint.winWithMatch(this.teamName, {required int factor})
      : type = HintType.winWithMatch,
        p2 = factor,
        p3 = 0;
  Hint.winPointsSingle(this.teamName, {required int pts, required int factor})
      : type = HintType.winPointsSingle,
        p2 = factor,
        p3 = pts;
  Hint.pointsNotLose(this.teamName, {required int pts})
      : type = HintType.pointsNotLose,
        p2 = pts,
        p3 = 0;
  Hint.matchNotLose(this.teamName, {required int factor})
      : type = HintType.matchNotLose,
        p2 = factor,
        p3 = 0;
  Hint.pointsNotLoseOther(this.teamName, {required int pts})
      : type = HintType.pointsNotLoseOther,
        p2 = pts,
        p3 = 0;
  Hint.counterMatch(this.teamName)
      : type = HintType.counterMatch,
        p2 = 0,
        p3 = 0;

  String getString(BuildContext context) {
    switch (type) {
      case HintType.lost:
        return context.l10n.hintLost(teamName, p2);
      case HintType.winPoints:
        return context.l10n.hint2win(teamName, p2);
      case HintType.winWithMatch:
        return context.l10n.hint2winMatches(teamName, p2);
      case HintType.winPointsSingle:
        return context.l10n.hint2winSpecial(teamName, p2, p3);
      case HintType.pointsNotLose:
        return context.l10n.hint2lead(teamName, p2);
      case HintType.matchNotLose:
        return context.l10n.hint2loseMatches(teamName, p2);
      case HintType.pointsNotLoseOther:
        return context.l10n.hint2loseOther(teamName, p2);
      case HintType.counterMatch:
        return context.l10n.hintCounterMatch(teamName);
    }
  }
}
