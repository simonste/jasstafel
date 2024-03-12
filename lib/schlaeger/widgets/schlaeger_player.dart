import 'package:flutter/material.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/common/widgets/progress.dart';
import 'package:jasstafel/schieber/widgets/schieber_strokes.dart';
import 'package:jasstafel/schlaeger/data/schlaeger_score.dart';
import 'package:jasstafel/settings/schlaeger_settings.g.dart';

class Margins {
  double? top;
  double? bottom;
  double? left;
  double? right;

  Margins(
      {required double vertical,
      required double horizontal,
      bool top = true,
      bool left = true})
      : top = (top ? vertical : null),
        bottom = (top ? null : vertical),
        left = (left ? horizontal : null),
        right = (left ? null : horizontal);
}

// ignore: empty_constructor_bodies
class PositionedMargin extends Positioned {
  PositionedMargin({required Margins margins, required super.child, super.key})
      : super(
            top: margins.top,
            bottom: margins.bottom,
            left: margins.left,
            right: margins.right);
}

class SchlaegerPlayer extends StatelessWidget {
  final BoardData<SchlaegerSettings, SchlaegerScore> data;
  final int? playerId;
  final Function(int) editNameDialog;
  final Function({int? editRowNo}) editRoundDialog;
  final int position;

  const SchlaegerPlayer(
      this.playerId, this.data, this.editNameDialog, this.editRoundDialog,
      {required this.position, super.key});

  @override
  Widget build(BuildContext context) {
    decoration() {
      if (position % 2 == 0) {
        return const BoxDecoration(
            border: Border(
                right: BorderSide(
          color: Colors.white,
        )));
      }
      return const BoxDecoration();
    }

    return Expanded(
        child: Container(
            decoration: decoration(),
            child: playerId == null
                ? const SizedBox(child: Stack())
                : _team(playerId!, data, context)));
  }

  Widget _team(int playerId, BoardData<SchlaegerSettings, SchlaegerScore> data,
      BuildContext context) {
    final height = MediaQuery.of(context).size.height / 2;
    final width = MediaQuery.of(context).size.width / 2;
    final landscape = width > height;

    final pts = data.score.total(playerId);
    var scoreString = "";
    var strokes = 0;
    var circles = 0;
    for (var row in data.score.rows) {
      var str = " ${row.pts[playerId]}";
      if (str == " null") {
        str = " x";
      } else if (row.pts[playerId]! > 0) {
        strokes += row.pts[playerId]!;
      } else if (row.pts[playerId]! < 0) {
        circles -= row.pts[playerId]!;
      }
      scoreString += str;
    }

    progress() {
      switch (GoalType.values[data.settings.goalType]) {
        case GoalType.points:
          return (pts / data.settings.goalPoints);
        case GoalType.rounds:
          return (data.score.noOfRounds() / data.settings.goalRounds);
        case GoalType.noGoal:
          return 0.0;
      }
    }

    final a = position < 2;
    final b = position % 2 != 0;
    final v1 = height * 0.01;
    final h1 = width * 0.05;

    final nameMargin = Margins(vertical: v1, horizontal: h1, top: a);
    final scoresMargin = landscape
        ? Margins(vertical: v1, horizontal: width * 0.5, top: a)
        : Margins(vertical: height * 0.1, horizontal: h1, top: a);
    final pointsMargin =
        Margins(vertical: v1, horizontal: 2 * h1, top: !a, left: b);
    final plusMargin = landscape
        ? Margins(vertical: height * 0.2, horizontal: 5 * h1)
        : Margins(vertical: height * 0.3, horizontal: 2 * h1);
    final minusMargin = landscape
        ? Margins(vertical: height * 0.25, horizontal: 12 * h1)
        : Margins(vertical: height * 0.5, horizontal: 2 * h1);

    return SizedBox(
      width: double.infinity,
      child: Stack(children: [
        Progress(
          progress(),
          bottom: position < 2,
          flip: position % 2 != 0,
        ),
        PositionedMargin(
          margins: nameMargin,
          child: GestureDetector(
              onTap: () => editNameDialog(playerId),
              child: Text(data.score.playerName[playerId],
                  textScaler: const TextScaler.linear(2))),
        ),
        PositionedMargin(
          margins: plusMargin,
          child: SizedBox(
              height: landscape ? height * 0.4 : height * 0.2,
              child: SchieberStrokes(
                StrokeType.I,
                strokes,
                widthFactor: landscape ? 0.004 : 0.01,
              )),
        ),
        PositionedMargin(
          margins: minusMargin,
          child: Text("o" * circles, textScaler: const TextScaler.linear(3)),
        ),
        PositionedMargin(
          margins: scoresMargin,
          child: GestureDetector(
              onLongPress: () =>
                  editRoundDialog(editRowNo: data.score.rows.length - 1),
              key: Key("scores_$playerId"),
              child: Text(scoreString)),
        ),
        PositionedMargin(
          margins: pointsMargin,
          child: GestureDetector(
              onLongPress: () =>
                  editRoundDialog(editRowNo: data.score.rows.length - 1),
              child: Text("$pts",
                  textScaler: const TextScaler.linear(6),
                  key: Key("sum_$playerId"))),
        ),
      ]),
    );
  }
}
