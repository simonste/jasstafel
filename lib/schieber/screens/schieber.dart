import 'package:flutter/material.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/dialog/points_dialog.dart';
import 'package:jasstafel/common/dialog/string_dialog.dart';
import 'package:jasstafel/common/widgets/board_title.dart';
import 'package:jasstafel/common/widgets/delete_button.dart';
import 'package:jasstafel/common/widgets/settings_button.dart';
import 'package:jasstafel/common/widgets/who_is_next_button.dart';
import 'package:jasstafel/schieber/data/schieber_score.dart';
import 'package:jasstafel/schieber/dialog/schieber_dialog.dart';
import 'package:jasstafel/schieber/dialog/schieber_history.dart';
import 'package:jasstafel/schieber/dialog/schieber_statistics.dart';
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
      SchieberSettings(), SchieberScore(), SchieberSettingsKeys().data);

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

    var dialogs = SchieberTeamDialogs(_openDialog, _stringDialog, _onTap);

    Widget goalPoints() {
      points(int teamId) {
        return GestureDetector(
            onTap: () => _pointsDialog(teamId),
            child: Text(data.score.team[teamId].goalPoints.toString(),
                textScaleFactor: 2, key: Key("GoalPoints$teamId")));
      }

      if (data.settings.differentGoals) {
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
                [data.score.team[0].name, data.score.team[1].name],
                data.score.noOfRounds(),
                data.common.whoIsNext,
                () => data.save()),
            SchieberHistoryButton(context, data, () {
              setState(() {
                data.score.undo();
                data.save();
              });
            }),
            SchieberStatisticsButton(context, data),
            DeleteButton(
              context,
              () => setState(() => data.reset()),
              deleteAllFunction: () {
                setState(() {
                  data.score.statistics.reset();
                  data.reset();
                });
              },
            ),
            SettingsButton(SchieberSettingsScreen(data), context,
                () => setState(() => data.settings.fromPrefService(context))),
          ],
        ),
        body: Stack(children: [
          Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SchieberTeam(0, data, dialogs),
                SchieberTeam(1, data, dialogs),
              ]),
          Center(child: goalPoints())
        ]));
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

  void _pointsDialog(int teamId) async {
    var controller = TextEditingController();
    controller.text = data.score.team[teamId].goalPoints.toString();

    final input = await pointsDialogBuilder(context, controller);
    if (input == null) return; // pressed anywhere outside dialog
    setState(() {
      data.score.team[teamId].goalPoints = input.value;
      data.save();
    });
  }

  void _openDialog(int teamId) async {
    final input = await schieberDialogBuilder(
        context, teamId, data.settings.match, data.score.team[teamId]);
    if (input == null) {
      return; // empty name not allowed
    }
    setState(() {
      data.score.add(input.points1, input.points2);
      data.save();
    });
  }

  void _onTap(int teamId, int pts) {
    if (data.settings.touchScreen) {
      if (data.supportsVibration && data.settings.vibrate) {
        Vibration.vibrate(duration: 50);
      }
      setState(() {
        if (teamId == 0) {
          data.score.add(pts, 0);
        } else {
          data.score.add(0, pts);
        }
        data.save();
      });
    }
  }
}
