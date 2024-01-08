import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/list_board/list_board_utils.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/common/dialog/string_dialog.dart';
import 'package:jasstafel/common/widgets/delete_button.dart';
import 'package:jasstafel/common/widgets/who_is_next_button.dart';
import 'package:jasstafel/schieber/data/schieber_score.dart';
import 'package:jasstafel/schieber/widgets/schieber_strokes.dart';
import 'package:jasstafel/settings/schieber_settings.g.dart';
import 'dart:developer' as developer;

class BacksideButton extends IconButton {
  BacksideButton(BuildContext context, Function callback,
      {super.key = const Key("backside")})
      : super(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) {
                    return const SchieberBackside();
                  },
                ),
              ).then((value) {
                callback();
              });
            },
            icon: const Icon(Icons.flip));
}

class SchieberBackside extends StatefulWidget {
  const SchieberBackside({super.key});

  @override
  State<SchieberBackside> createState() => _SchieberBacksideState();
}

class _SchieberBacksideState extends State<SchieberBackside> {
  var data = BoardData(
      SchieberSettings(), SchieberScore(), SchieberSettingsKeys().data);

  void restoreData() async {
    data = await data.load() as BoardData<SchieberSettings, SchieberScore>;
    setState(() {}); // trigger widget update
  }

  @override
  void initState() {
    developer.log('init state', name: 'jasstafel schieber backside');
    super.initState();
    restoreData();
  }

  @override
  Widget build(BuildContext context) {
    developer.log('build', name: 'jasstafel schieber backside');

    if (data.score.backside[data.settings.backsideColumns - 1].name.isEmpty ||
        (data.settings.backsideColumns < 6 &&
            data.score.backside[data.settings.backsideColumns].name
                .isNotEmpty)) {
      setDefaultPlayerNames(context);
    }

    final int columns = data.settings.backsideColumns;
    const int strokesPerRow = 10;

    final screen = MediaQuery.of(context).size;
    final columnWidth = screen.width / columns;
    final padding = columnWidth * 0.15;
    final strokeWidthFactor = 0.03 * pow(columns, -1.0);

    final double strokeHeight = columns == 2 ? 100 : 70;
    var mostStrokes = 0;
    for (var element in data.score.backside) {
      mostStrokes = max(mostStrokes, element.strokes);
    }
    final minRows = (screen.height / strokeHeight).floor() - 2;
    final noOfRows = max(minRows, (mostStrokes / strokesPerRow).ceil());

    background() {
      List<Widget> columnWidgets = [];
      for (var i = 0; i < columns; i++) {
        final decoration = i != 0
            ? const BoxDecoration(
                border: Border(left: BorderSide(color: Colors.white)))
            : const BoxDecoration();
        columnWidgets.add(Expanded(
          child: Container(
            decoration: decoration,
            child: const SizedBox.expand(),
          ),
        ));
      }
      return Row(children: columnWidgets);
    }

    List<Widget> columnWidgets = [];
    for (var i = 0; i < columns; i++) {
      final totalStrokes = data.score.backside[i].strokes;
      List<Widget> rows = [];

      strokeRow(int row) {
        final strokes = (totalStrokes / strokesPerRow) > (row + 1)
            ? strokesPerRow
            : max(totalStrokes - row * strokesPerRow, 0);

        return GestureDetector(
            key: Key("add$i:$row"),
            onTap: () => {
                  setState(() {
                    data.score.backside[i].strokes++;
                    data.save();
                  })
                },
            onPanEnd: (details) => {
                  setState(() {
                    if (details.velocity.pixelsPerSecond.dy.abs() > 200) {
                      data.score.backside[i].strokes--;
                    } else {
                      data.score.backside[i].strokes++;
                    }
                    data.save();
                  })
                },
            child: SizedBox(
                height: strokeHeight,
                width: MediaQuery.of(context).size.width / columns,
                child: Container(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: SchieberStrokes(
                      StrokeType.I,
                      strokes,
                      widthFactor: strokeWidthFactor,
                    ))));
      }

      for (var j = 0; j < noOfRows; j++) {
        rows.add(strokeRow(j));
      }
      columnWidgets.add(Expanded(
          child: Column(
              key: Key('column$i'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rows)));
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.backsideTitle),
          actions: [
            DeleteButton(
              context,
              deleteFunction: () => setState(() {
                data.score.resetBackside();
                data.save();
              }),
              resetHint: context.l10n.resetConfirmStrokes,
            )
          ],
        ),
        body: Column(children: [
          rowHeader(
              playerNames: data.score.backside.map((e) => e.name).toList(),
              players: data.settings.backsideColumns,
              headerFunction: _stringDialog,
              context: context,
              hideRoundColumn: true),
          Expanded(
              child: Stack(
            children: [
              background(),
              SingleChildScrollView(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: columnWidgets),
              ),
            ],
          )),
        ]));
  }

  void _stringDialog(player) async {
    var controller =
        TextEditingController(text: data.score.backside[player].name);

    final title = Text(context.l10n.playerName);
    final input = await stringDialogBuilder(context, controller, title: title);
    if (input == null) return; // empty name not allowed
    setState(() {
      data.score.backside[player].name = input;
      data.save();
    });
  }

  void setDefaultPlayerNames(BuildContext context) {
    if (data.settings.backsideColumns == 2) {
      data.score.backside[0].name = data.score.team[0].name;
      data.score.backside[1].name = data.score.team[1].name;
    } else if (data.settings.backsideColumns == 4) {
      var players = WhoIsNextButton.guessPlayerNames(
          [data.score.team[0].name, data.score.team[1].name]);
      data.score.backside[0].name = players[0];
      data.score.backside[1].name = players[2];
      data.score.backside[2].name = players[1];
      data.score.backside[3].name = players[3];
      data.score.backside[3].name = players[3];
      data.score.backside[3].name = players[3];
    } else {
      for (var i = 0; i < data.settings.backsideColumns; i++) {
        data.score.backside[i].name = context.l10n.playerNo(i + 1);
      }
    }
    for (var i = data.settings.backsideColumns; i < 6; i++) {
      data.score.backside[i].name = "";
    }
  }
}
