import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jasstafel/coiffeur/data/coiffeur_score.dart';
import 'package:jasstafel/coiffeur/dialog/coiffeur_info.dart';
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
  Widget build(BuildContext context) {
    developer.log('build', name: 'jasstafel coiffeur');

    return Scaffold(
      appBar: AppBar(
        title: BoardTitle(Board.coiffeur, context),
        actions: [
          WhoIsNextButton(
              context,
              data.score.teamName.sublist(0, data.settings.threeTeams ? 3 : 2),
              data.score.noOfRounds(),
              data.common.whoIsNext,
              () => data.save()),
          CoiffeurInfoButton(context, data),
          DeleteButton(
            context,
            () => setState(() => data.reset()),
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
    Widget teamWidget(team) {
      return CoiffeurCell(
        data.score.teamName[team],
        onTap: () {
          _stringDialog(team);
        },
      );
    }

    var cells = [
      CoiffeurCell(
        context.l10n.noOfRounds(data.score.noOfRounds()),
        onTap: () {},
        leftBorder: false,
        textScaleFactor: 1.0,
      ),
      teamWidget(0),
      teamWidget(1),
    ];

    if (data.settings.threeTeams) {
      cells.add(teamWidget(2));
    } else if (data.settings.thirdColumn) {
      cells.add(CoiffeurCell(
        data.common.timestamps.elapsed(context),
        textScaleFactor: 1.0,
      ));
    }
    return CoiffeurRow(cells);
  }

  CoiffeurRow _createRow(int i) {
    Widget teamWidget(team, row) {
      return CoiffeurPointsCell(
        data.score.points(row, team),
        onTap: () {
          _pointsDialog(team, row);
        },
        key: Key("$team:$row"),
      );
    }

    var cells = [
      CoiffeurTypeCell(data, i, () => setState(() {})),
      teamWidget(0, i),
      teamWidget(1, i),
    ];
    if (data.settings.threeTeams) {
      cells.add(teamWidget(2, i));
    } else if (data.settings.thirdColumn) {
      cells.add(CoiffeurPointsCell.number(data.score.diff(i)));
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
      CoiffeurPointsCell.number(data.score.total(0), key: const Key("sum_0")),
      CoiffeurPointsCell.number(data.score.total(1), key: const Key("sum_1")),
    ];
    if (data.settings.threeTeams || data.settings.thirdColumn) {
      cells.add(
        CoiffeurPointsCell.number(data.score.total(2), key: const Key("sum_2")),
      );
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
                      controller.text =
                          (157 - int.parse(controller.text)).toString();
                    } on FormatException {
                      controller.text = "157";
                    }
                  },
                  key: const Key('157-x'),
                  child: SvgPicture.asset("assets/actions/157-x.svg")))
        ]));

    final input =
        await pointsDialogBuilder(context, controller, title: titleWidget);
    if (input == null) return; // pressed anywhere outside dialog
    setState(() {
      if (data.score.noOfRounds() == 0) {
        data.common.firstPoints();
      }
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
