import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jasstafel/coiffeur/data/coiffeur_hint.dart';
import 'package:jasstafel/coiffeur/data/coiffeur_score.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/settings/coiffeur_settings.g.dart';
import 'package:collection/collection.dart';

class Result {
  int min = 0;
  int max = 0;
  int pts = 0;

  List<int> open = [];
}

class Winner {
  List<int> winner;
  List<int> loser;

  Winner(this.winner, this.loser);
}

int roundedInt(int value, bool rounded) {
  final factor = rounded ? 0.1 : 1;
  return (value * factor).round();
}

class CoiffeurInfo {
  CoiffeurInfo(this._data)
      : teams = _data.settings.threeTeams ? 3 : 2,
        bonusPoints = roundedInt(
            _data.settings.bonus ? _data.settings.bonusValue : 0,
            _data.settings.rounded),
        match = roundedInt(_data.settings.match, _data.settings.rounded),
        noMatch = roundedInt(
            _data.settings.bonus
                ? _data.settings.match
                : roundPoints(_data.settings.match),
            _data.settings.rounded) {
    for (var t = 0; t < teams; t++) {
      for (var i = 0; i < _data.settings.rows; i++) {
        final pts = _data.score.rows[i].pts[t];
        if (pts.pts == null && !pts.scratched && !pts.match) {
          result[t].open.add(_data.score.rows[i].factor);
        }
      }
      result[t].pts = _data.score.total(t);
      result[t].min = result[t].pts;
      final factorSum = result[t].open.sum;
      result[t].max = result[t].pts + factorSum * match;
      result[t].max += result[t].open.length * bonusPoints;
      final minusFactor =
          _data.settings.bonus ? result[t].open.length : result[t].open.sum;
      result[t].min -= minusFactor *
          roundedInt(_data.settings.counterLoss, _data.settings.rounded);
    }
  }

  final int teams;

  final result = [Result(), Result(), Result()];

  final BoardData<CoiffeurSettings, CoiffeurScore> _data;

  final int bonusPoints;

  final int match;

  final int noMatch;

  String teamName(int i) {
    return _data.score.teamName[i];
  }

  Winner winner() {
    var maxes = [result[0].max, result[1].max, result[2].max];
    var mins = [result[0].min, result[1].min, result[2].min];
    maxes.sort();
    mins.sort();
    final highestMin = mins[2];
    final highestMax = maxes[2];
    final secondHighestMax = maxes[1];

    List<int> winners = [];
    List<int> losers = [];
    for (var t = 0; t < teams; t++) {
      if (result[t].max < highestMin) {
        losers.add(t);
      }
      if (result[t].max == highestMax && result[t].min >= secondHighestMax) {
        winners.add(t);
      }
    }
    return Winner(winners, losers);
  }

  List<Hint> getHints() {
    var maxes = [result[0].max, result[1].max, result[2].max];
    var mins = [result[0].min, result[1].min, result[2].min];
    var points = [result[0].pts, result[1].pts, result[2].pts];
    maxes.sort();
    mins.sort();
    points.sort();

    final highestMin = mins[2];
    final highestMax = maxes[2];
    final highestPts = points[2];
    final secondHighestMax = maxes[1];

    int pointsToWin(int current, int factor) {
      return max(((secondHighestMax - current) / factor).ceil(), 0);
    }

    int matchRequired(int avgRequired, List<int> factors) {
      if (avgRequired <= noMatch || factors.isEmpty) return 0;
      final int ptsDiff = factors.sum * avgRequired;
      final int maxPointsWithoutMatch = factors.sum * noMatch;

      for (int f in factors) {
        final int noMatchDiff = (_data.settings.bonus)
            ? _data.settings.bonusValue
            : ((match - noMatch) * f);

        // enough if everywhere else "noMatch" points?
        if (ptsDiff - noMatchDiff <= maxPointsWithoutMatch) {
          int idx = factors.lastIndexOf(f);
          return factors.removeAt(idx);
        }
      }
      return factors.removeAt(factors.length - 1);
    }

    void calcPointsToLead(List<Hint> hints, Result team, String teamName) {
      var remainingFactors = [...team.open]; // clone list
      var teamPts = team.pts; // clone
      int avgPtsToLead = ((highestPts - team.pts) / team.open.sum).ceil();
      int requiredMatch = matchRequired(avgPtsToLead, remainingFactors);

      final bool requireAtLeastOneMatch = (requiredMatch != 0);

      while (requiredMatch != 0) {
        hints.add(Hint.matchNotLose(teamName, factor: requiredMatch));

        if (remainingFactors.isEmpty) {
          break;
        }
        teamPts += requiredMatch * match + bonusPoints;
        avgPtsToLead = ((highestPts - teamPts) / remainingFactors.sum).ceil();
        requiredMatch = matchRequired(avgPtsToLead, remainingFactors);
      }
      if (remainingFactors.isNotEmpty) {
        if (requireAtLeastOneMatch) {
          hints.add(Hint.pointsNotLoseOther(teamName, pts: avgPtsToLead));
        } else {
          hints.add(Hint.pointsNotLose(teamName, pts: avgPtsToLead));
        }
      }
    }

    List<Hint> getHintsForTeam(int t) {
      final team = result[t];
      final teamName = _data.score.teamName[t];
      final canWin = team.max >= highestMin;
      final canWinSelf = team.max == highestMax && team.open.isNotEmpty;
      final notWonYet = team.min < secondHighestMax;
      final leading = team.pts == highestPts;

      List<Hint> hints = [];

      if (canWin && team.max < highestPts) {
        hints.add(Hint.counterMatch(teamName));
      }
      if (team.open.sum == 0) return hints;

      if (!canWin) {
        int val = ((highestMin - team.pts - team.open.length * bonusPoints) /
                team.open.sum)
            .ceil();
        hints.add(Hint.lost(teamName, pts: val));
      } else if (canWinSelf && notWonYet) {
        final avgPtsWin = pointsToWin(team.pts, team.open.sum);
        if (team.open.length == 1) {
          if (avgPtsWin > noMatch) {
            hints.add(Hint.winWithMatch(teamName, factor: team.open[0]));
          } else {
            hints.add(Hint.winPointsSingle(teamName,
                factor: team.open[0], pts: avgPtsWin));
          }
        } else {
          if (avgPtsWin > match && _data.settings.bonus) {
            // need match to win
            calcPointsToLead(hints, team, teamName);
          } else {
            hints.add(Hint.winPoints(teamName, pts: avgPtsWin));
            for (int f in team.open) {
              int enough = pointsToWin(team.min, f);
              if (enough < noMatch) {
                hints.add(
                    Hint.winPointsSingle(teamName, factor: f, pts: enough));
              } else if ((f * match + bonusPoints) >
                  (secondHighestMax - team.pts)) {
                hints.add(Hint.winWithMatch(teamName, factor: f));
              }
            }
          }
        }
      } else if (!leading) {
        calcPointsToLead(hints, team, teamName);
      }
      return hints;
    }

    List<Hint> hints = [];
    for (int t = 0; t < teams; ++t) {
      hints.addAll(getHintsForTeam(t));
    }
    return hints;
  }
}

class CoiffeurInfoButton extends IconButton {
  CoiffeurInfoButton(BuildContext context, data)
      : super(
            onPressed: () {
              dialogBuilder(context, CoiffeurInfo(data));
            },
            icon: const Icon(Icons.info_outline),
            key: const Key("InfoButton"));
}

enum RowType { bold, normal }

Future<void> dialogBuilder(BuildContext context, CoiffeurInfo info) {
  return showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            rowS(String title, List<String> str,
                {RowType rowType = RowType.normal}) {
              text(String string) {
                return Expanded(
                    child: Text(
                  string,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: (rowType == RowType.normal)
                          ? FontWeight.w100
                          : FontWeight.w400),
                ));
              }

              if (info.teams == 2) {
                return Row(children: [
                  text(str[0]),
                  text(title),
                  text(str[1]),
                ]);
              } else {
                return Row(children: [
                  text(title),
                  text(str[0]),
                  text(str[1]),
                  text(str[2]),
                ]);
              }
            }

            rowI(String title, List<int> pts,
                {RowType rowType = RowType.normal}) {
              return rowS(title, pts.map((e) => "$e").toList(),
                  rowType: rowType);
            }

            List<Widget> children = [
              rowS("", [info.teamName(0), info.teamName(1), info.teamName(2)],
                  rowType: RowType.bold),
              rowI("Pts",
                  [info.result[0].pts, info.result[1].pts, info.result[2].pts],
                  rowType: RowType.bold),
              const Divider(),
              rowI("Min",
                  [info.result[0].min, info.result[1].min, info.result[2].min]),
              rowI("Max",
                  [info.result[0].max, info.result[1].max, info.result[2].max]),
              const Divider()
            ];

            for (final hint in info.getHints()) {
              children.add(Text(
                hint.getString(context),
                style: const TextStyle(fontWeight: FontWeight.w200),
              ));
            }

            return AlertDialog(
              title: Text(context.l10n.currentRound),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: children,
              ),
              actions: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: Text(context.l10n.ok),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      });
}
