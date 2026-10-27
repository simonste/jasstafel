import 'dart:convert';

import 'package:archive/archive_io.dart';

/// A recorded game as the sync sends it: a row of the history, see
/// `GameRecord.toRow`.
typedef GameRow = Map<String, Object?>;

/// The history as the sync shares it: the devices of a session send each
/// other the games they don't have, or have in an earlier revision.
abstract class SyncHistory {
  /// The revision of a game not finished yet. Any finished game is later.
  static const unfinished = 0;

  /// The revision of a game deleted here, later than any change.
  static const deleted = 1 << 53;

  /// The revision of each game kept here: [unfinished], or the time it last
  /// changed once finished, see `GameRecord.changed`. Those deleted here are
  /// [deleted]: they aren't to be sent again.
  Future<Map<String, int>> revisions();

  /// The games of [ids] that are kept here.
  Future<List<GameRow>> rows(Iterable<String> ids);

  /// Takes in games of another device. A game deleted here is left out, one
  /// kept here only replaced by a later revision, see [revisionOf].
  Future<void> take(List<GameRow> rows);

  /// The revision of [row], see [revisions].
  static int revisionOf(GameRow row) =>
      row['finished'] == 1 ? row['changed'] as int : unfinished;
}

/// No history, for a session without one.
class NoSyncHistory implements SyncHistory {
  const NoSyncHistory();

  @override
  Future<Map<String, int>> revisions() async => {};

  @override
  Future<List<GameRow>> rows(Iterable<String> ids) async => [];

  @override
  Future<void> take(List<GameRow> rows) async {}
}

/// [rows] compressed for a message: a game is mostly its board, which
/// shrinks to a fraction.
String encodeGames(List<GameRow> rows) =>
    base64.encode(GZipEncoder().encode(utf8.encode(jsonEncode(rows))));

/// The most a message of games may unpack to. A game is a few kilobytes,
/// so more is a broken or hostile device.
const maxGamesBytes = 4 * 1024 * 1024;

/// The games of a message made by [encodeGames]. Throws a [FormatException]
/// for one that isn't, or that unpacks to more than [maxGamesBytes].
List<GameRow> decodeGames(String encoded) {
  final bytes = base64.decode(encoded);
  // The gzip header as [encodeGames] makes it, without optional fields. The
  // games after it are unpacked here, to stop at the limit rather than
  // after unpacking all.
  if (bytes.length < 18 ||
      bytes[0] != 0x1f ||
      bytes[1] != 0x8b ||
      bytes[2] != 8 ||
      bytes[3] != 0) {
    throw const FormatException('not a message of games');
  }
  final output = _LimitedOutput(maxGamesBytes);
  Inflate(bytes.sublist(10), output: output);
  return [
    for (final row in jsonDecode(utf8.decode(output.getBytes())) as List)
      (row as Map).cast<String, Object?>(),
  ];
}

/// Unpacked bytes, which stop with a [FormatException] at [limit].
class _LimitedOutput extends OutputMemoryStream {
  _LimitedOutput(this.limit);

  final int limit;

  void _check(int count) {
    if (length + count > limit) {
      throw const FormatException('games too large');
    }
  }

  @override
  void writeByte(int value) {
    _check(1);
    super.writeByte(value);
  }

  @override
  void writeBytes(List<int> bytes, {int? length}) {
    _check(length ?? bytes.length);
    super.writeBytes(bytes, length: length);
  }

  @override
  void writeStream(InputStream stream) {
    _check(stream.length);
    super.writeStream(stream);
  }

  @override
  void writeBackReference(int distance, int count) {
    _check(count);
    super.writeBackReference(distance, count);
  }
}
