import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/data/profile_data.dart';
import 'package:jasstafel/common/history/game_record.dart';
import 'package:jasstafel/coiffeur/data/coiffeur_score.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/molotow/data/molotow_score.dart';
import 'package:jasstafel/point_board/data/point_board_score.dart';
import 'package:jasstafel/settings/point_board_settings.g.dart';
import 'package:jasstafel/settings/coiffeur_settings.g.dart';
import 'package:jasstafel/settings/molotow_settings.g.dart';
import 'package:jasstafel/guggitaler/data/guggitaler_score.dart';
import 'package:jasstafel/settings/guggitaler_settings.g.dart';
import 'package:jasstafel/schieber/data/schieber_score.dart';
import 'package:jasstafel/settings/schieber_settings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helper/testapp.dart';

Future<BoardData<SchieberSettings, SchieberScore>> loadSchieber() => BoardData(
  SchieberSettings(),
  SchieberScore(),
  SchieberSettingsKeys().data,
).load();

void main() {
  final records = <GameRecord>[];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    records.clear();
    BoardData.onGameEnded = (record) async => records.add(record);
  });

  tearDown(() => BoardData.onGameEnded = null);

  test('a finished game is recorded whenever it is saved', () async {
    final data = await loadSchieber();
    data.score.add(1000, 100);
    data.save();
    await pumpEventQueue();
    expect(records, isEmpty);

    data.score.add(1500, 0);
    expect(data.score.winner(), ['Team 1']);
    data.common.timestamps.justFinished();
    data.save();
    await pumpEventQueue();

    final record = records.single;
    expect(record.id, data.common.gameId);
    expect(record.finished, isTrue);
    expect(record.ended, data.common.timestamps.finishTime);
    expect(record.profile, 'Standard');
    expect(record.rounds, data.score.noOfRounds());
    expect(record.names, ['Team 1', 'Team 2']);
    expect(record.totals, [2500, 100]);
    expect(record.winners, ['Team 1']);
    expect(jsonDecode(record.state!)['common']['gameId'], record.id);
    expect(record.changed, data.common.timestamps.changeTime);
    expect(record.settings, isNot(contains(SchieberSettingsKeys().data)));
    expect(record.settings, contains(SchieberSettingsKeys().goalType));

    data.score.add(0, 50);
    data.save();
    await pumpEventQueue();
    expect(records.length, 2);
    expect(records.last.id, record.id);
    expect(records.last.totals, [2500, 150]);
  });

  test('the players are guessed from the team names', () {
    final data = BoardData(
      SchieberSettings(),
      SchieberScore(),
      SchieberSettingsKeys().data,
    );
    data.score.team[0].name = 'Max & Ann';
    data.score.team[1].name = 'Team 2';
    expect(data.players(), [
      ['Max', 'Ann'],
      [],
    ]);
    data.score.add(157, 0);
    data.reset();
    expect(records.single.players, [
      ['Max', 'Ann'],
      [],
    ]);
  });

  test('a schieber of three has a player alone', () {
    final data = BoardData(
      SchieberSettings()..differentGoals = true,
      SchieberScore(),
      SchieberSettingsKeys().data,
    );
    data.score.team[0].name = 'Max & Ann';
    data.score.team[0].goalPoints = 3000;
    data.score.team[1].name = 'Tom';
    data.score.team[1].goalPoints = 2000;
    expect(data.players(), [
      ['Max', 'Ann'],
      ['Tom'],
    ]);
  });

  test('a lone player named like a team is no player', () {
    final data = BoardData(
      SchieberSettings()..differentGoals = true,
      SchieberScore(),
      SchieberSettingsKeys().data,
    );
    data.score.team[0].name = 'Max & Ann';
    data.score.team[0].goalPoints = 3000;
    data.score.team[1].goalPoints = 2000;
    expect(data.players(), [
      ['Max', 'Ann'],
      [],
    ]);
  });

  test('coiffeur teams and boards without teams', () {
    final coiffeur = BoardData(
      CoiffeurSettings()..threeTeams = true,
      CoiffeurScore(),
      CoiffeurSettingsKeys().data,
    );
    coiffeur.score.teamName = ['Max & Ann', 'Tom/Eva', 'Ben Lia'];
    expect(coiffeur.players(), [
      ['Max', 'Ann'],
      ['Tom', 'Eva'],
      ['Ben', 'Lia'],
    ]);

    final molotow = BoardData(
      MolotowSettings()..players = 3,
      MolotowScore(),
      MolotowSettingsKeys().data,
    );
    molotow.score.playerName[1] = 'Ann & Co';
    expect(molotow.players(), [
      ['Spieler 1'],
      ['Ann & Co'],
      ['Spieler 3'],
    ]);
  });

  group('a game gets its id when it starts', () {
    tearDown(() => BoardData.isShared = null);

    test('on a board of its own, with its first entry', () async {
      final data = await loadSchieber();
      // Left from a board shared before, as on the other devices.
      final left = data.common.gameId;
      data.score.add(157, 0);
      data.save();
      final own = data.common.gameId;
      expect(own, isNot(left));

      data.score.add(0, 157);
      data.save();
      expect(data.common.gameId, own);
    });

    test('not while the board is shared', () async {
      BoardData.isShared = () => true;
      final data = await loadSchieber();
      final shared = data.common.gameId;
      data.score.add(157, 0);
      data.save();
      expect(data.common.gameId, shared);
    });

    test('not for a game going on', () async {
      final data = await loadSchieber();
      data.score.add(157, 0);
      data.save();
      final id = data.common.gameId;
      await pumpEventQueue();

      final again = await loadSchieber();
      expect(again.common.gameId, id);
      again.score.add(0, 157);
      again.save();
      expect(again.common.gameId, id);
    });

    test('not for a game from another device', () async {
      final data = await loadSchieber();
      final other = await loadSchieber();
      other.score.add(157, 0);
      data.applyRemote(other.currentJson(), {});
      expect(data.common.gameId, other.common.gameId);
    });
  });

  test('a reset ends the game on the board, an empty board is no game', () {
    final data = BoardData(
      SchieberSettings(),
      SchieberScore(),
      SchieberSettingsKeys().data,
    );
    data.reset();
    expect(records, isEmpty);

    final id = data.common.gameId;
    data.score.add(157, 0);
    data.score.add(50, 0, weis: true);
    final before = DateTime.now();
    data.reset();

    final record = records.single;
    expect(record.details, {
      'weis': [50, 0],
    });
    expect(record.id, id);
    expect(record.finished, isFalse);
    expect(record.rounds, 1);
    expect(record.totals, [207, 0]);
    expect(record.winners, isEmpty);
    expect(record.ended.isBefore(before), isFalse);
    expect(data.common.gameId, isNot(id));
    expect(data.played, isFalse);
  });

  test('a reset right after the finish keeps the game finished', () {
    final data = BoardData(
      SchieberSettings(),
      SchieberScore(),
      SchieberSettingsKeys().data,
    );
    data.score.add(2500, 100);
    data.common.timestamps.justFinished();
    final finishTime = data.common.timestamps.finishTime;
    data.reset();

    final record = records.single;
    expect(record.finished, isTrue);
    expect(record.ended, finishTime);
    expect(record.winners, ['Team 1']);
  });

  test('a board without a goal only ends by reset, which finishes it', () {
    final data = BoardData(
      GuggitalerSettings(),
      GuggitalerScore(),
      GuggitalerSettingsKeys().data,
    );
    expect(data.hasGoal, isFalse);
    data.score.rows.add(GuggitalerRow()..domino[0] = 15);
    data.reset();

    expect(records.single.finished, isTrue);
    expect(records.single.totals.first, 15);
  });

  test('a game that goes on in another profile is not ended', () async {
    final data = await loadSchieber();
    data.score.add(157, 0);
    final fresh = BoardData(
      SchieberSettings(),
      SchieberScore(),
      SchieberSettingsKeys().data,
    );
    data.applyRemote(fresh.currentJson(), {}, endsGame: false);
    await pumpEventQueue();
    expect(records, isEmpty);
  });

  test('the game another device replaces keeps its own settings', () {
    final data = BoardData(
      PointBoardSettings()..players = 4,
      PointBoardScore(),
      PointBoardSettingsKeys().data,
    );
    data.score.rows.add(PointBoardRow([1, 2, 3, 4]));
    final fresh = BoardData(
      PointBoardSettings()..players = 3,
      PointBoardScore(),
      PointBoardSettingsKeys().data,
    );

    data.applyRemote(fresh.currentJson(), {PointBoardSettings.keys.players: 3});

    expect(records.single.names.length, 4);
    expect(records.single.totals, [1, 2, 3, 4]);
    expect(data.settings.players, 3);
  });

  test('a state without a game id ends no game', () {
    final data = BoardData(
      SchieberSettings(),
      SchieberScore(),
      SchieberSettingsKeys().data,
    );
    data.score.add(157, 0);
    final id = data.common.gameId;
    final json = jsonDecode(data.currentJson()) as Map<String, dynamic>;
    json.remove('common');

    data.applyRemote(jsonEncode(json), {});
    expect(records, isEmpty);
    // A board without a game is a new one.
    expect(data.common.gameId, isNot(id));
  });

  test('a profile without a game starts one of its own', () async {
    final data = await loadSchieber();
    data.score.add(2500, 100);
    data.common.timestamps.justFinished();
    data.saveActiveProfile();
    final finished = data.common.gameId;

    // As saved by an app before games had ids and times.
    final map = data.profileMap();
    map['Old'] = encodeProfile({
      ...data.settings.toJson(),
      SchieberSettingsKeys().data: jsonEncode(SchieberScore().toJson()),
    });
    data.storeProfiles(map);
    await data.loadProfile('Old');
    await pumpEventQueue();
    // The finished game, as saved.
    expect(records.map((r) => r.id), [finished]);
    records.clear();

    expect(data.common.gameId, isNot(finished));
    expect(data.common.timestamps.finishTime, isNull);
    data.score.add(157, 0);
    data.save();
    await pumpEventQueue();
    expect(records, isEmpty);
  });

  test('a change is stamped later than the state it was made from', () async {
    final data = await loadSchieber();
    final ahead = DateTime.now().add(const Duration(minutes: 1));
    // As set by a device whose clock runs ahead.
    data.common.timestamps.changeTime = ahead;
    data.score.add(157, 0);
    data.save();
    expect(data.common.timestamps.changeTime!.isAfter(ahead), isTrue);
  });

  test('a change is stamped here, one from another device keeps its', () async {
    final data = await loadSchieber();
    final other = await loadSchieber();
    other.score.add(157, 0);
    other.save();
    final theirs = other.common.timestamps.changeTime!;

    data.applyRemote(other.currentJson(), {});
    expect(data.common.timestamps.changeTime, theirs);

    await Future.delayed(const Duration(milliseconds: 2));
    data.score.add(0, 157);
    data.save();
    expect(data.common.timestamps.changeTime!.isAfter(theirs), isTrue);
  });

  test('a copied profile goes on as a game of its own', () async {
    final data = await loadSchieber();
    data.score.add(157, 0);
    data.saveActiveProfile();
    final map = data.profileMap();

    final copy = data.withNewGame(map['Standard']!);
    map['Holiday'] = copy;
    data.storeProfiles(map);

    await data.loadProfile('Holiday');
    expect(data.score.totals(), [157, 0]);
    final holiday = data.common.gameId;
    await data.loadProfile('Standard');
    expect(data.common.gameId, isNot(holiday));
    expect(data.score.totals(), [157, 0]);
  });

  test('a copied profile keeps a finished game as the one it was', () async {
    final data = await loadSchieber();
    data.score.add(2500, 100);
    data.common.timestamps.justFinished();
    data.saveActiveProfile();
    final id = data.common.gameId;
    final map = data.profileMap();

    map['Holiday'] = data.withNewGame(map['Standard']!);
    data.storeProfiles(map);
    await data.loadProfile('Holiday');
    expect(data.common.gameId, id);

    data.reset();
    await pumpEventQueue();
    expect(records.map((record) => record.id).toSet(), {id});
  });

  test('a new game from another device ends the one on the board', () async {
    final data = await loadSchieber();
    data.score.add(157, 0);
    final id = data.common.gameId;

    // The same game, changed on the other device.
    final same = jsonDecode(data.currentJson()) as Map<String, dynamic>;
    same['rounds'] = [...same['rounds'], ...same['rounds']];
    data.applyRemote(jsonEncode(same), {});
    expect(records, isEmpty);

    // The other device reset the board.
    final fresh = BoardData(
      SchieberSettings(),
      SchieberScore(),
      SchieberSettingsKeys().data,
    );
    data.applyRemote(fresh.currentJson(), {});
    await pumpEventQueue();

    final record = records.single;
    expect(record.id, id);
    expect(record.finished, isFalse);
    expect(record.rounds, 2);
    expect(data.common.gameId, fresh.common.gameId);
    expect(data.played, isFalse);
  });

  testWidgets('reaching the goal saves the finish', (tester) async {
    final data = await loadSchieber();
    data.score.add(2500, 100);

    await tester.pumpWidget(
      JasstafelTestApp(
        child: Builder(
          builder: (context) {
            data.checkGameOver(context, goalType: GoalType.points);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(records.single.finished, isTrue);
    expect(records.single.winners, ['Team 1']);
    final preferences = await SharedPreferences.getInstance();
    final saved = jsonDecode(
      preferences.getString(SchieberSettingsKeys().data)!,
    );
    expect(saved['common']['timestamps']['finishTime'], isNotNull);
  });

  Future<void> pumpBoard(
    WidgetTester tester,
    BoardData<SchieberSettings, SchieberScore> data,
  ) async {
    await tester.pumpWidget(
      JasstafelTestApp(
        child: Builder(
          builder: (context) {
            data.checkGameOver(context, goalType: GoalType.points);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a finish from another device shows the winner here too', (
    tester,
  ) async {
    final data = await loadSchieber();
    final other = await loadSchieber();
    other.common = data.common;
    other.score.add(2500, 100);
    other.common.timestamps.justFinished();
    final finished = other.currentJson();

    data.applyRemote(finished, {});
    await pumpBoard(tester, data);

    expect(find.byType(AlertDialog), findsOneWidget);
    // Recorded with the shared finish, not saved again.
    expect(records.length, 1);
  });

  testWidgets('a game finished before it arrived shows no winner', (
    tester,
  ) async {
    final data = await loadSchieber();
    // Another game, finished on the other devices before joining them.
    final other = await loadSchieber();
    other.score.add(2500, 2600);
    other.common.timestamps.justFinished();

    data.applyRemote(other.currentJson(), {});
    await pumpBoard(tester, data);

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('a finished game opened again shows no winner', (tester) async {
    final data = await loadSchieber();
    data.score.add(2500, 100);
    data.common.timestamps.justFinished();
    data.save();
    await tester.runAsync(pumpEventQueue);

    final reopened = await loadSchieber();
    await pumpBoard(tester, reopened);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('switching to a finished profile shows no winner', (
    tester,
  ) async {
    final data = await loadSchieber();
    await tester.runAsync(() => data.switchProfile('Family'));
    data.score.add(2500, 100);
    data.common.timestamps.justFinished();
    data.saveActiveProfile();
    await tester.runAsync(() => data.switchProfile('Standard'));

    await tester.runAsync(() => data.loadProfile('Family'));
    expect(data.score.winner(), ['Team 1']);
    await pumpBoard(tester, data);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('the winner chosen when both reached the goal is kept', (
    tester,
  ) async {
    final data = await loadSchieber();
    data.score.add(2500, 2600);
    expect(data.score.winner(), ['Team 1', 'Team 2']);

    await tester.pumpWidget(
      JasstafelTestApp(
        child: Builder(
          builder: (context) {
            data.checkGameOver(context, goalType: GoalType.points);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(records.single.winners, ['Team 1', 'Team 2']);

    await tester.tap(find.text('Team 2'));
    await tester.pumpAndSettle();

    expect(records.last.winners, ['Team 2']);
    expect(data.score.winner(), ['Team 2']);
  });
}
