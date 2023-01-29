import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jasstafel/coiffeur/data/coiffeur_score.dart';
import 'package:jasstafel/coiffeur/widgets/coiffeur_type_cell.dart';
import 'package:jasstafel/coiffeur/widgets/coiffeur_cell.dart';
import 'package:jasstafel/coiffeur/widgets/coiffeur_row.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/dialog/points_dialog.dart';
import 'package:jasstafel/common/dialog/string_dialog.dart';
import 'package:jasstafel/common/widgets/board_title.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/common/widgets/delete_button.dart';
import 'package:jasstafel/common/widgets/settings_button.dart';
import 'package:jasstafel/common/widgets/who_is_next_button.dart';
import 'package:jasstafel/settings/coiffeur_settings.g.dart';
import 'coiffeur_settings.dart';
import 'dart:developer' as developer;

class Coiffeur extends StatefulWidget {
  const Coiffeur({super.key});

  @override
  State<Coiffeur> createState() => _CoiffeurState();
}

class _CoiffeurState extends State<Coiffeur> {
  var state = BoardData(
      CoiffeurSettings(), CoiffeurScore(), CoiffeurSettingsKeys().data);

  void restoreData() async {
    state = await state.load() as BoardData<CoiffeurSettings, CoiffeurScore>;
    setState(() {}); // trigger widget update
  }

  @override
  void initState() {
    developer.log('init state', name: 'jasstafel coiffeur');
    super.initState();
    restoreData();
  }

  @override
  Widget build(BuildContext context) {
    developer.log('build', name: 'jasstafel coiffeur');
    state.score.setSettings(state.settings);

    return Scaffold(
      appBar: AppBar(
        title: BoardTitle(Board.coiffeur, context),
        actions: [
          WhoIsNextButton(
              context,
              state.score.teamName
                  .sublist(0, state.settings.threeTeams ? 3 : 2),
              state.score.noOfRounds(),
              state.common.whoIsNext,
              () => state.save()),
          DeleteButton(
            context,
            () => setState(() => state.reset()),
          ),
          SettingsButton(CoiffeurSettingsScreen(state), context,
              () => setState(() => state.settings.fromPrefService(context))),
        ],
      ),
      body: Column(
        children: _createRows,
      ),
    );
  }

  List<CoiffeurRow> get _createRows {
    var list = [_createHeader];
    for (var i = 0; i < state.settings.rows; i++) {
      list.add(_createRow(i));
    }
    list.add(_createFooter);
    return list;
  }

  CoiffeurRow get _createHeader {
    Widget teamWidget(team) {
      return CoiffeurCell(
        state.score.teamName[team],
        onTap: () {
          _stringDialog(team);
        },
      );
    }

    var cells = [
      CoiffeurCell(
        context.l10n.noOfRounds(state.score.noOfRounds()),
        onTap: () {},
        leftBorder: false,
        textScaleFactor: 1.0,
      ),
      teamWidget(0),
      teamWidget(1),
    ];

    if (state.settings.threeTeams) {
      cells.add(teamWidget(2));
    } else if (state.settings.thirdColumn) {
      cells.add(CoiffeurCell(
        state.common.timestamps.elapsed(context),
        textScaleFactor: 1.0,
      ));
    }
    return CoiffeurRow(cells);
  }

  CoiffeurRow _createRow(int i) {
    Widget teamWidget(team, row) {
      return CoiffeurPointsCell(
        state.score.points(row, team),
        onTap: () {
          _pointsDialog(team, row);
        },
      );
    }

    var cells = [
      CoiffeurTypeCell(state, i, () => setState(() {})),
      teamWidget(0, i),
      teamWidget(1, i),
    ];
    if (state.settings.threeTeams) {
      cells.add(teamWidget(2, i));
    } else if (state.settings.thirdColumn) {
      cells.add(CoiffeurPointsCell.number(state.score.diff(i)));
    }

    return CoiffeurRow(cells, topBorder: true);
  }

  CoiffeurRow get _createFooter {
    var cells = [
      Expanded(
        child: Text(
          context.l10n.total,
          textAlign: TextAlign.center,
          textScaleFactor: 2,
        ),
      ),
      CoiffeurPointsCell.number(state.score.total(0)),
      CoiffeurPointsCell.number(state.score.total(1)),
    ];
    if (state.settings.threeTeams || state.settings.thirdColumn) {
      cells.add(
        CoiffeurPointsCell.number(state.score.total(2)),
      );
    }

    return CoiffeurRow(cells, topBorder: true);
  }

  void _stringDialog(team) async {
    var controller = TextEditingController(text: state.score.teamName[team]);

    final input = await stringDialogBuilder(context, controller);
    if (input == null) return; // empty name not allowed
    setState(() {
      state.score.teamName[team] = input;
      state.save();
    });
  }

  void _pointsDialog(team, row) async {
    var controller = TextEditingController();
    if (state.score.rows[row].pts[team].pts == null ||
        state.score.rows[row].pts[team].scratched) {
      controller.text = "";
    } else {
      controller.text = state.score.rows[row].pts[team].pts.toString();
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
                  child: SvgPicture.asset("assets/actions/scratch.svg"))),
          Expanded(
              child: InkWell(
                  onTap: () {
                    controller.text = state.settings.match.toString();
                  },
                  child: SvgPicture.asset("assets/actions/match.svg"))),
          Expanded(
              child: InkWell(
                  onTap: () {
                    try {
                      controller.text =
                          (157 - int.parse(controller.text)).toString();
                    } on FormatException {
                      controller.text = "157";
                    }
                  },
                  child: SvgPicture.asset("assets/actions/157-x.svg")))
        ]));

    final input =
        await pointsDialogBuilder(context, controller, title: titleWidget);
    if (input == null) return; // pressed anywhere outside dialog
    setState(() {
      if (state.score.noOfRounds() == 0) {
        state.common.firstPoints();
      }
      if (input.scratch) {
        state.score.rows[row].pts[team].scratch();
      } else {
        state.score.rows[row].pts[team].reset();
        state.score.rows[row].pts[team].pts = input.value;
        if (input.value == state.settings.match) {
          state.score.rows[row].pts[team].match = true;
        }
      }
      state.save();
    });
  }
}
