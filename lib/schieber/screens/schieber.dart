import 'package:flutter/material.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/dialog/pointsdialog.dart';
import 'package:jasstafel/common/dialog/stringdialog.dart';
import 'package:jasstafel/common/widgets/boardtitle.dart';
import 'package:jasstafel/common/widgets/settings_button.dart';
import 'package:jasstafel/common/widgets/who_is_next_button.dart';
import 'package:jasstafel/schieber/data/schieber_data.dart';
import 'package:jasstafel/schieber/dialog/schieber_dialog.dart';
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
  var state = BoardData(SchieberData(), SchieberSettingsKeys().data);

  void restoreData() async {
    state = await state.load() as BoardData<SchieberData>;
    setState(() {}); // trigger widget update
  }

  @override
  void initState() {
    developer.log('init state', name: 'jasstafel schieber');
    super.initState();
    restoreData();
  }

  int getGoalPoints(int team) {
    if (state.data.settings.differentGoals && team == 0) {
      return state.data.settings.goalPoints2;
    }
    return state.data.settings.goalPoints;
  }

  void setGoalPoints(int team, int points) {
    if (state.data.settings.differentGoals && team == 0) {
      state.data.settings.goalPoints2 = points;
    } else {
      state.data.settings.goalPoints = points;
    }
  }

  @override
  Widget build(BuildContext context) {
    developer.log('build', name: 'jasstafel schieber');
    var dialogs = SchieberTeamDialogs(_openDialog, _stringDialog, _onTap);
    state.data.settings.fromPrefService(context);

    Widget goalPoints() {
      points(int teamId) {
        return GestureDetector(
            onTap: () => _pointsDialog(teamId),
            child: Text(getGoalPoints(teamId).toString(), textScaleFactor: 2));
      }

      if (state.data.settings.differentGoals) {
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
                state.commonData,
                [state.data.team[0].name, state.data.team[1].name],
                state.data.rounds()),
            IconButton(
                onPressed: () => _openStatistics(),
                icon: const Icon(Icons.history)),
            IconButton(
                onPressed: () => _openHistory(),
                icon: const Icon(Icons.bar_chart)),
            IconButton(
                onPressed: () => setState(() => state.reset()),
                icon: const Icon(Icons.delete)),
            SettingsButton(
                const SchieberSettingsScreen(),
                context,
                () => setState(() {
                      developer.log('build', name: 'reload settings');
                      state.data.settings.fromPrefService(context);
                    })),
          ],
        ),
        body: Stack(children: [
          Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SchieberTeam(0, state.data, dialogs),
                SchieberTeam(1, state.data, dialogs),
              ]),
          Center(child: goalPoints())
        ]));
  }

  void _openHistory() {}
  void _openStatistics() {}

  void _stringDialog(team) async {
    var controller = TextEditingController(text: state.data.team[team].name);

    final input = await stringDialogBuilder(context, controller);
    if (input == null) return; // empty name not allowed
    setState(() {
      state.data.team[team].name = input;
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
    final input = await schieberDialogBuilder(
        context, teamId, state.data.settings.pointsPerRound);
    if (input == null) {
      return; // empty name not allowed
    }
    setState(() {
      state.data.team[0].add(input.points1);
      state.data.team[1].add(input.points2);
      state.save();
    });
  }

  void _onTap(int teamId, int step) {
    if (state.data.settings.touchScreen) {
      if (state.data.settings.vibrate) {
        Vibration.vibrate(duration: 50);
      }
      setState(() {
        if (step == -1) {
          state.data.team[teamId].strokes[0]--;
        } else {
          state.data.team[teamId].strokes[step]++;
        }
        state.data.team[teamId].checkOverflow();
        state.save();
      });
    }
  }
}
