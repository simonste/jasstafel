import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:jasstafel/coiffeur/dialog/coiffeur_info.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/dialog/statistics_dialog.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/common/sync/sync_service.dart';
import 'package:jasstafel/common/widgets/delete_button.dart';
import 'package:jasstafel/common/widgets/settings_button.dart';
import 'package:jasstafel/common/widgets/settings_provider.dart';
import 'package:jasstafel/common/widgets/sync_button.dart';
import 'package:jasstafel/common/widgets/who_is_next_button.dart';
import 'package:jasstafel/schieber/dialog/schieber_history.dart';
import 'package:jasstafel/schieber/dialog/schieber_statistics.dart';
import 'package:jasstafel/schieber/screens/schieber_backside.dart';
import 'package:jasstafel/settings/common_settings.g.dart';

class TitleBar extends AppBar {
  TitleBar({
    super.key,
    required Board board,
    required List<Widget> actions,
    required BuildContext context,
  }) : super(
         title: BoardTitle(board, context),
         actions: shrinkActions(
           actions: actions,
           context: context,
           priority: [
             for (final (_, action)
                 in actions.indexed.toList()..sort(_byMenuRank))
               action.runtimeType,
           ],
           // Most players never sync, so the sync button waits in the menu.
           // While a session runs it stays in the bar, where its icon shows
           // the session's state.
           inMenu: SyncService.instance.status.value.active
               ? const []
               : const [SyncButton],
           keep: SyncService.instance.status.value.active
               ? const [SyncButton]
               : const [],
         ),
       );
}

/// The rank of a title bar action: when the bar is too narrow, the actions
/// with the lowest rank move into its menu first. Every action needs one.
int _menuRank(Widget action) => switch (action) {
  SettingsButton() => 1,
  SyncButton() => 2,
  WhoIsNextButton() => 3,
  DeleteButton() => 4,
  StatisticsButton() ||
  SchieberStatisticsButton() ||
  SchieberHistoryButton() ||
  CoiffeurInfoButton() => 5,
  BacksideButton() => 6,
  _ => throw ArgumentError.value(action, 'action', 'has no menu rank'),
};

/// Orders indexed actions by their menu rank, equal ranks from left to right.
int _byMenuRank((int, Widget) a, (int, Widget) b) {
  final byRank = _menuRank(a.$2).compareTo(_menuRank(b.$2));
  return byRank != 0 ? byRank : a.$1.compareTo(b.$1);
}

class BoardTitle extends Theme {
  BoardTitle(Board board, BuildContext context, {super.key})
    : super(
        data: ThemeData.dark(),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Board>(
            isExpanded: true,
            value: board,
            dropdownColor: Theme.of(context).appBarTheme.backgroundColor,
            items: <DropdownMenuItem<Board>>[
              DropdownMenuItem(
                value: Board.schieber,
                child: AutoSizeText(context.l10n.schieber),
              ),
              DropdownMenuItem(
                value: Board.coiffeur,
                child: AutoSizeText(context.l10n.coiffeur),
              ),
              DropdownMenuItem(
                value: Board.molotow,
                child: AutoSizeText(context.l10n.molotow),
              ),
              DropdownMenuItem(
                value: Board.differenzler,
                child: AutoSizeText(context.l10n.differenzler),
              ),
              DropdownMenuItem(
                value: Board.guggitaler,
                child: AutoSizeText(context.l10n.guggitaler),
              ),
              DropdownMenuItem(
                value: Board.schlaeger,
                child: AutoSizeText(context.l10n.schlaeger),
              ),
              DropdownMenuItem(
                value: Board.pointBoard,
                child: AutoSizeText(context.l10n.pointBoard),
              ),
            ],
            onChanged: (value) {
              final preferences = SettingsProvider.of(context);
              preferences.setInt(CommonSettings.keys.lastBoard, value!.index);
              Navigator.of(context).restorablePushReplacementNamed(value.name);
            },
          ),
        ),
      );
}

/// Fits [actions] into the bar, moving those that don't fit into a menu.
///
/// [priority] lists the types to move first, then the leftmost actions go;
/// types without a movable action in the bar are skipped.
/// Actions of the types in [inMenu] go into the menu whatever the width, as
/// most players never need them; actions of the types in [keep] stay in the
/// bar whatever the width. A menu that would hold a single entry is a detour,
/// that entry goes back to its place among the actions instead.
List<Widget> shrinkActions({
  required List<Widget> actions,
  required BuildContext context,
  required List<Type> priority,
  List<Type> inMenu = const [],
  List<Type> keep = const [],
}) {
  final screenWidth = MediaQuery.of(context).size.width;
  const iconWidth = 48;
  const boardTitleWidth = 113 + 16 + 16;
  final maxActions = ((screenWidth - boardTitleWidth) / iconWidth).floor();

  final order = [...actions];
  final menuFirst = actions
      .where((action) => inMenu.contains(action.runtimeType))
      .toList();
  actions.removeWhere((action) => inMenu.contains(action.runtimeType));

  final preferences = SettingsProvider.of(context);
  if (preferences.getBool("additionalTestButtons") ?? false) {
    // for debug / test: add additional buttons
    for (var i = actions.length; i <= maxActions; ++i) {
      actions.insert(
        1,
        IconButton(
          key: Key("additionalTestButton$i"),
          icon: const Icon(Icons.android),
          onPressed: () {},
        ),
      );
    }
  }

  bool movable(Widget action) => !keep.contains(action.runtimeType);

  var priorityCopy = [...priority];
  if (actions.length > maxActions || menuFirst.isNotEmpty) {
    List<IconButton> iconButtons = [];

    while ((actions.length + 1) > maxActions && actions.any(movable)) {
      Widget? action;
      while (action == null && priorityCopy.isNotEmpty) {
        final type = priorityCopy.removeAt(0);
        action = actions
            .where((a) => a.runtimeType == type && movable(a))
            .firstOrNull;
      }
      // remove leftmost
      action ??= actions.firstWhere(movable);
      actions.remove(action);
      iconButtons.add(action as IconButton);
    }
    iconButtons.addAll(menuFirst.cast<IconButton>());
    if (iconButtons.length == 1) {
      final lone = iconButtons.single;
      final before = order.takeWhile((action) => action != lone).toSet();
      actions.insert(actions.where(before.contains).length, lone);
      return actions;
    }
    actions.insert(
      actions.length,
      PopupMenuButton(
        key: const Key('actionsMenu'),
        color: Theme.of(context).appBarTheme.backgroundColor,
        itemBuilder: (BuildContext context) {
          // unwrap icon buttons to be able to call Navigator.pop (close drop down)
          List<PopupMenuItem<int>> popupItems = [];
          iconButtons.asMap().forEach((index, element) {
            final icon = IconTheme.merge(
              data: const IconThemeData(color: Colors.white),
              child: element.icon,
            );
            // keep the tooltip, it labels the entry for screen readers
            final tooltip = element.tooltip;
            popupItems.add(
              PopupMenuItem(
                key: element.key,
                value: index,
                child: tooltip == null
                    ? icon
                    : Tooltip(message: tooltip, child: icon),
              ),
            );
          });
          return popupItems;
        },
        onSelected: (value) {
          iconButtons[value].onPressed!();
        },
      ),
    );
  }
  return actions;
}
