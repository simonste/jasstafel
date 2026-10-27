import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jasstafel/common/data/common_data.dart';
import 'package:jasstafel/common/dialog/safe_dialog.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/common/widgets/who_is_next_widget.dart';

Widget getIcon(int players) {
  var imgPath = switch (players) {
    2 => "assets/actions/who_is_next_2.svg",
    3 => "assets/actions/who_is_next_3.svg",
    4 => "assets/actions/who_is_next_4.svg",
    5 => "assets/actions/who_is_next_5.svg",
    6 => "assets/actions/who_is_next_6.svg",
    7 => "assets/actions/who_is_next_7.svg",
    8 => "assets/actions/who_is_next_8.svg",
    _ => "assets/actions/who_is_next_4.svg",
  };
  return SvgPicture.asset(imgPath, width: 24);
}

class WhoIsNextButton extends IconButton {
  WhoIsNextButton(
    BuildContext context,
    List<String> players,
    int rounds,
    WhoIsNext whoIsNext,
    Function saveFunction,
  ) : super(
        key: const Key('whoIsNext'),
        onPressed: () {
          dialogBuilder(
            context,
            WhoIsNextData(players, rounds, whoIsNext, saveFunction),
          );
        },
        icon: getIcon(players.length),
      );

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
    // A hyphen joins names such as Anna-Lena, unless nothing else splits.
    var playerNames = teamName.split(RegExp("[&/+]"));
    if (playerNames.length < 2 || playerNames[0].isEmpty) {
      playerNames = teamName.split("-");
    }
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
        playerNames[limit - 1] = teamName.substring(
          teamName.indexOf(playerNames[limit - 1]),
        );
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

  static int _playersPerTeam(List<String> teamNames) {
    if (teamNames.length == 2 &&
        splitTeamName(teamNames[0].trim()).length == 3 &&
        splitTeamName(teamNames[1].trim()).length == 3) {
      return 3;
    }
    return 2;
  }

  /// The players of each team, split from the team names, or null for a
  /// team whose name doesn't name its players, such as "Team 1".
  static List<List<String>?> teamPlayers(List<String> teamNames) {
    final playersPerTeam = _playersPerTeam(teamNames);
    return [
      for (final name in teamNames)
        switch (name.trim()) {
          final teamName
              when teamName.isNotEmpty &&
                  !teamName.toLowerCase().contains('team') =>
            switch (splitTeamName(teamName, limit: playersPerTeam)) {
              final names when names.length == playersPerTeam => names,
              _ => null,
            },
          _ => null,
        },
    ];
  }

  /// The player of a team of one, or null if it isn't named after them.
  static List<String>? lonePlayer(String teamName) {
    final name = teamName.trim();
    return name.isEmpty || name.toLowerCase().contains('team') ? null : [name];
  }

  static List<String> guessPlayerNames(List<String> teamNames) {
    final l = teamNames.length;
    final playersPerTeam = _playersPerTeam(teamNames);
    final teams = teamPlayers(teamNames);
    final int numPlayers = l * playersPerTeam;
    List<String> playerNames = List.generate(numPlayers, (i) => 'P${i + 1}');
    for (var t = 0; t < l; t++) {
      final teamName = teamNames[t].trim();
      if (teamName.isEmpty) {
        continue;
      }
      for (var n = 0; n < playersPerTeam; n++) {
        playerNames[t + n * l] = teams[t]?[n] ?? _addSuffix(teamName, n);
      }
    }
    return playerNames;
  }
}

Future<void> dialogBuilder(BuildContext context, WhoIsNextData whoIsNextData) {
  return showSafeDialog<void>(
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
                      style: TextStyle(
                        fontWeight: context.fontWeight(FontWeight.w100),
                      ),
                      textScaler: const TextScaler.linear(0.8),
                    ),
                  ],
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: Text(context.l10n.ok),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    },
  );
}
