import 'package:flutter/material.dart';
import 'package:jasstafel/coiffeur/data/coiffeurdata.dart';
import 'package:jasstafel/coiffeur/widgets/coiffeurtype.dart';
import 'package:jasstafel/coiffeur/widgets/coiffeurcell.dart';
import 'package:jasstafel/coiffeur/widgets/coiffeurrow.dart';
import 'package:jasstafel/common/dialog/pointsdialog.dart';
import 'package:jasstafel/common/dialog/stringdialog.dart';

class Coiffeur extends StatefulWidget {
  const Coiffeur({super.key});

  @override
  State<Coiffeur> createState() => _CoiffeurState();
}

class _CoiffeurState extends State<Coiffeur> {
  var state = CoiffeurState();

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
        title: const Text("Coiffeur"),
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
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings))
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
      return Expanded(
          child: InkWell(
              onTap: () {
                _stringDialog(team);
              },
              child: CoiffeurCell(state.teamName[team])));
    }

    var cells = [
      const Expanded(
          child: Text(
        "2 Runden",
        textAlign: TextAlign.center,
      )),
      teamWidget(0),
      teamWidget(1),
    ];
    if (state.settings.threeTeams) {
      cells.add(teamWidget(2));
    } else if (state.settings.thirdColumn) {
      cells.add(Expanded(child: CoiffeurCell("")));
    }
    return CoiffeurRow(cells);
  }

  CoiffeurRow _createRow(int i) {
    Widget teamWidget(team, row) {
      return Expanded(
          child: InkWell(
              onTap: () {
                _pointsDialog(team, row);
              },
              child: CoiffeurPointsCell(state.rows[row].pts[team])));
    }

    var cells = [
      Expanded(
          child:
              InkWell(onTap: () {}, child: CoiffeurType(state.rows[i].type))),
      teamWidget(0, i),
      teamWidget(1, i),
    ];
    if (state.settings.threeTeams) {
      cells.add(teamWidget(2, i));
    }
    if (state.settings.thirdColumn) {
      cells.add(Expanded(child: CoiffeurPointsCell(state.diff(i))));
    }

    return CoiffeurRow(cells, topBorder: true);
  }

  CoiffeurRow get _createFooter {
    var cells = [
      const Expanded(
        child: Text(
          "Total",
          textAlign: TextAlign.center,
          textScaleFactor: 2,
        ),
      ),
      Expanded(child: CoiffeurPointsCell(state.total(0))),
      Expanded(child: CoiffeurPointsCell(state.total(1))),
    ];
    if (state.settings.threeTeams || state.settings.thirdColumn) {
      cells.add(
        Expanded(child: CoiffeurPointsCell(state.total(2))),
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
}