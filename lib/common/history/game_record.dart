import 'dart:convert';

import 'package:jasstafel/common/board.dart';

/// A game that ended, as the history keeps it.
///
/// Keyed by the game's id, which synced devices share, so the same game is
/// one entry on every device. [state] holds the whole board as saved, for
/// statistics that may be wanted later without changing the history.
class GameRecord {
  const GameRecord({
    required this.id,
    required this.board,
    required this.profile,
    required this.started,
    required this.ended,
    required this.finished,
    required this.rounds,
    required this.names,
    required this.totals,
    this.details = const {},
    this.players = const [],
    required this.winners,
    required this.losers,
    required this.state,
    required this.settings,
  });

  final String id;
  final Board board;
  final String profile;
  final DateTime? started;
  final DateTime ended;

  /// Whether the game reached its goal, or had none to reach, rather than
  /// being reset before.
  final bool finished;
  final int rounds;

  /// The teams or players and their final points, in board order.
  final List<String> names;
  final List<int> totals;

  /// Further numbers of each team or player by kind, see `Score.details`,
  /// such as the Weis.
  final Map<String, List<int>> details;

  /// The players of each team in [names], empty for a team whose players
  /// aren't known. On a board without teams, each player is their own.
  final List<List<String>> players;
  final List<String> winners;
  final List<String> losers;

  /// The board as saved, see `BoardData.currentJson`.
  final String state;

  /// The shared settings of the board, see `BoardData.sharedSettings`.
  final Map<String, dynamic> settings;

  Map<String, Object?> toRow() => {
    'id': id,
    'board': board.name,
    'profile': profile,
    'started': started?.millisecondsSinceEpoch,
    'ended': ended.millisecondsSinceEpoch,
    'finished': finished ? 1 : 0,
    'rounds': rounds,
    'names': jsonEncode(names),
    'totals': jsonEncode(totals),
    'details': jsonEncode(details),
    'players': jsonEncode(players),
    'winners': jsonEncode(winners),
    'losers': jsonEncode(losers),
    'state': state,
    'settings': jsonEncode(settings),
  };

  factory GameRecord.fromRow(Map<String, Object?> row) => GameRecord(
    id: row['id'] as String,
    board: Board.values.byName(row['board'] as String),
    profile: row['profile'] as String,
    started: row['started'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row['started'] as int),
    ended: DateTime.fromMillisecondsSinceEpoch(row['ended'] as int),
    finished: row['finished'] == 1,
    rounds: row['rounds'] as int,
    names: _strings(row['names']),
    totals: (jsonDecode(row['totals'] as String) as List).cast<int>(),
    details: {
      for (final MapEntry(:key, :value)
          in (jsonDecode(row['details'] as String) as Map).entries)
        key as String: (value as List).cast<int>(),
    },
    players: [
      for (final team in jsonDecode(row['players'] as String) as List)
        (team as List).cast<String>(),
    ],
    winners: _strings(row['winners']),
    losers: _strings(row['losers']),
    state: row['state'] as String,
    settings: jsonDecode(row['settings'] as String) as Map<String, dynamic>,
  );

  static List<String> _strings(Object? json) =>
      (jsonDecode(json as String) as List).cast<String>();

  /// How long the game took, if it was timed.
  Duration? get duration => started == null ? null : ended.difference(started!);
}
