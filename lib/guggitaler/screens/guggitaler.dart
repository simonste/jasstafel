import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/dialog/statistics_dialog.dart';
import 'package:jasstafel/common/dialog/string_dialog.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/common/widgets/board_title.dart';
import 'package:jasstafel/common/widgets/delete_button.dart';
import 'package:jasstafel/common/widgets/settings_button.dart';
import 'package:jasstafel/common/widgets/who_is_next_button.dart';
import 'package:jasstafel/guggitaler/data/guggitaler_score.dart';
import 'package:jasstafel/guggitaler/data/guggitaler_values.dart';
import 'package:jasstafel/guggitaler/dialog/guggitaler_dialog.dart';
import 'package:jasstafel/guggitaler/screens/guggitaler_settings_screen.dart';
import 'package:jasstafel/settings/guggitaler_settings.g.dart';
import 'dart:developer' as developer;

class Guggitaler extends StatefulWidget {
  const Guggitaler({super.key});

  @override
  State<Guggitaler> createState() => _GuggitalerState();
}

class _GuggitalerState extends State<Guggitaler> {
  var data = BoardData(
      GuggitalerSettings(), GuggitalerScore(), GuggitalerSettingsKeys().data);
  Timer? updateTimer;

  void restoreData() async {
    data = await data.load() as BoardData<GuggitalerSettings, GuggitalerScore>;
    setState(() {}); // trigger widget update
  }

  @override
  void initState() {
    developer.log('init state', name: 'jasstafel guggitaler');
    super.initState();
    restoreData();
  }

  @override
  Widget build(BuildContext context) {
    developer.log('build', name: 'jasstafel guggitaler');
    data.checkGameOver(context, goalType: GoalType.noGoal);
    if (updateTimer != null) {
      updateTimer!.cancel();
    }

    rowWidget(List<String> data,
        {bool header = false,
        bool footer = false,
        bool round = false,
        int? rowNo}) {
      List<Widget> children = [
        SizedBox(
            width: 20,
            child: Text(
              data[0],
              textAlign: TextAlign.right,
            ))
      ];

      for (var i = 1; i < data.length; i++) {
        final key = footer ? Key('sum_${i - 1}') : null;
        final text = Text(
          key: key,
          data[i],
          textAlign: TextAlign.center,
          textScaleFactor: header ? 1 : 2,
        );

        if (header) {
          children.add(Expanded(
              child: InkWell(
            onTap: () => _stringDialog(i - 1),
            child: text,
          )));
        } else if (footer) {
          children.add(Expanded(
            child: text,
          ));
        } else {
          children.add(Expanded(
              child: InkWell(
            onLongPress: () => _guggitalerDialog(editRowNo: rowNo!),
            child: text,
          )));
        }
      }
      var decoration = (header || footer)
          ? BoxDecoration(color: Theme.of(context).colorScheme.secondary)
          : round
              ? BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary,
                  border: Border(
                      bottom: BorderSide(
                          color: Theme.of(context).colorScheme.onPrimary)))
              : null;

      return Container(
          height: (header || footer) ? 30 : null,
          decoration: decoration,
          child: Row(children: children));
    }

    header() {
      List<String> list = [''];
      data.score.playerName.sublist(0, data.settings.players).forEach((e) {
        list.add(e);
      });
      return rowWidget(list, header: true);
    }

    footer() {
      List<String> list = ['T'];
      for (var i = 0; i < data.settings.players; i++) {
        list.add('${data.score.total(i)}');
      }
      return rowWidget(list, footer: true);
    }

    int roundNo = 0;
    guggitalerRow(int rowNo) {
      final row = data.score.rows[rowNo];
      List<String> list = [''];
      if (row.isRound()) {
        roundNo++;
        list[0] = '$roundNo';
      }
      for (int player = 0; player < data.settings.players; player++) {
        int pts = row.sum(player);
        if (pts != 0) {
          list.add('$pts');
        } else {
          list.add('-');
        }
      }
      return rowWidget(list, rowNo: rowNo);
    }

    List<Widget> rows = [];
    for (var i = 0; i < data.score.rows.length; i++) {
      rows.add(guggitalerRow(i));
    }

    List<String> colHeader = [];
    for (var i = 0; i < GuggitalerValues.length; i++) {
      colHeader.add(GuggitalerValues.type(i, context));
    }
    List<List<String>> stats = [];
    for (var p = 0; p < data.settings.players; p++) {
      var cols = [data.score.playerName[p]];
      for (var i = 0; i < GuggitalerValues.length; i++) {
        cols.add(data.score.columnSum(p, i).toString());
      }
      stats.add(cols);
    }

    return Scaffold(
      appBar: TitleBar(
        board: Board.guggitaler,
        context: context,
        actions: [
          WhoIsNextButton(
            context,
            data.score.playerName.sublist(0, data.settings.players),
            data.score.noOfRounds(),
            data.common.whoIsNext,
            () => data.save(),
          ),
          StatisticsButton(context, data.common.timestamps.elapsed(context),
              colHeader, stats),
          DeleteButton(
            context,
            deleteFunction: () => setState(() => data.reset()),
          ),
          SettingsButton(GuggitalerSettingsScreen(data), context,
              () => setState(() => data.settings.fromPrefService(context))),
        ],
      ),
      body: Stack(children: [
        Column(children: [
          header(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: rows),
            ),
          ),
          footer()
        ]),
        Positioned(
            right: 20,
            bottom: 50,
            child: FloatingActionButton(
                heroTag: "add_round",
                onPressed: () => _guggitalerDialog(),
                tooltip: context.l10n.addRound,
                child: const Icon(Icons.add))),
      ]),
    );
  }

  void _stringDialog(player) async {
    var controller = TextEditingController(text: data.score.playerName[player]);

    final title = Text(context.l10n.playerName);
    final input = await stringDialogBuilder(context, controller, title: title);
    if (input == null) return; // empty name not allowed
    setState(() {
      data.score.playerName[player] = input;
      data.save();
    });
  }

  void _guggitalerDialog({int? editRowNo}) async {
    final input = await guggitalerDialogBuilder(context,
        playerNames: data.score.playerName.sublist(0, data.settings.players),
        row: (editRowNo != null) ? data.score.rows[editRowNo] : null);
    if (input == null) return;
    setState(() {
      data.common.timestamps.addPoints(data.score.totalPoints());
      final p = data.score.playerName.indexOf(input.player);
      var row = editRowNo ?? data.score.rows.length - 1;

      if (editRowNo == null &&
          (data.score.rows.isEmpty ||
              data.score.rows.last.sum(p) != 0 ||
              data.score.rows.last.isRound())) {
        data.score.rows.add(GuggitalerRow());
        row++;
      }
      data.score.rows[row].pts[p] = input.points;
      data.save();
    });
  }
}
