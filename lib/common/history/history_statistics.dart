import 'package:jasstafel/common/history/game_record.dart';

/// How a team or player did over the recorded games.
class NameStatistics {
  NameStatistics(this.name);

  final String name;
  int games = 0;
  int wins = 0;
  int points = 0;

  /// The sum of each detail by kind, see `GameRecord.details`.
  final details = <String, int>{};

  double get average => games == 0 ? 0 : points / games;

  /// The average of the detail [kind].
  double averageOf(String kind) =>
      games == 0 ? 0 : (details[kind] ?? 0) / games;
}

/// How a single player did over the recorded games, in whichever team.
class PlayerStatistics {
  PlayerStatistics(this.name);

  final String name;
  int games = 0;
  int wins = 0;

  double get winRate => games == 0 ? 0 : wins / games;
}

/// The statistics of the recorded games of a board, by team or player name,
/// over the games that were finished.
///
/// Names are matched as written, so a renamed team counts as a new one.
class HistoryStatistics {
  HistoryStatistics(List<GameRecord> records) {
    for (final record in records) {
      games++;
      // A game reset before its end has no winner, it would count as lost.
      if (!record.finished) continue;
      finished++;
      for (var i = 0; i < record.names.length; i++) {
        final stats = _byName.putIfAbsent(
          record.names[i],
          () => NameStatistics(record.names[i]),
        );
        stats.games++;
        stats.points += i < record.totals.length ? record.totals[i] : 0;
        for (final MapEntry(key: kind, value: values)
            in record.details.entries) {
          if (i >= values.length) continue;
          if (!detailKinds.contains(kind)) detailKinds.add(kind);
          stats.details[kind] = (stats.details[kind] ?? 0) + values[i];
        }
        final won = record.winners.contains(record.names[i]);
        if (won) stats.wins++;

        final team = i < record.players.length ? record.players[i] : const [];
        if (team.length > 1) hasTeams = true;
        for (final player in team) {
          final p = _byPlayer.putIfAbsent(
            player,
            () => PlayerStatistics(player),
          );
          p.games++;
          if (won) p.wins++;
        }
      }
    }
  }

  /// The kinds of details the games kept, in the order first seen.
  final detailKinds = <String>[];

  /// Whether teams of several players were recorded, so that the players
  /// tell more than the teams.
  bool hasTeams = false;
  final _byPlayer = <String, PlayerStatistics>{};

  /// Every player who took part, the best win rate first, then the most
  /// games.
  List<PlayerStatistics> get players {
    final list = _byPlayer.values.toList();
    list.sort((a, b) {
      final byRate = b.winRate.compareTo(a.winRate);
      return byRate != 0 ? byRate : b.games.compareTo(a.games);
    });
    return list;
  }

  int games = 0;
  int finished = 0;
  final _byName = <String, NameStatistics>{};

  /// Those who played the most games first, then the most wins.
  List<NameStatistics> get names {
    final list = _byName.values.toList();
    list.sort((a, b) {
      final byGames = b.games.compareTo(a.games);
      return byGames != 0 ? byGames : b.wins.compareTo(a.wins);
    });
    return list;
  }
}
