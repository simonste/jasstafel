import 'dart:convert';

import 'package:archive/archive_io.dart';

/// A recorded game as the sync sends it: a row of the history, see
/// `GameRecord.toRow`.
typedef GameRow = Map<String, Object?>;

/// The history as the sync shares it: the devices of a session send each
/// other the games they don't have.
abstract class SyncHistory {
  /// The ids of the games kept here, each with whether it is finished, and
  /// of those deleted here, as finished: they aren't to be sent again.
  Future<Map<String, bool>> ids();

  /// The games of [ids] that are kept here.
  Future<List<GameRow>> rows(Iterable<String> ids);

  /// Takes in games of another device. A game deleted here is left out, one
  /// kept here only replaced by its finished version.
  Future<void> take(List<GameRow> rows);
}

/// No history, for a session without one.
class NoSyncHistory implements SyncHistory {
  const NoSyncHistory();

  @override
  Future<Map<String, bool>> ids() async => {};

  @override
  Future<List<GameRow>> rows(Iterable<String> ids) async => [];

  @override
  Future<void> take(List<GameRow> rows) async {}
}

/// [rows] compressed for a message: a game is mostly its board, which
/// shrinks to a fraction.
String encodeGames(List<GameRow> rows) =>
    base64.encode(GZipEncoder().encode(utf8.encode(jsonEncode(rows))));

List<GameRow> decodeGames(String encoded) => [
  for (final row
      in jsonDecode(
            utf8.decode(GZipDecoder().decodeBytes(base64.decode(encoded))),
          )
          as List)
    (row as Map).cast<String, Object?>(),
];
