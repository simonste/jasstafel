import 'dart:developer' as developer;

import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/history/game_record.dart';
import 'package:jasstafel/common/sync/sync_history.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// The games that ended, kept in a SQLite database on the device.
///
/// A game is stored once per id, so recording it again (a synced device
/// receiving its end, a reset after it was finished) replaces the entry
/// rather than adding one.
///
/// Games deleted here are remembered, so the devices of a shared board,
/// which send each other the games they lack or have in an earlier
/// revision, don't bring them back.
class HistoryDb implements SyncHistory {
  /// The database the app records into, opened on first use.
  static final HistoryDb instance = HistoryDb();

  /// [factory] and [path] default to the platform's; tests pass the ffi
  /// factory with [inMemoryDatabasePath].
  HistoryDb({DatabaseFactory? factory, String? path})
    : _factory = factory,
      _path = path;

  final DatabaseFactory? _factory;
  final String? _path;
  Future<Database>? _db;

  static const _table = 'games';
  static const _deleted = 'deleted';

  static const _version = 1;

  Future<Database> get _database => _db ??= _open();

  Future<Database> _open() async {
    try {
      return await _openDatabase();
    } catch (_) {
      // Not kept, so that the next call tries again.
      _db = null;
      rethrow;
    }
  }

  Future<Database> _openDatabase() async {
    final factory = _factory ?? databaseFactory;
    final path =
        _path ?? p.join(await factory.getDatabasesPath(), 'history.db');
    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _version,
        onCreate: (db, version) async {
          await db.execute('CREATE TABLE $_deleted (id TEXT PRIMARY KEY)');
          await db.execute('''
          CREATE TABLE $_table (
            id TEXT PRIMARY KEY,
            board TEXT NOT NULL,
            profile TEXT NOT NULL,
            started INTEGER,
            ended INTEGER NOT NULL,
            changed INTEGER NOT NULL,
            finished INTEGER NOT NULL,
            rounds INTEGER NOT NULL,
            names TEXT NOT NULL,
            totals TEXT NOT NULL,
            details TEXT NOT NULL,
            players TEXT NOT NULL,
            winners TEXT NOT NULL,
            losers TEXT NOT NULL,
            state TEXT NOT NULL,
            settings TEXT NOT NULL
          )
        ''');
        },
      ),
    );
  }

  /// Stores [record], replacing an entry of the same id. Not one of a later
  /// revision, see [SyncHistory.revisionOf]: a synced device may have sent
  /// the game as it went on after the board here last saw it. Nor one
  /// deleted here, which its board may still show and save again.
  Future<void> upsert(GameRecord record) async {
    final db = await _database;
    final row = record.toRow();
    await db.transaction((txn) async {
      final deleted = await txn.query(
        _deleted,
        where: 'id = ?',
        whereArgs: [record.id],
      );
      if (deleted.isNotEmpty) return;
      final kept = await txn.query(
        _table,
        columns: ['finished', 'changed'],
        where: 'id = ?',
        whereArgs: [record.id],
      );
      if (kept.isNotEmpty &&
          SyncHistory.revisionOf(kept.single) > SyncHistory.revisionOf(row)) {
        return;
      }
      await txn.insert(
        _table,
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  /// Like [upsert], but a failure is logged rather than thrown, for callers
  /// that must not fail over the history, such as saving the board.
  Future<void> record(GameRecord record) async {
    try {
      await upsert(record);
    } catch (e, stack) {
      developer.log(
        'recording game ${record.id} failed',
        name: 'jasstafel history',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// The columns of the list: all but the board's state, which is the bulk
  /// of a game and isn't shown.
  static const _listColumns = [
    'id',
    'board',
    'profile',
    'started',
    'ended',
    'changed',
    'finished',
    'rounds',
    'names',
    'totals',
    'details',
    'players',
    'winners',
    'losers',
    'settings',
  ];

  /// The games of [board], the one that ended last first, without their
  /// [GameRecord.state].
  Future<List<GameRecord>> games(Board board) async {
    final db = await _database;
    final rows = await db.query(
      _table,
      columns: _listColumns,
      where: 'board = ?',
      whereArgs: [board.name],
      orderBy: 'ended DESC',
    );
    return [for (final row in rows) GameRecord.fromRow(row)];
  }

  Future<void> delete(String id) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.insert(_deleted, {
        'id': id,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await txn.delete(_table, where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> deleteAll(Board board) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.rawInsert(
        'INSERT OR IGNORE INTO $_deleted (id) '
        'SELECT id FROM $_table WHERE board = ?',
        [board.name],
      );
      await txn.delete(_table, where: 'board = ?', whereArgs: [board.name]);
    });
  }

  @override
  Future<Map<String, int>> revisions() async {
    final db = await _database;
    final rows = await db.rawQuery(
      'SELECT id, finished, changed FROM $_table '
      'UNION SELECT id, 1, ? FROM $_deleted',
      [SyncHistory.deleted],
    );
    return {
      for (final row in rows) row['id'] as String: SyncHistory.revisionOf(row),
    };
  }

  @override
  Future<List<GameRow>> rows(Iterable<String> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return [];
    final db = await _database;
    return db.query(
      _table,
      where: 'id IN (${List.filled(list.length, '?').join(', ')})',
      whereArgs: list,
    );
  }

  @override
  Future<void> take(List<GameRow> rows) async {
    final db = await _database;
    await db.transaction((txn) async {
      for (final row in rows) {
        final GameRecord game;
        try {
          game = GameRecord.fromRow(row);
        } catch (_) {
          // From a broken or foreign device.
          continue;
        }
        // Nor one without its board, which the history can't keep.
        if (game.state == null) continue;
        final deleted = await txn.query(
          _deleted,
          where: 'id = ?',
          whereArgs: [game.id],
        );
        if (deleted.isNotEmpty) continue;
        final kept = await txn.query(
          _table,
          columns: ['finished', 'changed', 'profile'],
          where: 'id = ?',
          whereArgs: [game.id],
        );
        if (kept.isEmpty) {
          await txn.insert(_table, game.toRow());
        } else if (SyncHistory.revisionOf(kept.single) <
            SyncHistory.revisionOf(game.toRow())) {
          // The end of a game this device left before it finished, or a
          // change made to it after, under the profile it was played in
          // here.
          await txn.insert(_table, {
            ...game.toRow(),
            'profile': kept.single['profile'],
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }

  Future<void> close() async {
    final db = await _db;
    _db = null;
    await db?.close();
  }
}
