import 'package:flutter/material.dart';
import 'package:jasstafel/coiffeur/data/coiffeurdata.dart';
import 'package:jasstafel/coiffeur/dialog/coiffeurtypedialog.dart';
import 'package:jasstafel/coiffeur/widgets/coiffeurtypecell.dart';
import 'package:jasstafel/coiffeur/widgets/coiffeurcell.dart';
import 'package:jasstafel/coiffeur/widgets/coiffeurrow.dart';
import 'package:jasstafel/common/dialog/pointsdialog.dart';
import 'package:jasstafel/common/dialog/stringdialog.dart';
import 'package:jasstafel/common/widgets/boardtitle.dart';
import 'package:jasstafel/common/localization.dart';

import 'coiffeursettings.dart';

class Coiffeur extends StatefulWidget {
  const Coiffeur({super.key});

  @override
  State<Coiffeur> createState() => _CoiffeurState();
}

class _CoiffeurState extends State<Coiffeur> {
  var state = CoiffeurData();

  void restoreData() async {
    state = await state.load();
    setState(() {}); // trigger widget update
  }

  @override
  void initState() {
    super.initState();
    restoreData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BoardTitle(Board.coiffeur, context),
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  for (var row in state.rows) {
                    row.reset();
                  }
                  state.save();
                });
              },
              icon: const Icon(Icons.delete)),
          IconButton(
              onPressed: () {
                _openSettings();
              },
              icon: const Icon(Icons.settings))
        ],
      ),
      body: Column(
        children: _createRows,
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return const CoiffeurSettingsScreen();
        },
      ),
    ).then((value) {
      setState(() {
        state.settings.fromPrefService(context);
      });
    });
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
        state.teamName[team],
        onTap: () {
          _stringDialog(team);
        },
      );
    }

    var cells = [
      CoiffeurCell(
        context.l10n.noOfRounds(state.rounds()),
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

    if (state.settings.threeTeams) {
      cells.add(teamWidget(2));
    } else if (state.settings.thirdColumn) {
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
        state.rows[row].pts[team],
        onTap: () {
          _pointsDialog(team, row);
        },
      );
    }

    var cells = [
      CoiffeurTypeCell(
        state.rows[i].factor,
        state.rows[i].type,
        onLongPress: () {
          _coiffeurTypeDialog(i);
        },
      ),
      teamWidget(0, i),
      teamWidget(1, i),
    ];
    if (state.settings.threeTeams) {
      cells.add(teamWidget(2, i));
    } else if (state.settings.thirdColumn) {
      cells.add(CoiffeurPointsCell(state.diff(i)));
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
      CoiffeurPointsCell(state.total(0)),
      CoiffeurPointsCell(state.total(1)),
    ];
    if (state.settings.threeTeams || state.settings.thirdColumn) {
      cells.add(
        CoiffeurPointsCell(state.total(2)),
      );
    }

    return CoiffeurRow(cells, topBorder: true);
  }

  void _stringDialog(team) async {
    var controller = TextEditingController(text: state.teamName[team]);

    final input = await stringDialogBuilder(context, controller);
    if (input == null) return; // empty name not allowed
    setState(() {
      state.teamName[team] = input;
      state.save();
    });
  }

  void _pointsDialog(team, row) async {
    var controller = TextEditingController();
    controller.text = (state.rows[row].pts[team] ?? "").toString();

    final input = await pointsDialogBuilder(context, controller);
    if (input == null) return; // pressed anywhere outside dialog
    setState(() {
      state.rows[row].pts[team] = input.value;
      state.save();
    });
  }

  void _coiffeurTypeDialog(row) async {
    var controller = TextEditingController(text: state.rows[row].type);

    final input = await coiffeurTypeDialogBuilder(
        context, controller, state.rows[row].factor);
    if (input == null || input.factor == 0) return; // empty name not allowed
    setState(() {
      state.rows[row].factor = input.factor;
      state.rows[row].type = input.type;
      state.save();
    });
  }
}
