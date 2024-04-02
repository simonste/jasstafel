import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/schieber/data/schieber_score.dart';
import 'package:jasstafel/schieber/widgets/schieber_background_z.dart';
import 'package:jasstafel/common/widgets/progress.dart';
import 'package:jasstafel/schieber/widgets/schieber_strokes.dart';
import 'package:jasstafel/settings/schieber_settings.g.dart';

class SchieberTeamDialogs {
  final Function(int) addPoints;
  final Function(int) editTeamName;
  final Function(int, int) onTap;

  SchieberTeamDialogs(this.addPoints, this.editTeamName, this.onTap);
}

class SchieberTeam extends StatelessWidget {
  final BoardData<SchieberSettings, SchieberScore> data;
  final int teamId;
  final SchieberTeamDialogs dialogs;

  const SchieberTeam(this.teamId, this.data, this.dialogs, {super.key});

  @override
  Widget build(BuildContext context) {
    if (teamId == 0) {
      return Expanded(
          child:
              RotatedBox(quarterTurns: 2, child: _team(teamId, data, context)));
    } else {
      return Expanded(child: _team(teamId, data, context));
    }
  }

  Widget _team(int teamId, BoardData<SchieberSettings, SchieberScore> data,
      BuildContext context) {
    final height = MediaQuery.of(context).size.height / 2;
    final width = MediaQuery.of(context).size.width;

    final teamData = data.score.team[teamId];
    final pts = teamData.sum();

    progress() {
      switch (GoalType.values[data.settings.goalType]) {
        case GoalType.points:
          return (pts / data.score.team[teamId].goalPoints);
        case GoalType.rounds:
          return (data.score.noOfRounds() / data.score.goalRounds);
        case GoalType.noGoal:
          return 0.0;
      }
    }

    final hMargin = width * 0.05;
    final strokeHeight = height * 0.2;
    final strokesWidth = width * 0.5;
    final numberWidth = width * 0.2;

    final top1 = height * 0.1;
    final top2 = top1 + (top1 + strokeHeight);
    final top3 = top2 + (top1 + strokeHeight);

    final teamName = Positioned(
        top: height * 0.01,
        left: width * 0.01,
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.8,
          child: GestureDetector(
              onTap: () => dialogs.editTeamName(teamId),
              child: AutoSizeText(
                teamData.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaleFactor: 2,
              )),
        ));
    teamPoints() {
      if (data.settings.bigScore) {
        return Center(
            child: Text("$pts",
                textScaler: const TextScaler.linear(4),
                key: Key("sum_$teamId")));
      }
      return Positioned(
        top: height * 0.01,
        right: width * 0.01,
        child: Text("$pts",
            textScaler: const TextScaler.linear(2), key: Key("sum_$teamId")),
      );
    }

    backgroundZ() {
      if (data.settings.drawZ) {
        return Row(children: [
          Expanded(child: BackgroundZ(Size(hMargin, top1 + strokeHeight / 2)))
        ]);
      } else {
        return const SizedBox.shrink();
      }
    }

    strokesBox(int pts) {
      final i = teamData.values.indexOf(pts);
      final type = pts == 50 ? StrokeType.X : StrokeType.I;
      var strokes = teamData.strokes[i];
      if (pts == 100 && data.settings.drawZ) {
        strokes += teamData.strokes[4] * 5;
      }
      return GestureDetector(
          key: Key("add${pts}_$teamId"),
          onTap: () => dialogs.onTap(teamId, pts),
          child:
              SchieberStrokes(type, strokes, shaded: data.settings.bigScore));
    }

    strokes20() {
      return Positioned(
        width: width * 0.6,
        height: strokeHeight,
        top: top3,
        left: hMargin,
        child: strokesBox(20),
      );
    }

    strokes50() {
      if (data.settings.drawZ) {
        var dx = width - 2 * hMargin;
        var dy = height - 2 * top1 - strokeHeight;
        var angle = -atan2(dy, dx) / 2 / pi;

        return Positioned(
            width: strokesWidth,
            height: strokeHeight,
            top: top2 * 1.1,
            left: hMargin * 4.0,
            child: RotationTransition(
                turns: AlwaysStoppedAnimation(angle), child: strokesBox(50)));
      }

      return Positioned(
        width: strokesWidth,
        height: strokeHeight,
        top: top2,
        left: hMargin,
        child: strokesBox(50),
      );
    }

    strokes100() {
      return Positioned(
        width: data.settings.drawZ ? width * 0.8 : strokesWidth,
        height: strokeHeight,
        top: top1,
        left: hMargin,
        child: strokesBox(100),
      );
    }

    strokes500() {
      if (data.settings.drawZ) {
        return const SizedBox.shrink();
      }
      return Positioned(
        width: width * 0.4,
        height: strokeHeight,
        top: top1,
        right: hMargin,
        child: SchieberStrokes(StrokeType.V, teamData.strokes[4],
            shaded: data.settings.bigScore),
      );
    }

    remaining(bool add) {
      if (data.settings.bigScore) {
        return const SizedBox.shrink();
      }
      if (add) {
        return Positioned(
            height: strokeHeight,
            top: (top1 + strokeHeight),
            right: hMargin,
            width: numberWidth,
            child: GestureDetector(
              key: Key("add1_$teamId"),
              onTap: () => dialogs.onTap(teamId, 1),
              child: Center(
                  child: Text(
                "${teamData.strokes[0]}",
                textScaler: const TextScaler.linear(3),
                textAlign: TextAlign.right,
              )),
            ));
      } else {
        return Positioned(
            top: (top1 + strokeHeight) + strokeHeight * 0.75,
            right: hMargin,
            width: numberWidth,
            height: strokeHeight / 2,
            child: GestureDetector(
              key: Key("subtract1_$teamId"),
              onTap: () => dialogs.onTap(teamId, -1),
              child: const Text(""),
            ));
      }
    }

    final addButton = Positioned(
        height: strokeHeight,
        top: 2 * (top1 + strokeHeight),
        right: hMargin,
        width: width * 0.2,
        child: GestureDetector(
          key: Key("add_$teamId"),
          onTap: () => dialogs..addPoints(teamId),
          child: SvgPicture.asset('assets/actions/add.svg'),
        ));

    return SizedBox(
      width: double.infinity,
      child: Stack(children: [
        Progress(progress(), flip: false),
        Progress(progress(), flip: true),
        backgroundZ(),
        teamName,
        strokes20(),
        strokes50(),
        strokes100(),
        strokes500(),
        remaining(true),
        remaining(false),
        teamPoints(),
        addButton,
      ]),
    );
  }
}
