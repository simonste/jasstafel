import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/history/game_record.dart';
import 'package:jasstafel/common/sync/sync_service.dart';
import 'package:jasstafel/common/sync/sync_session.dart';
import 'package:jasstafel/schieber/data/schieber_score.dart';
import 'package:jasstafel/settings/schieber_settings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What the history keeps of games on a board that joins a shared one.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final sync = SyncService.instance;
  final records = <GameRecord>[];
  late BoardData<SchieberSettings, SchieberScore> data;

  BoardData<SchieberSettings, SchieberScore> board() => BoardData(
    SchieberSettings(),
    SchieberScore(),
    SchieberSettingsKeys().data,
  );

  /// The host's board [host], shown in the host's profile [profile].
  BoardState hostBoard(
    BoardData<SchieberSettings, SchieberScore> host, {
    String profile = 'Standard',
  }) => BoardState(
    Board.schieber,
    jsonDecode(host.currentJson()) as Map<String, dynamic>,
    const {},
    profile: profile,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    records.clear();
    BoardData.onGameEnded = (record) async => records.add(record);
    data = await board().load();
    sync.bind(data: data, onRemoteUpdate: () {}, onSwitchBoard: () {});
    sync.statusNotifier.value = const SyncStatus(
      role: SyncRole.client,
      connectedPeers: 1,
      sessionName: 'Pixel',
    );
  });

  tearDown(() {
    sync.statusNotifier.value = const SyncStatus();
    sync.unbind(data);
    BoardData.onGameEnded = null;
  });

  test('joining into a new profile keeps the game on the board', () async {
    data.score.add(157, 0);
    final local = data.common.gameId;

    await sync.show(hostBoard(board()));
    await sync.chooseProfile('Pixel Standard');

    expect(records, isEmpty);
    expect(data.profiles.active, 'Pixel Standard');
    expect(data.common.gameId, isNot(local));
  });

  test('joining onto the active profile ends its game', () async {
    data.score.add(157, 0);
    final local = data.common.gameId;

    await sync.show(hostBoard(board()));
    await sync.chooseProfile('Standard');

    final record = records.single;
    expect(record.id, local);
    expect(record.finished, isFalse);
    expect(record.totals, [157, 0]);
    expect(record.profile, 'Standard');
  });

  test('joining onto another profile ends that profile\'s game', () async {
    // A game in Family, then back to Standard with a game of its own.
    await data.switchProfile('Family');
    data.score.add(100, 57);
    data.saveActiveProfile();
    await data.switchProfile('Standard');
    data.score.add(157, 0);

    await sync.show(hostBoard(board()));
    await sync.chooseProfile('Family');

    final record = records.single;
    expect(record.profile, 'Family');
    expect(record.totals, [100, 57]);
  });

  test('an active profile missing from the list still ends its game', () async {
    sync.unbind(data);
    SharedPreferences.setMockInitialValues({
      '${SchieberSettingsKeys().data}_profiles': ['Family:{}'],
    });
    data = await board().load();
    sync.bind(data: data, onRemoteUpdate: () {}, onSwitchBoard: () {});
    expect(data.profileMap().keys, ['Family']);
    data.score.add(157, 0);

    await sync.show(hostBoard(board()));
    await sync.chooseProfile('Standard');

    expect(records.single.totals, [157, 0]);
  });

  test('an empty board ends no game when joining', () async {
    await sync.show(hostBoard(board()));
    await sync.chooseProfile('Standard');
    expect(records, isEmpty);
  });

  test('the same game coming back ends nothing', () async {
    final host = board();
    host.score.add(157, 0);
    await sync.show(hostBoard(host));
    await sync.chooseProfile('Standard');

    host.score.add(0, 157);
    await sync.show(hostBoard(host));
    expect(records, isEmpty);
    expect(data.score.totals(), [157, 157]);
  });

  test('the host\'s finish is recorded on the joined board', () async {
    final host = board();
    await sync.show(hostBoard(host));
    await sync.chooseProfile('Pixel Standard');

    host.score.add(2500, 100);
    host.common.timestamps.justFinished();
    await sync.show(hostBoard(host));
    await pumpEventQueue();

    final record = records.single;
    expect(record.id, host.common.gameId);
    expect(record.finished, isTrue);
    expect(record.ended, host.common.timestamps.finishTime);
    expect(record.profile, 'Pixel Standard');
  });

  test('a new game of the host ends the shared one here', () async {
    final host = board();
    await sync.show(hostBoard(host));
    await sync.chooseProfile('Standard');
    host.score.add(157, 0);
    await sync.show(hostBoard(host));
    final shared = host.common.gameId;

    // The host keeps its own history.
    final hook = BoardData.onGameEnded;
    BoardData.onGameEnded = null;
    host.reset();
    BoardData.onGameEnded = hook;
    await sync.show(hostBoard(host));

    expect(records.where((r) => r.id == shared).length, 1);
    expect(data.common.gameId, host.common.gameId);
  });

  test('following the host into a profile new here ends nothing', () async {
    final host = board();
    host.score.add(157, 0);
    await sync.show(hostBoard(host, profile: 'Family'));
    await sync.chooseProfile('Pixel Family');

    final other = board();
    other.score.add(20, 137);
    await sync.show(hostBoard(other, profile: 'Kids'));

    // Family's game goes on in Pixel Family.
    expect(records, isEmpty);
    expect(data.profiles.active, 'Kids');
  });
}
