import 'package:flutter/material.dart';
import 'package:jasstafel/common/dialog/confirm_dialog.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/common/utils.dart';

Future<void> winnerDialog({
  required BuildContext context,
  required List<String> winners,
  required List<String> losers,
  required Function setWinnerFunction,
  GoalType goalType = GoalType.points,
}) {
  if (winners.length == 1) {
    var subtitle = (goalType == GoalType.points && losers.isEmpty)
        ? context.l10n.winner(winners.first)
        : context.l10n.winnerRounds(winners.first);

    if (losers.isNotEmpty) {
      subtitle += "\n\n${context.l10n.winner(losers.first)}";
    }

    return confirmDialog(
      context: context,
      title: context.l10n.gameOver,
      subtitle: subtitle,
      actions: [],
    );
  } else {
    String subtitle;
    if (goalType == GoalType.rounds) {
      subtitle = context.l10n.winnerBoth;
      winners.clear();
    } else {
      subtitle =
          "${context.l10n.winnerBothPoints}\n${context.l10n.winnerFirst}";
    }

    return _bothDialog(
      context: context,
      title: context.l10n.gameOver,
      subtitle: subtitle,
      winners: winners,
      setFunction: setWinnerFunction,
    );
  }
}

Future<void> hillDialog({
  required BuildContext context,
  required List<String> hillers,
  required Function setHillerFunction,
}) {
  return _bothDialog(
    context: context,
    title: context.l10n.hill,
    subtitle: "${context.l10n.hillBoth}\n${context.l10n.winnerFirst}",
    winners: hillers,
    setFunction: setHillerFunction,
  );
}

Future<void> _bothDialog({
  required BuildContext context,
  required String title,
  required String subtitle,
  required List<String> winners,
  required Function setFunction,
}) {
  var actions = <DialogAction>[];
  for (final winner in winners) {
    actions.add(
      DialogAction(
        text: winner,
        action: () {
          setFunction(winner);
        },
      ),
    );
  }
  return confirmDialog(
    context: context,
    title: title,
    subtitle: subtitle,
    actions: actions,
  );
}
