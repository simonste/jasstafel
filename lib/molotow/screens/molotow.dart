import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/dialog/player_points_dialog.dart';
import 'package:jasstafel/common/dialog/string_dialog.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/common/widgets/board_title.dart';
import 'package:jasstafel/common/widgets/delete_button.dart';
import 'package:jasstafel/common/widgets/settings_button.dart';
import 'package:jasstafel/common/widgets/who_is_next_button.dart';
import 'package:jasstafel/molotow/data/molotow_score.dart';
import 'package:jasstafel/molotow/dialog/molotow_dialog.dart';
import 'package:jasstafel/molotow/dialog/molotow_statistics.dart';
import 'package:jasstafel/molotow/screens/molotow_settings_screen.dart';
import 'package:jasstafel/settings/molotow_settings.g.dart';
import 'dart:developer' as developer;

class Molotow extends StatefulWidget {
  const Molotow({super.key});

  @override
  State<Molotow> createState() => _MolotowState();
}

class _MolotowState extends State<Molotow> {
  var data =
      BoardData(MolotowSettings(), MolotowScore(), MolotowSettingsKeys().data);
  Timer? updateTimer;

  void restoreData() async {
    data = await data.load() as BoardData<MolotowSettings, MolotowScore>;
    setState(() {}); // trigger widget update
  }

  @override
  void initState() {
    developer.log('init state', name: 'jasstafel molotow');
    super.initState();
    restoreData();
  }

  @override
  Widget build(BuildContext context) {
    developer.log('build', name: 'jasstafel molotow');
    data.checkGameOver(context,
        goalType: GoalType.values[data.settings.goalType]);
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
            onLongPress: () => _pointsDialog(editRowNo: rowNo!),
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
    molotowRow(int rowNo) {
      final row = data.score.rows[rowNo];
      List<String> list = [''];
      if (row.isRound) {
        roundNo++;
        list[0] = '$roundNo';
      }
      row.pts.sublist(0, data.settings.players).forEach((pts) {
        if (pts != null) {
          list.add('${roundedInt(pts, data.settings.rounded)}');
        } else {
          list.add('-');
        }
      });
      return rowWidget(list, round: row.isRound, rowNo: rowNo);
    }

    List<Widget> rows = [];
    for (var i = 0; i < data.score.rows.length; i++) {
      rows.add(molotowRow(i));
    }

    return Scaffold(
      appBar: AppBar(
        title: BoardTitle(Board.molotow, context),
        actions: [
          WhoIsNextButton(
            context,
            data.score.playerName.sublist(0, data.settings.players),
            data.score.noOfRounds(),
            data.common.whoIsNext,
            () => data.save(),
          ),
          MolotowStatisticsButton(context, data),
          DeleteButton(
            context,
            deleteFunction: () => setState(() => data.reset()),
          ),
          SettingsButton(MolotowSettingsScreen(data), context,
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
            right: 160,
            bottom: 50,
            child: FloatingActionButton(
                heroTag: "hand_weis",
                onPressed: () => _weisDialog(hand: true),
                tooltip: context.l10n.handWeis,
                child: SizedBox(
                    height: 40,
                    child: SvgPicture.asset('assets/actions/hand_weis.svg')))),
        Positioned(
            right: 90,
            bottom: 50,
            child: FloatingActionButton(
                heroTag: "add_round",
                onPressed: () => _pointsDialog(),
                tooltip: context.l10n.addRound,
                child: const Icon(Icons.add))),
        Positioned(
            right: 20,
            bottom: 50,
            child: FloatingActionButton(
                heroTag: "table_weis",
                onPressed: () => _weisDialog(hand: false),
                tooltip: context.l10n.tableWeis,
                child: SizedBox(
                    height: 40,
                    child: SvgPicture.asset('assets/actions/table_weis.svg')))),
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

  void _weisDialog({required bool hand}) async {
    final input = await molotowWeisDialogBuilder(context,
        playerNames: data.score.playerName.sublist(0, data.settings.players),
        hand: hand);
    if (input == null) return;
    setState(() {
      final index = data.score.playerName.indexOf(input.player);
      final pts = hand ? -input.points : input.points;

      if (data.score.rows.isNotEmpty &&
          data.score.rows.last.pts[index] == null) {
        data.score.rows.last.pts[index] = pts;
      } else {
        List<int?> round = List.filled(Players.max, null);
        round[index] = pts;
        data.score.rows.add(MolotowRow(round, isRound: false));
      }
      data.save();
    });
  }

  void _pointsDialog({int? editRowNo}) async {
    final previousPts =
        (editRowNo != null) ? data.score.rows[editRowNo].pts : null;
    final input = await playerPointsDialogBuilder(context,
        playerNames: data.score.playerName.sublist(0, data.settings.players),
        pointsPerRound: data.settings.pointsPerRound,
        rounded: data.settings.rounded,
        previousPts: previousPts);
    if (input == null) return;
    setState(() {
      if (editRowNo == null) {
        data.score.rows.add(MolotowRow(input, isRound: true));
      } else {
        data.score.rows[editRowNo].pts = input;
      }
      data.save();
    });
  }
}
