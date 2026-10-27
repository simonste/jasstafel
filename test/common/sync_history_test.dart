import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/sync/sync_history.dart';
import 'package:jasstafel/common/sync/sync_session.dart';

import '../helper/sync_fakes.dart';

/// A recorded game as a row, [state] standing for its board.
GameRow game(String id, {bool finished = true, String state = '{}'}) => {
  'id': id,
  'board': 'schieber',
  'finished': finished ? 1 : 0,
  'state': state,
};

BoardState board(int points) => BoardState(Board.schieber, {
  'pts': [points],
}, const {});

void main() {
  late FakeNetwork network;
  late Device host;
  late Device a;
  late Device b;

  void run(void Function(FakeAsync async) body) {
    fakeAsync((async) {
      network = FakeNetwork();
      host = Device('H', network);
      a = Device('A', network);
      b = Device('B', network);
      try {
        body(async);
      } finally {
        for (final device in [host, a, b]) {
          device.session.dispose();
        }
      }
    });
  }

  void start(FakeAsync async, {List<Device>? clients}) {
    host.boards.current = board(0);
    host.session.startHost();
    async.flushMicrotasks();
    for (final client in clients ?? [a]) {
      client.session.startDiscovery();
      async.flushMicrotasks();
      client.session.connectToHost('H');
      async.flushMicrotasks();
    }
  }

  /// Lets the queued games go out, one batch per pause.
  void exchange(FakeAsync async, {int pauses = 5}) {
    for (var i = 0; i < pauses; i++) {
      async.elapse(SyncSession.gamesPause);
      async.flushMicrotasks();
    }
  }

  test('host and client get the games the other lacks', () {
    run((async) {
      host.history.games['h1'] = game('h1');
      host.history.games['both'] = game('both');
      a.history.games['a1'] = game('a1');
      a.history.games['both'] = game('both');

      start(async);
      exchange(async);

      expect(host.history.games.keys.toSet(), {'h1', 'both', 'a1'});
      expect(a.history.games.keys.toSet(), {'h1', 'both', 'a1'});
      // Only what was missing went over.
      expect(host.history.batches, [1]);
      expect(a.history.batches, [1]);
    });
  });

  test('the host passes a client\'s games on to the others', () {
    run((async) {
      a.history.games['a1'] = game('a1');
      b.history.games['b1'] = game('b1');

      start(async, clients: [a, b]);
      exchange(async);

      for (final device in [host, a, b]) {
        expect(device.history.games.keys.toSet(), {'a1', 'b1'});
      }
    });
  });

  test('many games go a batch at a time, the board keeps moving', () {
    run((async) {
      for (var i = 0; i < 20; i++) {
        host.history.games['g$i'] = game('g$i');
      }
      start(async);

      // A move on the board gets through right away, between the batches.
      async.elapse(SyncSession.gamesPause);
      async.flushMicrotasks();
      host.boards.current = board(157);
      host.session.broadcast(board(157));
      async.elapse(SyncSession.debounce);
      async.flushMicrotasks();
      expect(a.boards.current, board(157));
      expect(a.history.games.length, lessThan(20));

      exchange(async);
      expect(a.history.games.length, 20);
      expect(a.history.batches, [8, 8, 4]);
    });
  });

  test('a batch too big for a message is split', () {
    run((async) {
      // Boards that hardly compress, as random text.
      final random = Random(1);
      String noise() => String.fromCharCodes(
        List.generate(30000, (_) => 33 + random.nextInt(90)),
      );
      for (var i = 0; i < 8; i++) {
        host.history.games['g$i'] = game('g$i', state: noise());
      }
      start(async);
      exchange(async);

      expect(a.history.games.length, 8);
      expect(a.history.batches.length, greaterThan(1));
      expect(a.history.batches.every((n) => n < 8), isTrue);
    });
  });

  test('a game deleted here doesn\'t come back, and stays elsewhere', () {
    run((async) {
      host.history.games['g'] = game('g');
      a.history.deleted.add('g');

      start(async);
      exchange(async);

      expect(a.history.games, isEmpty);
      expect(a.history.batches, isEmpty, reason: 'not even sent');
      expect(host.history.games.keys, ['g']);
    });
  });

  test('a finished game replaces the same game unfinished', () {
    run((async) {
      host.history.games['g'] = game('g');
      a.history.games['g'] = game('g', finished: false);
      a.history.games['a'] = game('a');

      start(async);
      exchange(async);

      expect(a.history.games['g']!['finished'], 1);
      expect(host.history.games['g']!['finished'], 1);
      expect(host.history.games.keys.toSet(), {'g', 'a'});
      // The unfinished one isn't sent the other way.
      expect(host.history.batches, [1]);
    });
  });

  test('after a reconnect the games are compared again', () {
    run((async) {
      start(async);
      exchange(async);

      host.transport.reachable = false;
      host.transport.running = false;
      async.elapse(SyncSession.pingInterval * (SyncSession.silenceTicks + 1));
      // Recorded on the host meanwhile.
      host.history.games['new'] = game('new');
      host.transport.reachable = true;
      host.transport.running = true;
      async.elapse(SyncSession.reconnectPause);
      async.flushMicrotasks();
      exchange(async);

      expect(a.history.games.keys, ['new']);
    });
  });

  test('an app without the history leaves its messages alone', () {
    // As the current app reads a message: as a board state, failing on
    // those of games.
    expect(
      () => BoardState.fromJson({'proto': 1, 'have': <String>[]}),
      throwsA(anything),
    );
    expect(
      () => BoardState.fromJson({'proto': 1, 'games': encodeGames([])}),
      throwsA(anything),
    );
  });

  test('games survive the way through a message', () {
    final rows = [game('a'), game('b', finished: false, state: '{"x":[1,2]}')];
    expect(decodeGames(encodeGames(rows)), rows);
  });
}
