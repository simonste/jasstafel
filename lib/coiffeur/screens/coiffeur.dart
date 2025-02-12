import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jasstafel/coiffeur/data/coiffeur_score.dart';
import 'package:jasstafel/coiffeur/dialog/coiffeur_info.dart';
import 'package:jasstafel/coiffeur/widgets/coiffeur_type_cell.dart';
import 'package:jasstafel/coiffeur/widgets/coiffeur_cell.dart';
import 'package:jasstafel/coiffeur/widgets/coiffeur_row.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/data/common_data.dart';
import 'package:jasstafel/common/dialog/points_dialog.dart';
import 'package:jasstafel/common/dialog/string_dialog.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/common/widgets/board_title.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/common/widgets/delete_button.dart';
import 'package:jasstafel/common/widgets/settings_button.dart';
import 'package:jasstafel/common/widgets/who_is_next_button.dart';
import 'package:jasstafel/settings/coiffeur_settings.g.dart';
import 'coiffeur_settings_screen.dart';
import 'dart:developer' as developer;

class Coiffeur extends StatefulWidget {
  const Coiffeur({super.key});

  @override
  State<Coiffeur> createState() => _CoiffeurState();
}

class _CoiffeurState extends State<Coiffeur> {
  var data = BoardData(
      CoiffeurSettings(), CoiffeurScore(), CoiffeurSettingsKeys().data);
  final typeNameGroup = AutoSizeGroup();
  final cellGroup = AutoSizeGroup();
  Timer? updateTimer;

  void restoreData() async {
    data = await data.load() as BoardData<CoiffeurSettings, CoiffeurScore>;
    setState(() {}); // trigger widget update
  }

  @override
  void initState() {
    developer.log('init state', name: 'jasstafel coiffeur');
    super.initState();
    restoreData();
  }

  @override
  void dispose() {
    updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    developer.log('build', name: 'jasstafel coiffeur');
    data.checkGameOver(context, goalType: GoalType.rounds);
    if (updateTimer != null) {
      updateTimer!.cancel();
    }

    return Scaffold(
      appBar: TitleBar(
        board: Board.coiffeur,
        context: context,
        actions: [
          WhoIsNextButton(
              context,
              WhoIsNextButton.guessPlayerNames(data.score.teamName
                  .sublist(0, data.settings.threeTeams ? 3 : 2)),
              data.score.noOfRounds(),
              data.common.whoIsNext,
              () => data.save()),
          CoiffeurInfoButton(context, data),
          DeleteButton(
            context,
            deleteFunction: () => setState(() => data.reset()),
          ),
          SettingsButton(CoiffeurSettingsScreen(data), context,
              () => setState(() => data.settings.fromPrefService(context))),
        ],
      ),
      body: Column(
        children: _createRows,
      ),
    );
  }

  List<CoiffeurRow> get _createRows {
    var list = [_createHeader];
    for (var i = 0; i < data.settings.rows; i++) {
      list.add(_createRow(i));
    }
    list.add(_createFooter);
    return list;
  }

  CoiffeurRow get _createHeader {
    final teamNameGroup = AutoSizeGroup();

    Widget teamWidget(team) {
      return CoiffeurCell(
        data.score.teamName[team],
        onTap: () {
          _stringDialog(team);
        },
        maxLines: 2,
        group: teamNameGroup,
      );
    }

    final separateCellForElapsedTime =
        data.settings.thirdColumn && !data.settings.threeTeams;
    var cells = [
      CoiffeurCell(
        separateCellForElapsedTime
            ? context.l10n.noOfRounds(data.score.noOfRounds())
            : "${context.l10n.noOfRounds(data.score.noOfRounds())}\n${data.common.timestamps.elapsed(context)}",
        leftBorder: false,
        group: typeNameGroup,
        maxLines: separateCellForElapsedTime ? 1 : 2,
      ),
      teamWidget(0),
      teamWidget(1),
    ];

    if (data.settings.threeTeams) {
      cells.add(teamWidget(2));
    } else if (data.settings.thirdColumn) {
      cells.add(CoiffeurCell(
        key: const Key('elapsed'),
        data.common.timestamps.elapsed(context),
        maxLines: 2,
        group: typeNameGroup,
      ));

      final updateInterval = 60000 / const Duration(minutes: 1).elapsed ~/ 2;
      updateTimer =
          Timer(Duration(milliseconds: updateInterval), () => setState(() {}));
    }
    return CoiffeurRow(cells);
  }

  CoiffeurRow _createRow(int i) {
    final rowCompleted =
        data.settings.greyCompletedRows && data.score.diff(i) != null;

    Widget teamWidget(team, row) {
      return CoiffeurPointsCell(data.score.points(row, team), onTap: () {
        _pointsDialog(team, row);
      }, key: Key("$team:$row"), group: cellGroup, grey: rowCompleted);
    }

    var cells = [
      CoiffeurTypeCell(
        data: data,
        row: i,
        updateParent: () => setState(() {}),
        group: typeNameGroup,
        grey: rowCompleted,
      ),
      teamWidget(0, i),
      teamWidget(1, i),
    ];
    if (data.settings.threeTeams) {
      cells.add(teamWidget(2, i));
    } else if (data.settings.thirdColumn) {
      final diff = data.score.diff(i);
      final alignment =
          ((diff ?? 0) > 0) ? Alignment.centerLeft : Alignment.centerRight;
      cells.add(CoiffeurPointsCell.number(diff,
          alignment: alignment, grey: rowCompleted));
    }

    return CoiffeurRow(cells, topBorder: true);
  }

  CoiffeurRow get _createFooter {
    var highlight = List.filled(3, false);
    final winner = CoiffeurInfo(data.settings, data.score).winner().winner;
    for (final w in winner) {
      highlight[w] = true;
    }

    totalCell(int i) {
      return CoiffeurPointsCell.number(
        data.score.total(i),
        highlight: highlight[i],
        group: cellGroup,
        key: Key("sum_$i"),
      );
    }

    var cells = [
      CoiffeurCell(context.l10n.total, leftBorder: false, group: typeNameGroup),
      totalCell(0),
      totalCell(1),
    ];
    if (data.settings.threeTeams || data.settings.thirdColumn) {
      cells.add(totalCell(2));
    }

    return CoiffeurRow(cells, topBorder: true);
  }

  void _stringDialog(team) async {
    var controller = TextEditingController(text: data.score.teamName[team]);

    final input = await stringDialogBuilder(context, controller);
    if (input == null) return; // empty name not allowed
    setState(() {
      data.score.teamName[team] = input;
      data.save();
    });
  }

  void _pointsDialog(team, row) async {
    var controller = TextEditingController();
    if (data.score.rows[row].pts[team].pts == null ||
        data.score.rows[row].pts[team].scratched) {
      controller.text = "";
    } else {
      controller.text = data.score.rows[row].pts[team].pts.toString();
    }

    var titleWidget = SizedBox(
        height: 32,
        child: Row(children: [
          Text(context.l10n.points),
          const Expanded(child: SizedBox.expand()),
          Expanded(
              child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop(IntValue(null, scratch: true));
                  },
                  key: const Key('scratch'),
                  child: SvgPicture.asset("assets/actions/scratch.svg"))),
          Expanded(
              child: InkWell(
                  onTap: () {
                    controller.text = data.settings.match.toString();
                  },
                  key: const Key('match'),
                  child: SvgPicture.asset("assets/actions/match.svg"))),
          Expanded(
              child: InkWell(
                  onTap: () {
                    try {
                      controller.text = (roundPoints(data.settings.match) -
                              int.parse(controller.text))
                          .toString();
                    } on FormatException {
                      controller.text = "${roundPoints(data.settings.match)}";
                    }
                  },
                  key: const Key('157-x'),
                  child: SvgPicture.asset("assets/actions/157-x.svg")))
        ]));

    final input =
        await pointsDialogBuilder(context, controller, title: titleWidget);
    if (input == null) return; // pressed anywhere outside dialog
    setState(() {
      data.common.timestamps.addPoints(data.score.totalPoints());
      if (input.scratch) {
        data.score.rows[row].pts[team].scratch();
      } else {
        data.score.rows[row].pts[team].reset();
        data.score.rows[row].pts[team].pts = input.value;
        if (input.value == data.settings.match) {
          data.score.rows[row].pts[team].match = true;
        }
      }
      data.save();
    });
  }
}
