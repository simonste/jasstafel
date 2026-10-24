import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/coiffeur/data/coiffeur_score.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/sync/sync_service.dart';
import 'package:jasstafel/common/sync/sync_session.dart';
import 'package:jasstafel/schieber/data/schieber_score.dart';
import 'package:jasstafel/settings/coiffeur_settings.g.dart';
import 'package:jasstafel/settings/schieber_settings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final sync = SyncService.instance;
  late BoardData<SchieberSettings, SchieberScore> data;

  /// The host's board, in its profile [profile].
  BoardState hostBoard(String profile, {int match = 300}) => BoardState(
    Board.schieber,
    jsonDecode(data.currentJson()) as Map<String, dynamic>,
    {SchieberSettings.keys.match: match},
    profile: profile,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    data = BoardData(
      SchieberSettings(),
      SchieberScore(),
      SchieberSettingsKeys().data,
    );
    // Bound before it loads, as by the board's screen.
    sync.bind(data: data, onRemoteUpdate: () {}, onSwitchBoard: () {});
    await data.load();
    sync.statusNotifier.value = const SyncStatus(
      role: SyncRole.client,
      connectedPeers: 1,
      sessionName: 'Pixel',
    );
  });

  tearDown(() {
    sync.statusNotifier.value = const SyncStatus();
    sync.unbind(data);
  });

  test('joining asks for the profile before showing the board', () async {
    await sync.show(hostBoard('Family'));

    final request = sync.profileRequest.value!;
    expect(request.profile, 'Family');
    expect(request.active, 'Standard');
    expect(request.names, ['Standard']);
    expect(data.settings.match, 257);
  });

  test('a switch of the host while asking is asked for instead', () async {
    await sync.show(hostBoard('Family'));
    await sync.show(const BoardState(Board.coiffeur, {}, {}, profile: 'Kids'));

    final request = sync.profileRequest.value!;
    expect(request.board, Board.coiffeur);
    expect(request.profile, 'Kids');
    expect(request.names, ['Standard']);
  });

  test('the board is shown in the profile chosen', () async {
    await sync.show(hostBoard('Family'));
    await sync.chooseProfile('Family');

    expect(sync.profileRequest.value, isNull);
    expect(data.profiles.active, 'Family');
    expect(data.settings.match, 300);
    expect(data.profileMap().keys, ['Standard', 'Family']);
    expect(sync.current!.profile, 'Family');
  });

  test('the active profile is replaced if chosen', () async {
    await sync.show(hostBoard('Family'));
    await sync.chooseProfile('Standard');

    expect(data.profiles.active, 'Standard');
    expect(data.settings.match, 300);
    // Changes are told by the host's profile.
    expect(sync.current!.profile, 'Family');
  });

  test('a profile switch of the host is followed', () async {
    await sync.show(hostBoard('Family'));
    await sync.chooseProfile('Pixel Family');
    await sync.show(hostBoard('Kids', match: 1000));

    expect(data.profiles.active, 'Kids');
    expect(data.settings.match, 1000);
    await sync.show(hostBoard('Family', match: 400));
    expect(data.profiles.active, 'Pixel Family');
    expect(data.settings.match, 400);
  });

  test('a board loaded again keeps the switch of another device', () async {
    await sync.show(hostBoard('Family'));
    await sync.chooseProfile('Family');
    var switched = false;
    sync.bind(
      data: data,
      onRemoteUpdate: () {},
      onSwitchBoard: () => switched = true,
    );
    await data.load();

    final coiffeur = BoardData(
      CoiffeurSettings(),
      CoiffeurScore(),
      CoiffeurSettingsKeys().data,
    );
    await sync.show(
      BoardState(
        Board.coiffeur,
        jsonDecode(coiffeur.currentJson()) as Map<String, dynamic>,
        const {},
        profile: 'Kids',
      ),
    );
    expect(switched, isTrue);
    // As after the Schieber backside, before the other board opens.
    await data.load();

    sync.bind(data: coiffeur, onRemoteUpdate: () {}, onSwitchBoard: () {});
    await coiffeur.load();
    expect(coiffeur.profiles.active, 'Kids');
    sync.unbind(coiffeur);
  });

  test('a state arriving while the switched board loads is taken', () async {
    await sync.show(hostBoard('Family'));
    await sync.chooseProfile('Family');
    final coiffeur = BoardData(
      CoiffeurSettings(),
      CoiffeurScore(),
      CoiffeurSettingsKeys().data,
    );
    BoardState coiffeurBoard(int match) => BoardState(
      Board.coiffeur,
      jsonDecode(coiffeur.currentJson()) as Map<String, dynamic>,
      {CoiffeurSettings.keys.match: match},
      profile: 'Family',
    );

    await sync.show(coiffeurBoard(300));
    sync.bind(data: coiffeur, onRemoteUpdate: () {}, onSwitchBoard: () {});
    await sync.show(coiffeurBoard(400));
    await coiffeur.load();

    expect(coiffeur.settings.match, 400);
    sync.unbind(coiffeur);
  });

  test('ending the session asks again on the next join', () async {
    await sync.show(hostBoard('Family'));
    await sync.chooseProfile('Family');
    sync.statusNotifier.value = const SyncStatus();
    sync.statusNotifier.value = const SyncStatus(
      role: SyncRole.client,
      connectedPeers: 1,
    );

    await sync.show(hostBoard('Family'));
    expect(sync.profileRequest.value!.names, ['Standard', 'Family']);
  });
}
