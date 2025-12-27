import 'package:flutter/material.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/dialog/points_dialog.dart';
import 'package:jasstafel/common/dialog/string_dialog.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/common/widgets/board_title.dart';
import 'package:jasstafel/common/widgets/delete_button.dart';
import 'package:jasstafel/common/widgets/settings_button.dart';
import 'package:jasstafel/common/widgets/who_is_next_button.dart';
import 'package:jasstafel/schieber/data/schieber_score.dart';
import 'package:jasstafel/schieber/dialog/schieber_dialog.dart';
import 'package:jasstafel/schieber/dialog/schieber_history.dart';
import 'package:jasstafel/schieber/dialog/schieber_statistics.dart';
import 'package:jasstafel/schieber/screens/schieber_backside.dart';
import 'package:jasstafel/schieber/screens/schieber_settings_screen.dart';
import 'package:jasstafel/schieber/widgets/schieber_team.dart';
import 'package:jasstafel/settings/schieber_settings.g.dart';
import 'package:vibration/vibration.dart';

import 'dart:developer' as developer;

class Schieber extends StatefulWidget {
  const Schieber({super.key});

  @override
  State<Schieber> createState() => _SchieberState();
}

class _SchieberState extends State<Schieber> {
  var data = BoardData(
    SchieberSettings(),
    SchieberScore(),
    SchieberSettingsKeys().data,
  );

  void restoreData() async {
    data = await data.load() as BoardData<SchieberSettings, SchieberScore>;
    setState(() {}); // trigger widget update
  }

  @override
  void initState() {
    developer.log('init state', name: 'jasstafel schieber');
    super.initState();
    restoreData();
  }

  @override
  Widget build(BuildContext context) {
    developer.log('build', name: 'jasstafel schieber');

    data.score.checkHill(context);
    data.checkGameOver(
      context,
      goalType: GoalType.values[data.settings.goalType],
    );

    var dialogs = SchieberTeamDialogs(_openDialog, _stringDialog, _onTap);

    Widget goalPoints() {
      points(int teamId) {
        setGoalPoints(pts) {
          if (data.settings.differentGoals) {
            data.score.team[teamId].goalPoints = pts;
          } else {
            data.score.team[0].goalPoints = pts;
            data.score.team[1].goalPoints = pts;
          }
        }

        return GestureDetector(
          onTap: () => _pointsDialog(
            value: data.score.team[teamId].goalPoints,
            apply: (int value) => setGoalPoints(value),
            title: Text(context.l10n.goalPoints),
          ),
          child: Text(
            data.score.team[teamId].goalPoints.toString(),
            textScaler: const TextScaler.linear(2),
            key: Key("GoalPoints$teamId"),
          ),
        );
      }

      if (data.settings.differentGoals) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotatedBox(quarterTurns: 2, child: points(0)),
            points(1),
          ],
        );
      }
      return points(0);
    }

    Widget goalRounds() {
      return GestureDetector(
        onTap: () => _pointsDialog(
          value: data.score.goalRounds,
          apply: (int value) => data.score.goalRounds = value,
          title: Text(context.l10n.rounds),
        ),
        child: Text(
          "${data.score.noOfRounds()} / ${data.score.goalRounds}",
          textScaler: const TextScaler.linear(2),
          key: const Key("GoalRounds"),
        ),
      );
    }

    var players = WhoIsNextButton.guessPlayerNames([
      data.score.team[0].name,
      data.score.team[1].name,
    ]);
    if (data.settings.differentGoals) {
      // only 3 players
      for (var i = 0; i < 2; i++) {
        final j = (i + 1) % 2;
        if (data.score.team[i].goalPoints < data.score.team[j].goalPoints) {
          players = WhoIsNextButton.guessPlayerNames([data.score.team[j].name]);
          players.add(data.score.team[i].name);
        }
      }
    }

    List<Widget> actions = [
      WhoIsNextButton(
        context,
        players,
        data.score.noOfRounds(),
        data.common.whoIsNext,
        () => data.save(),
      ),
      SchieberHistoryButton(context, data, () {
        setState(() {
          data.score.undo();
          data.save();
        });
      }),
      SchieberStatisticsButton(context, data),
      DeleteButton(
        context,
        deleteFunction: () => setState(() => data.reset()),
        deleteAllFunction: () {
          setState(() {
            data.reset();
            data.score.statistics.reset();
          });
        },
      ),
      SettingsButton(
        SchieberSettingsScreen(data),
        context,
        () => setState(() => data.settings.fromPrefService(context)),
      ),
    ];
    if (data.settings.backside) {
      actions.insert(0, BacksideButton(context, () => data.load()));
    }

    Widget center;
    switch (GoalType.values[data.settings.goalType]) {
      case GoalType.points:
        center = goalPoints();
        break;
      case GoalType.rounds:
        center = goalRounds();
        break;
      case GoalType.noGoal:
        center = Container();
        break;
    }

    return Scaffold(
      appBar: TitleBar(
        board: Board.schieber,
        context: context,
        actions: actions,
        priority: const [
          SettingsButton<SchieberSettingsScreen>,
          DeleteButton,
          SchieberStatisticsButton,
        ],
      ),
      body: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SchieberTeam(0, data, dialogs),
              SchieberTeam(1, data, dialogs),
            ],
          ),
          Center(child: center),
        ],
      ),
    );
  }

  void _stringDialog(team) async {
    var controller = TextEditingController(text: data.score.team[team].name);

    final input = await stringDialogBuilder(context, controller);
    if (input == null) return; // empty name not allowed
    setState(() {
      data.score.team[team].name = input;
      data.save();
    });
  }

  void _pointsDialog({
    required int value,
    required Function apply,
    Widget? title,
  }) async {
    var controller = TextEditingController();
    controller.text = "$value";

    final input = await pointsDialogBuilder(context, controller, title: title);
    if (input == null) return; // pressed anywhere outside dialog
    setState(() {
      apply(input.value!);
      data.save();
    });
  }

  void _openDialog(int teamId) async {
    final input = await schieberDialogBuilder(
      context,
      teamId,
      data.settings.match,
      data.settings.pointsPerRound,
      data.score.team[teamId],
    );
    if (input == null) {
      return; // empty name not allowed
    }
    setState(() {
      data.common.timestamps.addPoints(data.score.totalPoints());
      data.score.add(input.points1, input.points2, weis: input.weis);
      data.save();
    });
  }

  void _onTap(int teamId, int pts) {
    if (data.settings.touchScreen) {
      if (data.supportsVibration && data.settings.vibrate) {
        Vibration.vibrate(duration: 50);
      }
      setState(() {
        data.common.timestamps.addPoints(data.score.totalPoints());
        if (teamId == 0) {
          data.score.add(pts, 0, weis: true);
        } else {
          data.score.add(0, pts, weis: true);
        }
        data.save();
      });
    }
  }
}
