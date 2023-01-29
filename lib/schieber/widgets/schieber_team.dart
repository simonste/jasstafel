import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/schieber/data/schieber_score.dart';
import 'package:jasstafel/schieber/widgets/schieber_background_z.dart';
import 'package:jasstafel/schieber/widgets/schieber_progress.dart';
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

  Widget _team(int teamId, data, BuildContext context) {
    final height = MediaQuery.of(context).size.height / 2;
    final width = MediaQuery.of(context).size.width;

    final teamData = data.score.team[teamId];
    final pts = teamData.sum();
    final progress = pts / data.score.team[teamId].goalPoints;
    final hMargin = width * 0.05;
    final strokeHeight = height * 0.2;
    final strokesWidth = width * 0.4;
    final numberWidth = width * 0.2;

    final top1 = height * 0.1;
    final top2 = top1 + (top1 + strokeHeight);
    final top3 = top2 + (top1 + strokeHeight);

    final teamName = Positioned(
      top: height * 0.01,
      left: width * 0.01,
      child: GestureDetector(
          onTap: () => dialogs.editTeamName(teamId),
          child: Text(teamData.name, textScaleFactor: 2)),
    );
    teamPoints() {
      if (data.settings.bigScore) {
        return Center(
            child: Text("$pts", textScaleFactor: 4, key: Key("sum_$teamId")));
      }
      return Positioned(
        top: height * 0.01,
        right: width * 0.01,
        child: Text("$pts", textScaleFactor: 2, key: Key("sum_$teamId")),
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

    strokes20() {
      return Positioned(
        key: Key("add20_$teamId"),
        width: strokesWidth,
        height: strokeHeight,
        top: top3,
        left: hMargin,
        child: GestureDetector(
            onTap: () => dialogs.onTap(teamId, 20),
            child: SchieberStrokes(
                StrokeType.I, teamData.strokes[1], data.settings.bigScore)),
      );
    }

    strokes50() {
      var strokesBox = GestureDetector(
          onTap: () => dialogs.onTap(teamId, 50),
          child: SchieberStrokes(
              StrokeType.X, teamData.strokes[2], data.settings.bigScore));

      if (data.settings.drawZ) {
        var dx = width - 2 * hMargin;
        var dy = height - 2 * top1 - strokeHeight;
        var angle = -atan2(dy, dx) / 2 / pi;

        return Positioned(
            key: Key("add50_$teamId"),
            width: strokesWidth,
            height: strokeHeight,
            top: top2 * 1.1,
            left: hMargin * 4.5,
            child: RotationTransition(
                turns: AlwaysStoppedAnimation(angle), child: strokesBox));
      }

      return Positioned(
        key: Key("add50_$teamId"),
        width: strokesWidth,
        height: strokeHeight,
        top: top2,
        left: hMargin,
        child: strokesBox,
      );
    }

    strokes100() {
      var strokes = teamData.strokes[3];
      if (data.settings.drawZ) {
        strokes += teamData.strokes[4] * 5;
      }

      return Positioned(
        key: Key("add100_$teamId"),
        width: strokesWidth,
        height: strokeHeight,
        top: top1,
        left: hMargin,
        child: GestureDetector(
            onTap: () => dialogs.onTap(teamId, 100),
            child:
                SchieberStrokes(StrokeType.I, strokes, data.settings.bigScore)),
      );
    }

    strokes500() {
      if (data.settings.drawZ) {
        return const SizedBox.shrink();
      }
      return Positioned(
        width: strokesWidth,
        height: strokeHeight,
        top: top1,
        right: hMargin,
        child: SchieberStrokes(
            StrokeType.V, teamData.strokes[4], data.settings.bigScore),
      );
    }

    remaining(bool add) {
      if (data.settings.bigScore) {
        return const SizedBox.shrink();
      }
      if (add) {
        return Positioned(
            key: Key("add1_$teamId"),
            height: strokeHeight,
            top: (top1 + strokeHeight),
            right: hMargin,
            width: numberWidth,
            child: GestureDetector(
              onTap: () => dialogs.onTap(teamId, 1),
              child: Center(
                  child: Text(
                "${teamData.strokes[0]}",
                textScaleFactor: 3,
                textAlign: TextAlign.right,
              )),
            ));
      } else {
        return Positioned(
            key: Key("subtract1_$teamId"),
            top: (top1 + strokeHeight) + strokeHeight * 0.75,
            right: hMargin,
            width: numberWidth,
            height: strokeHeight / 2,
            child: GestureDetector(
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
          onTap: () => dialogs..addPoints(teamId),
          child: SvgPicture.asset('assets/actions/add.svg'),
        ));

    return SizedBox(
      width: double.infinity,
      child: Stack(children: [
        SchieberProgress(progress, false),
        SchieberProgress(progress, true),
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
