import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jasstafel/common/data/common_data.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/common/widgets/who_is_next_widget.dart';

class WhoIsNextButton extends IconButton {
  WhoIsNextButton(BuildContext context, List<String> players, int rounds,
      WhoIsNext whoIsNext, Function saveFunction)
      : super(
            key: const Key('whoIsNext'),
            onPressed: () {
              dialogBuilder(context,
                  WhoIsNextData(players, rounds, whoIsNext, saveFunction));
            },
            icon: SvgPicture.asset(
              "assets/actions/who_is_next.svg",
              width: 24,
            ));

  static List<String> splitAtUpperCaseLetters(String teamName) {
    List<String> players = [];
    int idx = 0;
    for (int i = 1; i < teamName.length; i++) {
      if (teamName[i] == teamName[i].toUpperCase()) {
        players.add(teamName.substring(idx, i));
        idx = i;
      }
    }
    players.add(teamName.substring(idx));
    return players;
  }

  static List<String> splitTeamName(String teamName, {int? limit}) {
    var playerNames = teamName.split(RegExp("[-&/+]"));
    if (playerNames.length < 2 || playerNames[0].isEmpty) {
      playerNames = teamName.split(RegExp("[ ]+"));
    }
    if (playerNames.length < 2) {
      final camelCaseSplit = splitAtUpperCaseLetters(teamName);
      if (camelCaseSplit.length == 2) {
        playerNames = camelCaseSplit;
      }
    }
    if (limit != null) {
      if (playerNames.length > limit) {
        playerNames[limit - 1] =
            teamName.substring(teamName.indexOf(playerNames[limit - 1]));
        playerNames = playerNames.sublist(0, limit);
      }
    }
    for (int i = 0; i < playerNames.length; ++i) {
      playerNames[i] = playerNames[i].trim();
    }
    return playerNames;
  }

  static String _addSuffix(String teamName, int playerNo) {
    final lastCharacter = teamName.characters.last;
    final isDigit = int.tryParse(lastCharacter) != null;
    var suffix = " ${playerNo + 1}";
    if (isDigit) {
      suffix = playerNo == 0 ? "a" : "b";
    }
    return "$teamName$suffix";
  }

  static List<String> guessPlayerNames(List<String> teamNames) {
    final l = teamNames.length;
    int playersPerTeam = 2;
    if (l == 2 &&
        splitTeamName(teamNames[0].trim()).length == 3 &&
        splitTeamName(teamNames[1].trim()).length == 3) {
      playersPerTeam = 3;
    }
    final int numPlayers = l * playersPerTeam;
    List<String> playerNames = List.generate(numPlayers, (i) => 'P${i + 1}');
    for (var t = 0; t < l; t++) {
      final teamName = teamNames[t].trim();
      if (teamName.isEmpty) {
        continue;
      }
      final names = splitTeamName(teamName, limit: playersPerTeam);
      final validSplit = names.length == playersPerTeam &&
          !teamName.toLowerCase().contains('team');
      for (var n = 0; n < playersPerTeam; n++) {
        if (validSplit) {
          playerNames[t + n * l] = names[n];
        } else {
          playerNames[t + n * l] = _addSuffix(teamName, n);
        }
      }
    }
    return playerNames;
  }
}

Future<void> dialogBuilder(BuildContext context, WhoIsNextData whoIsNextData) {
  return showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(context.l10n.whoBegins),
              content: Wrap(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(context.l10n.noOfRounds(whoIsNextData.rounds)),
                      WhoIsNextWidget(whoIsNextData),
                      Text(
                        context.l10n.whoBeginsInfo,
                        style: const TextStyle(fontWeight: FontWeight.w100),
                        textScaler: const TextScaler.linear(0.8),
                      ),
                    ],
                  )
                ],
              ),
              actions: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: Text(context.l10n.ok),
                  onPressed: () {
                    Navigator.of(context).pop(WhoIsNext());
                  },
                ),
              ],
            );
          },
        );
      });
}
