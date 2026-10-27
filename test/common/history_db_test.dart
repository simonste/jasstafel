import 'dart:io';

import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/history/game_record.dart';
import 'package:jasstafel/common/history/history_db.dart';
import 'package:jasstafel/common/history/history_statistics.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

GameRecord record(
  String id, {
  Board board = Board.schieber,
  DateTime? ended,
  bool finished = true,
  List<String> names = const ['Wir', 'Ihr'],
  List<int> totals = const [2500, 1800],
  List<String> winners = const ['Wir'],
  List<List<String>> players = const [],
  Map<String, List<int>> details = const {},
}) {
  ended ??= DateTime(2026, 10, 24, 20);
  return GameRecord(
    id: id,
    board: board,
    profile: 'Standard',
    started: ended.subtract(const Duration(minutes: 42)),
    ended: ended,
    finished: finished,
    rounds: 12,
    names: names,
    totals: totals,
    players: players,
    details: details,
    winners: winners,
    losers: const [],
    state: '{"rounds":[]}',
    settings: const {'schieber_goal_points': 2500},
  );
}

void main() {
  late HistoryDb db;

  setUpAll(sqfliteFfiInit);

  setUp(() {
    db = HistoryDb(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
  });

  tearDown(() => db.close());

  test('the players of the teams are kept', () async {
    await db.upsert(
      record(
        'g',
        players: [
          ['Max', 'Matthew'],
          [],
        ],
      ),
    );
    expect((await db.games(Board.schieber)).single.players, [
      ['Max', 'Matthew'],
      [],
    ]);
  });

  test('players are counted in whichever team they played', () {
    // Five players, four of them at a time, the pairs changing.
    final stats = HistoryStatistics([
      record(
        '1',
        names: ['Max & Ann', 'Tom & Eva'],
        winners: ['Max & Ann'],
        players: [
          ['Max', 'Ann'],
          ['Tom', 'Eva'],
        ],
      ),
      record(
        '2',
        names: ['Max & Tom', 'Ann & Ben'],
        winners: ['Max & Tom'],
        players: [
          ['Max', 'Tom'],
          ['Ann', 'Ben'],
        ],
      ),
      record(
        '3',
        names: ['Eva & Ben', 'Ann & Tom'],
        winners: ['Ann & Tom'],
        players: [
          ['Eva', 'Ben'],
          ['Ann', 'Tom'],
        ],
      ),
    ]);

    expect(stats.hasTeams, isTrue);
    final byName = {for (final p in stats.players) p.name: p};
    expect(byName.keys.toSet(), {'Max', 'Ann', 'Tom', 'Eva', 'Ben'});
    expect([byName['Max']!.games, byName['Max']!.wins], [2, 2]);
    expect([byName['Ann']!.games, byName['Ann']!.wins], [3, 2]);
    expect([byName['Tom']!.games, byName['Tom']!.wins], [3, 2]);
    expect([byName['Eva']!.games, byName['Eva']!.wins], [2, 0]);
    expect([byName['Ben']!.games, byName['Ben']!.wins], [2, 0]);
    expect(stats.players.first.name, 'Max');
    expect(byName['Ann']!.winRate, closeTo(0.667, 0.001));
  });

  test('players of boards without teams make no teams', () {
    final stats = HistoryStatistics([
      record(
        '1',
        names: ['Max', 'Ann', 'Tom'],
        totals: [10, 20, 30],
        players: [
          ['Max'],
          ['Ann'],
          ['Tom'],
        ],
      ),
    ]);
    expect(stats.hasTeams, isFalse);
  });

  test('a game is stored once, the latest version of it', () async {
    await db.upsert(record('g1', totals: [2000, 1800], winners: []));
    await db.upsert(record('g1'));

    final games = await db.games(Board.schieber);
    expect(games.length, 1);
    expect(games.single.totals, [2500, 1800]);
    expect(games.single.winners, ['Wir']);
    expect(games.single.duration, const Duration(minutes: 42));
    expect(games.single.settings, {'schieber_goal_points': 2500});
  });

  test('games are listed per board, the latest first', () async {
    await db.upsert(record('old', ended: DateTime(2026, 1, 1)));
    await db.upsert(record('new', ended: DateTime(2026, 6, 1)));
    await db.upsert(record('other', board: Board.molotow));

    final games = await db.games(Board.schieber);
    expect([for (final g in games) g.id], ['new', 'old']);
    expect((await db.games(Board.molotow)).single.id, 'other');
  });

  test('a game without a start has no duration', () async {
    await db.upsert(
      GameRecord(
        id: 'g',
        board: Board.coiffeur,
        profile: 'Standard',
        started: null,
        ended: DateTime(2026, 10, 24),
        finished: false,
        rounds: 0,
        names: const ['A', 'B'],
        totals: const [0, 0],
        winners: const [],
        losers: const [],
        state: '{}',
        settings: const {},
      ),
    );
    final game = (await db.games(Board.coiffeur)).single;
    expect(game.duration, isNull);
    expect(game.finished, isFalse);
  });

  test('games can be deleted one by one or per board', () async {
    await db.upsert(record('a'));
    await db.upsert(record('b'));
    await db.upsert(record('m', board: Board.molotow));

    await db.delete('a');
    expect((await db.games(Board.schieber)).single.id, 'b');

    await db.deleteAll(Board.schieber);
    expect(await db.games(Board.schieber), isEmpty);
    expect((await db.games(Board.molotow)).single.id, 'm');
  });

  test('record logs a failure instead of throwing', () async {
    final broken = HistoryDb(
      factory: databaseFactoryFfi,
      path: '/nonexistent/dir/x.db',
    );
    await broken.record(record('g'));
    await expectLater(broken.upsert(record('g')), throwsA(anything));
  });

  test('a failed open is tried again on the next call', () async {
    final dir = Directory.systemTemp.createTempSync('history');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = HistoryDb(
      factory: databaseFactoryFfi,
      path: '${dir.path}/history.db',
    );
    addTearDown(file.close);

    // Can't be written, as on a full or locked storage.
    Process.runSync('chmod', ['500', dir.path]);
    await expectLater(file.upsert(record('g')), throwsA(anything));
    Process.runSync('chmod', ['700', dir.path]);

    await file.upsert(record('g'));
    expect((await file.games(Board.schieber)).single.id, 'g');
  });

  test('the games are still there when opened again', () async {
    final dir = Directory.systemTemp.createTempSync('history');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = '${dir.path}/history.db';

    final first = HistoryDb(factory: databaseFactoryFfi, path: path);
    await first.upsert(
      record(
        'g',
        players: [
          ['Max', 'Ann'],
          [],
        ],
      ),
    );
    await first.close();

    final again = HistoryDb(factory: databaseFactoryFfi, path: path);
    addTearDown(again.close);
    final game = (await again.games(Board.schieber)).single;
    expect(game.id, 'g');
    expect(game.players, [
      ['Max', 'Ann'],
      [],
    ]);
  });

  test('the details are kept', () async {
    final details = {
      'handWeis': [-20, 0],
      'tableWeis': [0, 50],
    };
    await db.upsert(record('g', details: details));
    expect((await db.games(Board.schieber)).single.details, details);
  });

  test('statistics average the details over the games', () {
    final stats = HistoryStatistics([
      record(
        '1',
        names: ['A', 'B'],
        details: {
          'weis': [100, 20],
        },
      ),
      record(
        '2',
        names: ['A', 'B'],
        details: {
          'weis': [50, 0],
        },
      ),
      record(
        '3',
        names: ['B', 'A'],
        details: {
          'weis': [0, 0],
        },
      ),
    ]);
    expect(stats.detailKinds, ['weis']);
    final a = stats.names.firstWhere((n) => n.name == 'A');
    expect(a.averageOf('weis'), 50);
    expect(HistoryStatistics([record('x')]).detailKinds, isEmpty);
  });

  test('statistics count games, wins and points per name', () {
    final stats = HistoryStatistics([
      record('1', names: ['Wir', 'Ihr'], totals: [2500, 1800]),
      record(
        '2',
        names: ['Ihr', 'Wir'],
        totals: [2510, 2200],
        winners: ['Ihr'],
      ),
      record(
        '3',
        names: ['Wir', 'Sie'],
        totals: [900, 1000],
        finished: false,
        winners: [],
      ),
    ]);

    expect(stats.games, 3);
    expect(stats.finished, 2);
    // The game reset before its end counts nowhere.
    final byName = {for (final n in stats.names) n.name: n};
    expect(byName.keys.toSet(), {'Wir', 'Ihr'});
    final wir = byName['Wir']!;
    expect(wir.games, 2);
    expect(wir.wins, 1);
    expect(wir.points, 2500 + 2200);
    expect(wir.average, 2350);
    expect([byName['Ihr']!.games, byName['Ihr']!.wins], [2, 1]);
  });
}
