import 'package:flutter/material.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:pref/pref.dart';

class TitleBar extends AppBar {
  TitleBar(
      {super.key,
      required Board board,
      required List<Widget> actions,
      required BuildContext context,
      List<Type> priority = const []})
      : super(
          title: BoardTitle(board, context),
          actions: shrinkActions(
            actions: actions,
            context: context,
            priority: priority,
          ),
        );
}

class BoardTitle extends Theme {
  BoardTitle(Board board, BuildContext context, {super.key})
      : super(
          data: ThemeData.dark(),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Board>(
              isExpanded: true,
              value: board,
              items: <DropdownMenuItem<Board>>[
                DropdownMenuItem(
                  value: Board.schieber,
                  child: Text(context.l10n.schieber),
                ),
                DropdownMenuItem(
                  value: Board.coiffeur,
                  child: Text(context.l10n.coiffeur),
                ),
                DropdownMenuItem(
                  value: Board.molotow,
                  child: Text(context.l10n.molotow),
                ),
                DropdownMenuItem(
                  value: Board.differenzler,
                  child: Text(context.l10n.differenzler),
                ),
                DropdownMenuItem(
                  value: Board.guggitaler,
                  child: Text(context.l10n.guggitaler),
                ),
                DropdownMenuItem(
                  value: Board.pointBoard,
                  child: Text(context.l10n.pointBoard),
                ),
              ],
              onChanged: (value) {
                PrefService.of(context)
                    .set(CommonSettings.keys.lastBoard, value!.index);
                Navigator.of(context)
                    .restorablePushReplacementNamed(value.name);
              },
            ),
          ),
        );
}

List<Widget> shrinkActions(
    {required List<Widget> actions,
    required BuildContext context,
    required List<Type> priority}) {
  final screenWidth = MediaQuery.of(context).size.width;
  const iconWidth = 40;
  const boardTitleWidth = 113 + 16 + 16;
  final maxActions = ((screenWidth - boardTitleWidth) / iconWidth).floor();

  var priorityCopy = [...priority];
  if (actions.length > maxActions) {
    List<IconButton> iconButtons = [];

    while ((actions.length + 1) > maxActions) {
      Widget? action;
      if (priorityCopy.isNotEmpty) {
        action = actions
            .firstWhere((element) => priorityCopy.first == element.runtimeType);
        actions.remove(action);
        priorityCopy.removeAt(0);
      } else {
        // remove leftmost
        action = actions.removeAt(0);
      }
      iconButtons.add(action as IconButton);
    }
    actions.insert(actions.length,
        PopupMenuButton(itemBuilder: (BuildContext context) {
      // unwrap icon buttons to be able to call Navigator.pop (close drop down)
      List<PopupMenuItem> popupItems = [];
      for (var element in iconButtons) {
        popupItems.add(PopupMenuItem(
            child: GestureDetector(
          key: element.key,
          onTap: () {
            Navigator.pop(context);
            element.onPressed!();
          },
          child: element.icon,
        )));
      }
      return popupItems;
    }));
  }
  return actions;
}
