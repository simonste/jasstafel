import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/dialog/points_dialog.dart';
import 'package:jasstafel/common/dialog/player_points_dialog.dart';
import 'package:jasstafel/common/dialog/statistics_dialog.dart';
import 'package:jasstafel/common/dialog/string_dialog.dart';
import 'package:jasstafel/common/list_board/list_board_utils.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/common/widgets/board_title.dart';
import 'package:jasstafel/common/widgets/delete_button.dart';
import 'package:jasstafel/common/widgets/settings_button.dart';
import 'package:jasstafel/common/widgets/who_is_next_button.dart';
import 'package:jasstafel/differenzler/data/differenzler_score.dart';
import 'package:jasstafel/differenzler/screens/differenzler_settings_screen.dart';
import 'package:jasstafel/settings/differenzler_settings.g.dart';
import 'dart:developer' as developer;

class Differenzler extends StatefulWidget {
  const Differenzler({super.key});

  @override
  State<Differenzler> createState() => _DifferenzlerState();
}

class _DifferenzlerState extends State<Differenzler> {
  var data = BoardData(DifferenzlerSettings(), DifferenzlerScore(),
      DifferenzlerSettingsKeys().data);
  Timer? updateTimer;

  final empty = '-';

  void restoreData() async {
    data =
        await data.load() as BoardData<DifferenzlerSettings, DifferenzlerScore>;
    setState(() {}); // trigger widget update
  }

  @override
  void initState() {
    developer.log('init state', name: 'jasstafel differenzler');
    super.initState();
    restoreData();
  }

  @override
  Widget build(BuildContext context) {
    developer.log('build', name: 'jasstafel differenzler');
    data.checkGameOver(context,
        goalType: GoalType.values[data.settings.goalType]);
    if (updateTimer != null) {
      updateTimer!.cancel();
    }

    if (data.score.rows.isEmpty || data.score.rows.last.isPlayed()) {
      data.score.rows.add(DifferenzlerRow());
    }

    rowWidget(List<String> data,
        {List<String> guess = const [],
        List<String> pts = const [],
        int? rowNo}) {
      List<Widget> children = rowContainer(data[0]);

      for (var i = 1; i < data.length; i++) {
        final text = defaultCell(data[i]);

        children.add(Expanded(
            child: Row(children: [
          Expanded(
              child: Column(children: [
            Text(key: Key('guess_${rowNo}_$i'), guess[i]),
            pts[i] == empty
                ? Text(pts[i])
                : InkWell(
                    onLongPress: () => _pointsDialog(editRowNo: rowNo!),
                    child: Text(pts[i]),
                  )
          ])),
          data[i] == empty
              ? text
              : InkWell(
                  onLongPress: () => _pointsDialog(editRowNo: rowNo!),
                  child: text),
        ])));
      }
      return Container(
          decoration: rowDecoration(context), child: Row(children: children));
    }

    footer() {
      List<String> list = ['T'];
      for (var i = 0; i < data.settings.players; i++) {
        list.add('${data.score.total(i)}');
      }
      return rowFooter(list, context: context);
    }

    int roundNo = 0;
    differenzlerRow(int rowNo) {
      final row = data.score.rows[rowNo];
      List<String> guess = [''];
      List<String> pts = [''];
      List<String> diff = [''];
      roundNo++;
      diff[0] = '$roundNo';
      for (var p = 0; p < data.settings.players; p++) {
        if (row.pts.length > p && row.pts[p] != null) {
          guess.add('${row.guesses[p]}');
          pts.add('${row.pts[p]}');
          diff.add('${row.diff(p)}');
        } else {
          if (row.guesses[p] != null) {
            if (data.settings.hideGuess) {
              guess.add('***');
            } else {
              guess.add('${row.guesses[p]}');
            }
          } else {
            guess.add(empty);
          }
          pts.add(empty);
          diff.add(empty);
        }
      }
      return rowWidget(diff, guess: guess, pts: pts, rowNo: rowNo);
    }

    List<Widget> rows = [];
    for (var i = 0; i < data.score.rows.length; i++) {
      rows.add(differenzlerRow(i));
    }

    List<Widget> enterGuessButtons = [const SizedBox(width: 20)];
    for (var p = 0; p < data.settings.players; p++) {
      if (data.score.rows.last.guesses[p] == null) {
        enterGuessButtons.add(Expanded(
            child: FloatingActionButton(
                heroTag: "add_guess_$p",
                onPressed: () => _guessDialog(p),
                tooltip: context.l10n.enterGuess(data.score.playerName[p]),
                child: const Icon(Icons.question_mark))));
      } else {
        enterGuessButtons.add(const Expanded(child: SizedBox()));
      }
    }
    rows.add(Row(children: enterGuessButtons));

    var addRoundButton = data.score.rows.last.isGuessed(data.settings.players)
        ? Positioned(
            right: 20,
            bottom: 50,
            child: FloatingActionButton(
                heroTag: "add_round",
                onPressed: () => _pointsDialog(),
                tooltip: context.l10n.addRound,
                child: const Icon(Icons.add)))
        : const SizedBox();

    List<List<String>> stats = [];
    var avgGuess = 0.0;
    for (var p = 0; p < data.settings.players; p++) {
      final gu = data.score.avgGuessed(p);
      var zeroGuessed = 0;
      var zeroDiff = 0;
      for (final row in data.score.rows) {
        if (row.isPlayed()) {
          zeroGuessed += (row.guesses[p] == 0) ? 1 : 0;
          zeroDiff += (row.diff(p) == 0) ? 1 : 0;
        }
      }

      final pts = data.score.avgPoints(p);
      if (data.score.rows.first.isPlayed()) {
        stats.add([
          data.score.playerName[p],
          '$gu',
          '$zeroGuessed',
          '$zeroDiff',
          '$pts'
        ]);
        avgGuess += gu;
      } else {
        stats.add([data.score.playerName[p], "?", "?", "?", "?"]);
      }
    }
    return Scaffold(
      appBar: TitleBar(
        board: Board.differenzler,
        context: context,
        actions: [
          WhoIsNextButton(
            context,
            data.score.playerName.sublist(0, data.settings.players),
            data.score.noOfRounds(),
            data.common.whoIsNext,
            () => data.save(),
          ),
          StatisticsButton(
              context,
              data.common.timestamps.elapsed(context),
              [
                context.l10n.avgGuess,
                context.l10n.zeroGuess,
                context.l10n.zeroDiff,
                context.l10n.avgPoints
              ],
              stats,
              summary: data.score.rows.first.isPlayed()
                  ? context.l10n.avgRoundGuess((avgGuess).round())
                  : null),
          DeleteButton(
            context,
            deleteFunction: () => setState(() => data.reset()),
          ),
          SettingsButton(DifferenzlerSettingsScreen(data), context,
              () => setState(() => data.settings.fromPrefService(context))),
        ],
      ),
      body: Stack(children: [
        Column(children: [
          rowHeader(
              playerNames: data.score.playerName,
              players: data.settings.players,
              headerFunction: _stringDialog,
              context: context),
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: rows),
            ),
          ),
          footer()
        ]),
        addRoundButton,
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

  void _guessDialog(int player) async {
    var controller = TextEditingController();
    var title = Text(context.l10n.enterGuess(data.score.playerName[player]));

    final input = await pointsDialogBuilder(context, controller, title: title);
    if (input == null) return;
    setState(() {
      data.common.timestamps.addPoints(data.score.totalPoints());
      data.score.rows.last.guesses[player] = input.value!;
      data.save();
    });
  }

  void _pointsDialog({int? editRowNo}) async {
    final previousPts =
        (editRowNo != null) ? data.score.rows[editRowNo].pts : null;
    final input = await playerPointsDialogBuilder(context,
        playerNames: data.score.playerName.sublist(0, data.settings.players),
        pointsPerRound: data.settings.pointsPerRound,
        previousPts: previousPts);
    if (input == null) return;
    setState(() {
      if (editRowNo == null) {
        data.score.rows.last.pts = input;
      } else {
        data.score.rows[editRowNo].pts = input;
      }
      data.save();
    });
  }
}
