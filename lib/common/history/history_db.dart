import 'dart:developer' as developer;

import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/history/game_record.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// The games that ended, kept in a SQLite database on the device.
///
/// A game is stored once per id, so recording it again (a synced device
/// receiving its end, a reset after it was finished) replaces the entry
/// rather than adding one.
class HistoryDb {
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
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll(Board board) async {
    final db = await _database;
    await db.delete(_table, where: 'board = ?', whereArgs: [board.name]);
  }

  Future<void> close() async {
    final db = await _db;
    _db = null;
    await db?.close();
  }
}
