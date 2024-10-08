import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/dialog/statistics_dialog.dart';
import 'package:jasstafel/common/dialog/string_dialog.dart';
import 'package:jasstafel/common/list_board/list_board_utils.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/common/widgets/board_list_with_fab.dart';
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

    footer() {
      List<String> list = ['T'];
      for (var i = 0; i < data.settings.players; i++) {
        list.add('${data.score.total(i)}');
      }
      return rowFooter(list, context: context);
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
      return defaultRow(list,
          rowNo: rowNo, context: context, pointsFunction: _guggitalerDialog);
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
      body: BoardListWithFab(
        header: rowHeader(
            playerNames: data.score.playerName,
            players: data.settings.players,
            headerFunction: _stringDialog,
            context: context),
        rows: rows,
        footer: footer(),
        floatingActionButtons: [
          FloatingActionButton(
              heroTag: "add_round",
              onPressed: () => _guggitalerDialog(),
              tooltip: context.l10n.addRound,
              child: const Icon(Icons.add))
        ],
      ),
    );
  }

  void _stringDialog(player) async {
    var controller = TextEditingController(text: data.score.playerName[player]);

    final input = await stringDialogBuilder(context, controller,
        title: context.l10n.playerName);
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
