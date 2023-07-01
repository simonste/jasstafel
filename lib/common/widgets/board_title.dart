import 'package:flutter/material.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:pref/pref.dart';

class BoardTitle extends Theme {
  BoardTitle(Board board, BuildContext context, {super.key})
      : super(
          data: ThemeData.dark(),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Board>(
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

List<Widget> shrinkActions(List<Widget> actions, int max,
    {List<Type> priority = const []}) {
  if (actions.length > max) {
    List<IconButton> iconButtons = [];
    Widget? action;
    while ((actions.length + 1) > max) {
      try {
        if (priority.isNotEmpty) {
          action = actions
              .firstWhere((element) => priority.first == element.runtimeType);
          actions.remove(action);
          priority.removeAt(0);
        }
      } catch (e) {
        // remove leftmost
      }
      action ??= actions.removeAt(0);
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
