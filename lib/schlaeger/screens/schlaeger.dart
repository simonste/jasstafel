import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/dialog/string_dialog.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/common/widgets/board_title.dart';
import 'package:jasstafel/common/widgets/delete_button.dart';
import 'package:jasstafel/common/widgets/settings_button.dart';
import 'package:jasstafel/common/widgets/who_is_next_button.dart';
import 'package:jasstafel/schlaeger/data/schlaeger_score.dart';
import 'package:jasstafel/schlaeger/dialog/schlaeger_dialog.dart';
import 'package:jasstafel/schlaeger/screens/schlaeger_settings_screen.dart';
import 'package:jasstafel/schlaeger/widgets/schlaeger_player.dart';
import 'package:jasstafel/settings/schlaeger_settings.g.dart';
import 'dart:developer' as developer;

class Schlaeger extends StatefulWidget {
  const Schlaeger({super.key});

  @override
  State<Schlaeger> createState() => _SchlaegerState();
}

class _SchlaegerState extends State<Schlaeger> {
  var data = BoardData(
      SchlaegerSettings(), SchlaegerScore(), SchlaegerSettingsKeys().data);
  Timer? updateTimer;

  void restoreData() async {
    data = await data.load() as BoardData<SchlaegerSettings, SchlaegerScore>;
    setState(() {}); // trigger widget update
  }

  @override
  void initState() {
    developer.log('init state', name: 'jasstafel schlaeger');
    super.initState();
    restoreData();
  }

  @override
  Widget build(BuildContext context) {
    developer.log('build', name: 'jasstafel schlaeger');
    data.checkGameOver(context,
        goalType: GoalType.values[data.settings.goalType]);
    if (updateTimer != null) {
      updateTimer!.cancel();
    }

    var playerWidgets = <Widget>[];
    var playerCounter = 0;
    for (int i = 0; i < 4; i++) {
      var player =
          (data.settings.players != 4 && data.settings.missingPlayer == i)
              ? null
              : playerCounter++;
      playerWidgets.add(SchlaegerPlayer(
          player, data, _stringDialog, _pointsDialog,
          position: i));
    }

    return Scaffold(
      appBar: TitleBar(
        board: Board.schlaeger,
        context: context,
        actions: [
          WhoIsNextButton(
            context,
            data.score.playerName.sublist(0, data.settings.players),
            data.score.noOfRounds(),
            data.common.whoIsNext,
            () => data.save(),
          ),
          DeleteButton(
            context,
            deleteFunction: () => setState(() => data.reset()),
          ),
          SettingsButton(SchlaegerSettingsScreen(data), context,
              () => setState(() => data.settings.fromPrefService(context))),
        ],
      ),
      body: Stack(children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [playerWidgets[0], playerWidgets[1]])),
            Expanded(
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [playerWidgets[2], playerWidgets[3]]))
          ],
        ),
        Center(
            child: FloatingActionButton(
                heroTag: "add_round",
                onPressed: () => _pointsDialog(),
                tooltip: context.l10n.addRound,
                child: const Icon(Icons.add))),
      ]),
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

  void _pointsDialog({int? editRowNo}) async {
    final previousPts =
        (editRowNo != null) ? data.score.rows[editRowNo].pts : null;
    final input = await schlaegerDialogBuilder(context,
        playerNames: data.score.playerName.sublist(0, data.settings.players),
        pointsPerRound: 3,
        previousPts: previousPts);
    if (input == null) return;
    setState(() {
      data.common.timestamps.addPoints(data.score.totalPoints());
      if (editRowNo == null) {
        data.score.rows.add(SchlaegerRound(input));
      } else {
        data.score.rows[editRowNo].pts = input;
      }
      data.save();
    });
  }
}
