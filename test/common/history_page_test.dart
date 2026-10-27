import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/history/game_record.dart';
import 'package:jasstafel/common/history/history_db.dart';
import 'package:jasstafel/common/history/history_page.dart';

import '../helper/testapp.dart';

/// The history kept in memory: a widget test's fake clock never sees SQLite
/// answer, the database itself is tested on its own.
class FakeHistoryDb extends HistoryDb {
  final _games = <String, GameRecord>{};

  @override
  Future<void> upsert(GameRecord record) async => _games[record.id] = record;

  @override
  Future<List<GameRecord>> games(Board board) async =>
      _games.values.where((g) => g.board == board).toList()
        ..sort((a, b) => b.ended.compareTo(a.ended));

  @override
  Future<void> delete(String id) async => _games.remove(id);

  @override
  Future<void> deleteAll(Board board) async =>
      _games.removeWhere((_, g) => g.board == board);

  @override
  Future<void> close() async {}
}

/// A history whose database can't be read.
class BrokenHistoryDb extends FakeHistoryDb {
  @override
  Future<List<GameRecord>> games(Board board) async =>
      throw StateError('database is locked');
}

GameRecord record(
  String id, {
  DateTime? ended,
  bool finished = true,
  List<String> names = const ['Wir', 'Ihr'],
  List<int> totals = const [2500, 1800],
  List<String> winners = const ['Wir'],
  List<List<String>> players = const [],
  Map<String, List<int>> details = const {},
}) {
  ended ??= DateTime(2026, 10, 24, 20, 30);
  return GameRecord(
    id: id,
    board: Board.schieber,
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
    state: '{}',
    settings: const {},
  );
}

void main() {
  late FakeHistoryDb db;

  setUp(() => db = FakeHistoryDb());

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      JasstafelTestApp(child: HistoryPage(Board.schieber, db: db)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a history that can\'t be read says why', (tester) async {
    await tester.pumpWidget(
      JasstafelTestApp(
        child: HistoryPage(Board.schieber, db: BrokenHistoryDb()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('database is locked'), findsOneWidget);
  });

  testWidgets('another board\'s games are not shown', (tester) async {
    await db.upsert(
      GameRecord(
        id: 'm',
        board: Board.molotow,
        profile: 'Standard',
        started: null,
        ended: DateTime(2026, 10, 24),
        finished: true,
        rounds: 3,
        names: const ['Max', 'Ann'],
        totals: const [10, 20],
        winners: const ['Max'],
        losers: const [],
        state: '{}',
        settings: const {},
      ),
    );
    await pumpPage(tester);
    expect(find.text('Noch keine Spiele beendet.'), findsOneWidget);
  });

  testWidgets('only unfinished games show no tables', (tester) async {
    await db.upsert(record('1', finished: false, winners: []));
    await pumpPage(tester);
    expect(find.text('Ø Punkte'), findsNothing);
    expect(find.byType(ListTile), findsOneWidget);
  });

  testWidgets('the weis is shown where it was kept', (tester) async {
    await db.upsert(record('1'));
    await pumpPage(tester);
    expect(find.text('Ø Weis'), findsNothing);

    await db.upsert(
      record(
        '2',
        details: {
          'weis': [150, 20],
        },
        ended: DateTime(2026, 10, 25),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    await pumpPage(tester);
    expect(find.text('Ø Weis'), findsOneWidget);
    final tile = tester.widget<ListTile>(find.byType(ListTile).first);
    expect((tile.subtitle as Text).data, contains('Weis 150 | 20'));
  });

  testWidgets('molotow shows hand and table weis apart', (tester) async {
    await db.upsert(
      record(
        '1',
        names: ['A', 'B'],
        details: {
          'handWeis': [-20, 0],
          'tableWeis': [50, 20],
        },
      ),
    );
    await pumpPage(tester);
    expect(find.text('Ø Weis'), findsNothing);
    expect(find.text('Ø Hand'), findsOneWidget);
    expect(find.text('Ø Tisch'), findsOneWidget);
    final tile = tester.widget<ListTile>(find.byType(ListTile));
    final subtitle = (tile.subtitle as Text).data!;
    expect(subtitle, contains('Handweis -20 | 0'));
    expect(subtitle, contains('Tischweis 50 | 20'));
  });

  testWidgets('an empty history says so', (tester) async {
    await pumpPage(tester);
    expect(find.text('Noch keine Spiele beendet.'), findsOneWidget);
  });

  testWidgets('the players of the teams get their own table', (tester) async {
    await pumpPage(tester);
    expect(find.text('Spieler'), findsNothing);

    await db.upsert(
      record(
        '1',
        names: ['Max & Ann', 'Tom & Eva'],
        winners: ['Max & Ann'],
        players: [
          ['Max', 'Ann'],
          ['Tom', 'Eva'],
        ],
      ),
    );
    // A page opened again, not the same one rebuilt.
    await tester.pumpWidget(const SizedBox());
    await pumpPage(tester);
    expect(find.text('Spieler'), findsOneWidget);
    expect(find.text('Siegquote'), findsOneWidget);
    final max = find.ancestor(of: find.text('Max'), matching: find.byType(Row));
    expect(
      find.descendant(of: max.first, matching: find.text('100 %')),
      findsOneWidget,
    );
    final eva = find.ancestor(of: find.text('Eva'), matching: find.byType(Row));
    expect(
      find.descendant(of: eva.first, matching: find.text('0 %')),
      findsOneWidget,
    );
  });

  testWidgets('the games and the summary are shown', (tester) async {
    await db.upsert(record('1'));
    await db.upsert(
      record(
        '2',
        ended: DateTime(2026, 10, 25, 9, 5),
        names: ['Wir', 'Sie'],
        totals: [900, 1200],
        finished: false,
        winners: [],
      ),
    );
    await pumpPage(tester);

    // The tables count the finished game only: Wir 1 game, 1 win, 2500.
    expect(find.text('1 Spiel'), findsOneWidget);
    final wir = find.text('Wir');
    expect(wir, findsOneWidget);
    final row = find.ancestor(of: wir, matching: find.byType(Row)).first;
    expect(
      find.descendant(of: row, matching: find.text('1')),
      findsNWidgets(2),
    );
    expect(
      find.descendant(of: row, matching: find.text('2500')),
      findsOneWidget,
    );
    expect(find.text('Sie'), findsNothing);

    final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
    expect(tiles.length, 2);
    // the latest first, not finished
    expect(
      (tiles[0].title as Text).textSpan!.toPlainText(),
      'Wir 900  |  Sie 1200',
    );
    expect((tiles[0].subtitle as Text).data, contains('nicht beendet'));
    expect((tiles[0].subtitle as Text).data, contains('42 min'));
    expect(
      (tiles[1].title as Text).textSpan!.toPlainText(),
      'Wir 2500  |  Ihr 1800',
    );
    expect((tiles[1].subtitle as Text).data, isNot(contains('nicht beendet')));
  });

  testWidgets('a game left open for long shows no duration', (tester) async {
    final ended = DateTime(2026, 10, 24, 20);
    await db.upsert(
      GameRecord(
        id: 'long',
        board: Board.schieber,
        profile: 'Standard',
        started: ended.subtract(const Duration(hours: 24)),
        ended: ended,
        finished: true,
        rounds: 5,
        names: const ['Wir', 'Ihr'],
        totals: const [2500, 1800],
        winners: const ['Wir'],
        losers: const [],
        state: '{}',
        settings: const {},
      ),
    );
    await pumpPage(tester);

    final tile = tester.widget<ListTile>(find.byType(ListTile));
    expect((tile.subtitle as Text).data, isNot(contains('min')));
  });

  testWidgets('a game is deleted after confirming', (tester) async {
    await db.upsert(record('1'));
    await db.upsert(record('2', ended: DateTime(2026, 10, 25)));
    await pumpPage(tester);

    await tester.tap(find.byIcon(Icons.delete).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.delete).first);
    await tester.pumpAndSettle();
    expect(find.text('Spiel löschen'), findsOneWidget);
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsOneWidget);
    expect((await db.games(Board.schieber)).single.id, '1');
  });

  testWidgets('the whole history is deleted after confirming', (tester) async {
    await db.upsert(record('1'));
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('deleteHistory')));
    await tester.pumpAndSettle();
    expect(find.text('Verlauf löschen'), findsOneWidget);
    await tester.tap(find.text('Ok'));
    await tester.pumpAndSettle();

    expect(find.text('Noch keine Spiele beendet.'), findsOneWidget);
    expect(await db.games(Board.schieber), isEmpty);
  });
}
