import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jasstafel/coiffeur/data/coiffeur_data.dart';
import 'package:jasstafel/coiffeur/dialog/coiffeur_type_dialog.dart';
import 'package:jasstafel/coiffeur/widgets/coiffeur_type_cell.dart';
import 'package:jasstafel/coiffeur/widgets/coiffeur_cell.dart';
import 'package:jasstafel/coiffeur/widgets/coiffeur_row.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/dialog/points_dialog.dart';
import 'package:jasstafel/common/dialog/string_dialog.dart';
import 'package:jasstafel/common/widgets/board_title.dart';
import 'package:jasstafel/common/localization.dart';
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
  var state = BoardData(CoiffeurData(), CoiffeurSettingsKeys().data);

  void restoreData() async {
    state = await state.load() as BoardData<CoiffeurData>;
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

    state.data.settings.fromPrefService(context);

    return Scaffold(
      appBar: AppBar(
        title: BoardTitle(Board.coiffeur, context),
        actions: [
          WhoIsNextButton(
              context,
              state.data.teamName
                  .sublist(0, state.data.settings.threeTeams ? 3 : 2),
              state.data.rounds()),
          IconButton(
              onPressed: () => setState(() => state.reset()),
              icon: const Icon(Icons.delete)),
          SettingsButton(
              const CoiffeurSettingsScreen(),
              context,
              () =>
                  setState(() => state.data.settings.fromPrefService(context))),
        ],
      ),
      body: Column(
        children: _createRows,
      ),
    );
  }

  List<CoiffeurRow> get _createRows {
    var list = [_createHeader];
    for (var i = 0; i < state.data.settings.rows; i++) {
      list.add(_createRow(i));
    }
    list.add(_createFooter);
    return list;
  }

  CoiffeurRow get _createHeader {
    Widget teamWidget(team) {
      return CoiffeurCell(
        state.data.teamName[team],
        onTap: () {
          _stringDialog(team);
        },
      );
    }

    var cells = [
      CoiffeurCell(
        context.l10n.noOfRounds(state.data.rounds()),
        onTap: () {},
        leftBorder: false,
        textScaleFactor: 1.0,
      ),
      teamWidget(0),
      teamWidget(1),
    ];

    String durationString() {
      var dur = state.commonData.duration();
      if (dur != null) {
        return context.l10n.duration(dur);
      }
      return "";
    }

    if (state.data.settings.threeTeams) {
      cells.add(teamWidget(2));
    } else if (state.data.settings.thirdColumn) {
      cells.add(CoiffeurCell(
        durationString(),
        textScaleFactor: 1.0,
      ));
    }
    return CoiffeurRow(cells);
  }

  CoiffeurRow _createRow(int i) {
    Widget teamWidget(team, row) {
      return CoiffeurPointsCell(
        state.data.points(row, team),
        match: state.data.match(row, team),
        scratch: state.data.rows[row].scratched(team),
        onTap: () {
          _pointsDialog(team, row);
        },
      );
    }

    var cells = [
      CoiffeurTypeCell(
        state.data.rows[i].factor,
        state.data.rows[i].type,
        context,
        onLongPress: () => _coiffeurTypeDialog(i),
      ),
      teamWidget(0, i),
      teamWidget(1, i),
    ];
    if (state.data.settings.threeTeams) {
      cells.add(teamWidget(2, i));
    } else if (state.data.settings.thirdColumn) {
      cells.add(CoiffeurPointsCell(state.data.diff(i)));
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
      CoiffeurPointsCell(state.data.total(0)),
      CoiffeurPointsCell(state.data.total(1)),
    ];
    if (state.data.settings.threeTeams || state.data.settings.thirdColumn) {
      cells.add(
        CoiffeurPointsCell(state.data.total(2)),
      );
    }

    return CoiffeurRow(cells, topBorder: true);
  }

  void _stringDialog(team) async {
    var controller = TextEditingController(text: state.data.teamName[team]);

    final input = await stringDialogBuilder(context, controller);
    if (input == null) return; // empty name not allowed
    setState(() {
      state.data.teamName[team] = input;
      state.save();
    });
  }

  void _pointsDialog(team, row) async {
    var controller = TextEditingController();
    if (state.data.points(row, team) == null ||
        state.data.rows[row].scratched(team)) {
      controller.text = "";
    } else {
      controller.text = state.data.rows[row].pts[team].toString();
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
                    controller.text = state.data.settings.match.toString();
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
      if (state.data.rounds() == 0) {
        state.commonData.firstPoints();
      }
      if (input.scratch) {
        state.data.rows[row].scratch(team);
      } else {
        state.data.rows[row].pts[team] = input.value;
      }
      state.save();
    });
  }

  void _coiffeurTypeDialog(row) async {
    var controller = TextEditingController(text: state.data.rows[row].type);

    var title = state.data.settings.customFactor
        ? context.l10n.xRound(row + 1)
        : context.l10n.xTimes(row + 1);

    final input = await coiffeurTypeDialogBuilder(context, title, controller,
        state.data.rows[row].factor, state.data.settings.customFactor);
    if (input == null || input.factor == 0 || input.type.isEmpty) {
      return; // empty name not allowed
    }
    setState(() {
      state.data.rows[row].factor = input.factor;
      state.data.rows[row].type = input.type;
      state.save();
    });
  }
}
