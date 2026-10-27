import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/sync/sync_session.dart';
import 'package:jasstafel/common/sync/sync_transport.dart';

import '../helper/sync_fakes.dart';

BoardState state(Board board, Map<String, dynamic> data) =>
    BoardState(board, data, const {});

void main() {
  late FakeNetwork network;
  late Device host;
  late Device a;
  late Device b;

  /// Runs [body] under fakeAsync with fresh devices. They are created
  /// inside the fake zone, so their stream events run under its control.
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

  /// Starts hosting and joins [clients], the host showing [board].
  void start(FakeAsync async, {List<Device>? clients, BoardState? board}) {
    host.boards.current = board;
    host.session.startHost();
    async.flushMicrotasks();
    for (final client in clients ?? [a]) {
      client.session.startDiscovery();
      async.flushMicrotasks();
      client.session.connectToHost('H');
      async.flushMicrotasks();
    }
  }

  test('a session goes by the host\'s Bluetooth name', () {
    run((async) {
      host.transport.name = 'Galaxy XCover 4s';
      start(async);
      expect(host.session.status.value.sessionName, 'Galaxy XCover 4s');
      expect(a.session.status.value.sessionName, 'Galaxy XCover 4s');
    });
  });

  test('a host without a Bluetooth name gets a code', () {
    run((async) {
      host.transport.name = ' ';
      start(async);
      expect(
        host.session.status.value.sessionName,
        matches(RegExp(r'^Jasstafel [A-Z2-9]{2}$')),
      );
    });
  });

  test('a joining client gets the host\'s board', () {
    run((async) {
      final board = state(Board.schieber, {
        'pts': [100],
      });
      start(async, board: board);

      expect(a.boards.shown, [board]);
      expect(a.session.status.value.connectedPeers, 1);
      expect(host.session.status.value.connectedPeers, 1);
      expect(a.session.status.value.sessionName, startsWith('Jasstafel '));
    });
  });

  test('a joining client gets the host\'s board even if it has it', () {
    run((async) {
      final board = state(Board.schieber, {
        'pts': [100],
      });
      a.boards.current = board;
      start(async, board: board);

      expect(a.boards.shown, [board]);
    });
  });

  test('a client\'s change reaches the host and the other client', () {
    run((async) {
      final board = state(Board.schieber, {
        'pts': [100],
      });
      start(async, clients: [a, b], board: board);

      final changed = state(Board.schieber, {
        'pts': [100, 57],
      });
      a.boards.current = changed;
      a.session.broadcast(changed);
      async.elapse(SyncSession.debounce);
      async.flushMicrotasks();

      expect(host.boards.current, changed);
      expect(b.boards.current, changed);
      // Not sent back to a, it has it.
      expect(a.boards.shown, [board]);
    });
  });

  test('changes that cross are merged, nothing is lost', () {
    run((async) {
      start(
        async,
        board: state(Board.schieber, {
          'pts': [100],
        }),
      );

      // Both enter a round at the same moment, from the same state.
      host.boards.current = state(Board.schieber, {
        'pts': [100, 20],
      });
      host.session.broadcast(host.boards.current!);
      a.boards.current = state(Board.schieber, {
        'pts': [100, 30],
      });
      a.session.broadcast(a.boards.current!);
      async.elapse(SyncSession.debounce);
      async.flushMicrotasks();

      final merged = state(Board.schieber, {
        'pts': [100, 20, 30],
      });
      expect(host.boards.current, merged);
      expect(a.boards.current, merged);
    });
  });

  test('a board switch opens the board on the other devices', () {
    run((async) {
      start(
        async,
        board: state(Board.schieber, {
          'pts': [100],
        }),
      );

      final coiffeur = state(Board.coiffeur, {'rows': []});
      host.boards.current = coiffeur;
      host.session.boardLoaded(coiffeur);
      async.elapse(SyncSession.debounce);
      async.flushMicrotasks();

      expect(a.boards.shown.last, coiffeur);
      // The board opened on a and reported it, which doesn't send it back.
      expect(a.session.switchingTo, isNull);
      final sentBefore = a.transport.sent.length;
      async.elapse(SyncSession.debounce);
      async.flushMicrotasks();
      expect(a.transport.sent.length, sentBefore);
    });
  });

  test('settings changed on a client reach the host', () {
    run((async) {
      start(
        async,
        board: state(Board.schieber, {
          'pts': [100],
        }),
      );

      a.boards.current = BoardState(
        Board.schieber,
        {
          'pts': [100],
        },
        {'schieber_match': 300},
      );
      a.session.shareChanges();
      async.elapse(SyncSession.debounce);
      async.flushMicrotasks();

      expect(host.boards.current!.settings, {'schieber_match': 300});
    });
  });

  test('the host\'s board comes with the name of its profile', () {
    run((async) {
      final board = BoardState(
        Board.schieber,
        {
          'pts': [100],
        },
        const {},
        profile: 'Family',
      );
      start(async, board: board);

      expect(a.boards.shown.single.profile, 'Family');
    });
  });

  test('a client\'s change keeps the host\'s profile', () {
    run((async) {
      start(
        async,
        board: BoardState(
          Board.schieber,
          {
            'pts': [100],
          },
          const {},
          profile: 'Family',
        ),
      );

      final changed = BoardState(
        Board.schieber,
        {
          'pts': [100, 57],
        },
        const {},
        profile: 'Standard',
      );
      a.boards.current = changed;
      a.session.broadcast(changed);
      async.elapse(SyncSession.debounce);
      async.flushMicrotasks();

      expect(host.boards.current!.profile, 'Family');
      expect(host.boards.current!.data, changed.data);
    });
  });

  test('a board a client opened gets the host\'s profile', () {
    run((async) {
      start(
        async,
        board: state(Board.schieber, {
          'pts': [100],
        }),
      );
      host.boards.profile = 'Family';

      final coiffeur = BoardState(
        Board.coiffeur,
        {'rows': []},
        const {},
        profile: 'Standard',
      );
      a.boards.current = coiffeur;
      a.session.boardLoaded(coiffeur);
      async.elapse(SyncSession.debounce);
      async.flushMicrotasks();
      async.elapse(SyncSession.debounce);
      async.flushMicrotasks();

      expect(host.boards.current!.profile, 'Family');
      expect(a.boards.shown.last.profile, 'Family');
    });
  });

  test('a device with another protocol version is dropped', () {
    run((async) {
      start(async);

      a.transport.send('H', utf8.encode('{"proto":99,"ping":true}'));
      async.flushMicrotasks();

      expect(host.events, contains(SyncEvent.versionMismatch));
      expect(a.events, contains(SyncEvent.reconnecting));
    });
  });

  test('the host ending the session tells the clients', () {
    run((async) {
      start(async, clients: [a, b]);

      host.session.stop();
      async.flushMicrotasks();

      expect(a.events, [SyncEvent.ended]);
      expect(b.events, [SyncEvent.ended]);
      expect(a.session.isActive, isFalse);
      expect(host.events, isEmpty, reason: 'no "device left" for its own end');
    });
  });

  test('a client reconnects once the host is back', () {
    run((async) {
      start(async);

      // The host walks away: unreachable, and nothing gets through.
      host.transport.reachable = false;
      host.transport.running = false;
      async.elapse(SyncSession.pingInterval * (SyncSession.silenceTicks + 1));
      expect(a.events, [SyncEvent.reconnecting]);
      expect(a.session.status.value.connectedPeers, 0);

      async.elapse(const Duration(seconds: 30));
      host.transport.reachable = true;
      host.transport.running = true;
      async.elapse(SyncSession.reconnectPause);
      async.flushMicrotasks();

      expect(a.events, [SyncEvent.reconnecting, SyncEvent.reconnected]);
      expect(a.session.status.value.connectedPeers, 1);
      expect(host.session.status.value.connectedPeers, 1);
    });
  });

  test('a change made while the host is away reaches it once back', () {
    run((async) {
      start(
        async,
        board: state(Board.schieber, {
          'pts': [100],
        }),
      );

      host.transport.reachable = false;
      host.transport.running = false;
      async.elapse(SyncSession.pingInterval * (SyncSession.silenceTicks + 1));
      expect(a.events, [SyncEvent.reconnecting]);

      // Both enter a round meanwhile.
      host.boards.current = state(Board.schieber, {
        'pts': [100, 20],
      });
      host.session.broadcast(host.boards.current!);
      a.boards.current = state(Board.schieber, {
        'pts': [100, 30],
      });
      a.session.broadcast(a.boards.current!);
      async.elapse(const Duration(seconds: 30));

      host.transport.reachable = true;
      host.transport.running = true;
      async.elapse(SyncSession.reconnectPause);
      async.flushMicrotasks();

      final merged = state(Board.schieber, {
        'pts': [100, 20, 30],
      });
      expect(a.events, [SyncEvent.reconnecting, SyncEvent.reconnected]);
      expect(host.boards.current, merged);
      expect(a.boards.current, merged);
    });
  });

  test('a change sent again after a reconnect is not counted twice', () {
    run((async) {
      start(async, board: state(Board.schieber, {'strokes': 3}));

      // The host takes the change in, but its answer is lost.
      host.transport.losing = true;
      a.boards.current = state(Board.schieber, {'strokes': 4});
      a.session.broadcast(a.boards.current!);
      async.elapse(SyncSession.ackTimeout);
      expect(host.boards.current, state(Board.schieber, {'strokes': 4}));

      // Then the link drops.
      host.transport.losing = false;
      host.transport.disconnectPeer('A');
      async.flushMicrotasks();

      expect(a.events, [SyncEvent.reconnecting, SyncEvent.reconnected]);
      expect(host.boards.current, state(Board.schieber, {'strokes': 4}));
      expect(a.boards.current, state(Board.schieber, {'strokes': 4}));
    });
  });

  test('a client gives the session up when the host stays away', () {
    run((async) {
      start(async);

      host.transport.reachable = false;
      host.transport.running = false;
      async.elapse(SyncSession.pingInterval * (SyncSession.silenceTicks + 1));
      async.elapse(SyncSession.reconnectTimeout + SyncSession.reconnectPause);
      async.flushMicrotasks();

      expect(a.events, [SyncEvent.reconnecting, SyncEvent.connectionLost]);
      expect(a.session.isActive, isFalse);
    });
  });

  test('a silent client is dropped by the host', () {
    run((async) {
      start(async);

      a.transport.running = false;
      async.elapse(SyncSession.pingInterval * (SyncSession.silenceTicks + 1));

      expect(host.events, [SyncEvent.deviceLeft]);
      expect(host.session.status.value.connectedPeers, 0);
    });
  });

  test('Bluetooth turned off ends the session', () {
    run((async) {
      start(async);

      host.transport.setState(BluetoothState.off);
      async.flushMicrotasks();

      expect(host.events, [SyncEvent.bluetoothOff]);
      expect(host.session.isActive, isFalse);
    });
  });

  test('Bluetooth turned off ends the session though the radio hangs', () {
    run((async) {
      start(async);

      a.transport.stuck = true;
      a.transport.setState(BluetoothState.off);
      async.flushMicrotasks();

      expect(a.events, [SyncEvent.bluetoothOff]);
      expect(a.session.isActive, isFalse);
      expect(a.session.status.value.connectedPeers, 0);
    });
  });

  test('ending a session the radio doesn\'t answer ends it at once', () {
    run((async) {
      start(async);
      a.transport.stuck = true;

      var ended = false;
      a.session.stop().then((_) => ended = true);
      async.flushMicrotasks();
      expect(a.session.isActive, isFalse);
      expect(a.session.status.value.role, SyncRole.idle);

      // Ending it again doesn't hang either.
      var again = false;
      a.session.stop().then((_) => again = true);
      async.elapse(SyncSession.cleanupTimeout * 3);
      expect(ended, isTrue);
      expect(again, isTrue);
    });
  });

  test('a device joins again once its radio answers again', () {
    run((async) {
      final board = state(Board.schieber, {
        'pts': [100],
      });
      start(async, board: board);
      a.transport.stuck = true;
      a.session.stop();
      async.flushMicrotasks();
      // The host notices the client gone.
      async.elapse(SyncSession.pingInterval * (SyncSession.silenceTicks + 2));

      a.transport.stuck = false;
      a.session.startDiscovery();
      async.elapse(SyncSession.cleanupTimeout * 3);
      a.session.connectToHost('H');
      async.flushMicrotasks();

      expect(a.session.status.value.connectedPeers, 1);
      expect(a.boards.current, board);
    });
  });

  test('a host ending the session tells every client to leave', () {
    run((async) {
      start(async, clients: [a, b]);
      host.session.stop();
      async.elapse(SyncSession.cleanupTimeout * 3);

      expect(a.events, [SyncEvent.ended]);
      expect(b.events, [SyncEvent.ended]);
    });
  });

  test('ending the session while connecting leaves no link', () {
    run((async) {
      host.boards.current = state(Board.schieber, {
        'pts': [100],
      });
      host.session.startHost();
      async.flushMicrotasks();
      a.session.startDiscovery();
      async.flushMicrotasks();

      a.transport.connecting = Completer<void>();
      bool? joined;
      a.session.connectToHost('H').then((result) => joined = result);
      async.flushMicrotasks();
      a.session.stop();
      async.flushMicrotasks();
      a.transport.connecting!.complete();
      async.elapse(SyncSession.cleanupTimeout);

      expect(joined, isFalse);
      expect(a.session.status.value, const SyncStatus());
      expect(a.transport.connectedHost, isNull);
      expect(host.session.status.value.connectedPeers, 0);
      expect(a.boards.shown, isEmpty);
    });
  });

  test('a host takes six devices, a seventh is told it is full', () {
    run((async) {
      final more = [
        for (final id in ['C', 'D', 'E', 'F', 'G']) Device(id, network),
      ];
      try {
        start(async, clients: [a, b, ...more.take(4)]);
        expect(host.session.status.value.connectedPeers, 6);

        final seventh = more.last;
        seventh.session.startDiscovery();
        async.flushMicrotasks();
        seventh.session.connectToHost('H');
        async.elapse(SyncSession.cleanupTimeout);

        expect(seventh.events, [SyncEvent.full]);
        expect(seventh.session.isActive, isFalse);
        expect(seventh.transport.connectedHost, isNull);
        expect(host.session.status.value.connectedPeers, 6);
        expect(host.events, isEmpty);

        // Once one leaves, there is room again.
        a.session.stop();
        async.elapse(SyncSession.cleanupTimeout);
        seventh.session.startDiscovery();
        async.flushMicrotasks();
        seventh.session.connectToHost('H');
        async.elapse(SyncSession.cleanupTimeout);
        expect(seventh.session.status.value.connectedPeers, 1);
        expect(host.session.status.value.connectedPeers, 6);
      } finally {
        for (final device in more) {
          device.session.dispose();
        }
      }
    });
  });

  test('a host not seen anymore leaves the list', () {
    run((async) {
      host.session.startHost();
      async.flushMicrotasks();
      a.session.startDiscovery();
      async.flushMicrotasks();
      expect(a.session.hosts.value.map((h) => h.id), ['H']);

      // Seen again for a while, then not.
      for (var i = 0; i < 3; i++) {
        async.elapse(const Duration(seconds: 1));
        network.advertise();
      }
      expect(a.session.hosts.value, hasLength(1));
      async.elapse(SyncSession.staleAfter + const Duration(seconds: 1));
      expect(a.session.hosts.value, isEmpty);
    });
  });

  test('a failed connection resumes the search', () {
    run((async) {
      host.session.startHost();
      async.flushMicrotasks();
      a.session.startDiscovery();
      async.flushMicrotasks();
      host.transport.reachable = false;

      var connected = true;
      a.session.connectToHost('H').then((value) => connected = value);
      async.flushMicrotasks();

      expect(connected, isFalse);
      expect(a.transport.scanning, isTrue);
      expect(a.session.status.value.role, SyncRole.client);
    });
  });
}
