import 'package:flutter/material.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/dialog/points_dialog.dart';
import 'package:jasstafel/common/dialog/string_dialog.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/common/widgets/board_title.dart';
import 'package:jasstafel/common/widgets/delete_button.dart';
import 'package:jasstafel/common/widgets/settings_button.dart';
import 'package:jasstafel/common/widgets/who_is_next_button.dart';
import 'package:jasstafel/schieber/data/schieber_score.dart';
import 'package:jasstafel/schieber/dialog/schieber_dialog.dart';
import 'package:jasstafel/schieber/dialog/schieber_history.dart';
import 'package:jasstafel/schieber/dialog/schieber_statistics.dart';
import 'package:jasstafel/schieber/screens/schieber_settings.dart';
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
  var state = BoardData(
      SchieberSettings(), SchieberScore(), SchieberSettingsKeys().data);

  void restoreData() async {
    state = await state.load() as BoardData<SchieberSettings, SchieberScore>;
    setState(() {}); // trigger widget update
  }

  @override
  void initState() {
    developer.log('init state', name: 'jasstafel schieber');
    super.initState();
    restoreData();
  }

  int getGoalPoints(int team) {
    if (state.settings.differentGoals && team == 0) {
      return state.settings.goalPoints2;
    }
    return state.settings.goalPoints;
  }

  void setGoalPoints(int team, int points) {
    if (state.settings.differentGoals && team == 0) {
      state.settings.goalPoints2 = points;
    } else {
      state.settings.goalPoints = points;
    }
  }

  @override
  Widget build(BuildContext context) {
    developer.log('build', name: 'jasstafel schieber');
    state.settings.fromPrefService(context);
    state.score.setSettings(state.settings);

    var dialogs = SchieberTeamDialogs(_openDialog, _stringDialog, _onTap);

    Widget goalPoints() {
      points(int teamId) {
        return GestureDetector(
            onTap: () => _pointsDialog(teamId),
            child: Text(getGoalPoints(teamId).toString(), textScaleFactor: 2));
      }

      if (state.settings.differentGoals) {
        return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          RotatedBox(quarterTurns: 2, child: points(0)),
          points(1)
        ]);
      }
      return points(0);
    }

    return Scaffold(
        appBar: AppBar(
          title: BoardTitle(Board.schieber, context),
          actions: [
            WhoIsNextButton(
                context,
                [state.score.team[0].name, state.score.team[1].name],
                state.score.noOfRounds(),
                state.common.whoIsNext,
                () => state.save()),
            SchieberHistoryButton(context, state, () {
              setState(() {
                state.score.undo();
                state.save();
              });
            }),
            SchieberStatisticsButton(context, state),
            DeleteButton(
              context,
              () => setState(() => state.reset()),
              deleteAllFunction: () {
                setState(() {
                  state.score.statistics.reset();
                  state.reset();
                });
              },
            ),
            SettingsButton(const SchieberSettingsScreen(), context,
                () => setState(() => state.settings.fromPrefService(context))),
          ],
        ),
        body: Stack(children: [
          Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SchieberTeam(0, state, dialogs),
                SchieberTeam(1, state, dialogs),
              ]),
          Center(child: goalPoints())
        ]));
  }

  void _stringDialog(team) async {
    var controller = TextEditingController(text: state.score.team[team].name);

    final input = await stringDialogBuilder(context, controller);
    if (input == null) return; // empty name not allowed
    setState(() {
      state.score.team[team].name = input;
      state.save();
    });
  }

  void _pointsDialog(int teamId) async {
    var controller = TextEditingController();
    controller.text = getGoalPoints(teamId).toString();

    final input = await pointsDialogBuilder(context, controller);
    if (input == null) return; // pressed anywhere outside dialog
    setState(() {
      setGoalPoints(teamId, input.value!);
      state.save();
    });
  }

  void _openDialog(int teamId) async {
    final input = await schieberDialogBuilder(context, teamId,
        roundPoints(state.settings.match), state.score.team[teamId]);
    if (input == null) {
      return; // empty name not allowed
    }
    setState(() {
      state.score.add(input.points1, input.points2);
      state.save();
    });
  }

  void _onTap(int teamId, int pts) {
    if (state.settings.touchScreen) {
      if (state.settings.vibrate) {
        Vibration.vibrate(duration: 50);
      }
      setState(() {
        if (teamId == 0) {
          state.score.add(pts, 0);
        } else {
          state.score.add(0, pts);
        }
        state.save();
      });
    }
  }
}
