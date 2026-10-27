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
/// which send each other the games they lack, don't bring them back.
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

  /// Stores [record], replacing an entry of the same id.
  Future<void> upsert(GameRecord record) async {
    final db = await _database;
    await db.insert(
      _table,
      record.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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

  /// The games of [board], the one that ended last first.
  Future<List<GameRecord>> games(Board board) async {
    final db = await _database;
    final rows = await db.query(
      _table,
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
  Future<Map<String, bool>> ids() async {
    final db = await _database;
    final rows = await db.rawQuery(
      'SELECT id, finished FROM $_table '
      'UNION SELECT id, 1 FROM $_deleted',
    );
    return {for (final row in rows) row['id'] as String: row['finished'] == 1};
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
        final deleted = await txn.query(
          _deleted,
          where: 'id = ?',
          whereArgs: [game.id],
        );
        if (deleted.isNotEmpty) continue;
        final kept = await txn.query(
          _table,
          columns: ['finished', 'profile'],
          where: 'id = ?',
          whereArgs: [game.id],
        );
        if (kept.isEmpty) {
          await txn.insert(_table, game.toRow());
        } else if (kept.single['finished'] == 0 && game.finished) {
          // The end of a game this device left before it finished, under
          // the profile it was played in here.
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
