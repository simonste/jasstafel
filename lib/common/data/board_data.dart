import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jasstafel/coiffeur/data/coiffeur_score.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/rounding.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/common/data/common_data.dart';
import 'package:jasstafel/common/data/profile_data.dart';
import 'package:jasstafel/common/dialog/winner_dialog.dart';
import 'package:jasstafel/differenzler/data/differenzler_score.dart';
import 'package:jasstafel/guggitaler/data/guggitaler_score.dart';
import 'package:jasstafel/molotow/data/molotow_score.dart';
import 'package:jasstafel/point_board/data/point_board_score.dart';
import 'package:jasstafel/schieber/data/schieber_score.dart';
import 'package:jasstafel/schlaeger/data/schlaeger_score.dart';
import 'package:jasstafel/settings/board_settings.dart';
import 'package:jasstafel/settings/coiffeur_settings.g.dart';
import 'package:jasstafel/settings/guggitaler_settings.g.dart';
import 'package:jasstafel/settings/molotow_settings.g.dart';
import 'package:jasstafel/settings/point_board_settings.g.dart';
import 'package:jasstafel/settings/schieber_settings.g.dart';
import 'package:jasstafel/settings/differenzler_settings.g.dart';
import 'package:jasstafel/settings/schlaeger_settings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

abstract class Score {
  Map<String, dynamic> toJson();

  void reset(int? duration);
  int noOfRounds();
  int totalPoints();

  List<String> winner();
  void setWinner(String team);
  List<String> loser(); // not empty if fewest points win
}

class BoardData<T extends BoardSettings, S extends Score> {
  final String dataKey;
  final String activeProfileKey;
  final String profilesKey;
  T settings;
  S score;
  var common = CommonData();
  ProfileData profiles = ProfileData("Standard", []);
  final Board boardType;
  bool supportsVibration = false;

  /// Broadcasts the serialized board state to synced devices, if a sync
  /// session is active. Wired up by the sync service while a board is visible.
  static void Function(BoardData<BoardSettings, Score> data, String json)?
  onSaveBroadcast;

  /// Called once a board is loaded, for the sync service to share it.
  static void Function(BoardData<BoardSettings, Score> data)? onLoaded;

  static Board determineBoardType(Score score) {
    if (score is SchieberScore) {
      return Board.schieber;
    } else if (score is CoiffeurScore) {
      return Board.coiffeur;
    } else if (score is MolotowScore) {
      return Board.molotow;
    } else if (score is PointBoardScore) {
      return Board.pointBoard;
    } else if (score is DifferenzlerScore) {
      return Board.differenzler;
    } else if (score is GuggitalerScore) {
      return Board.guggitaler;
    } else if (score is SchlaegerScore) {
      return Board.schlaeger;
    } else {
      assert(false);
    }
    return Board.schieber;
  }

  BoardData(this.settings, this.score, this.dataKey)
    : profilesKey = "${dataKey}_profiles",
      activeProfileKey = "${dataKey}_profile",
      boardType = determineBoardType(score) {
    _updateSettings();
  }

  void _updateSettings() {
    switch (boardType) {
      case Board.schieber:
        (score as SchieberScore).setSettings(settings as SchieberSettings);
        break;
      case Board.coiffeur:
        (score as CoiffeurScore).setSettings(settings as CoiffeurSettings);
        break;
      case Board.molotow:
        (score as MolotowScore).setSettings(settings as MolotowSettings);
        break;
      case Board.pointBoard:
        (score as PointBoardScore).setSettings(settings as PointBoardSettings);
        break;
      case Board.differenzler:
        (score as DifferenzlerScore).setSettings(
          settings as DifferenzlerSettings,
        );
        break;
      case Board.guggitaler:
        (score as GuggitalerScore).setSettings(settings as GuggitalerSettings);
        break;
      case Board.schlaeger:
        (score as SchlaegerScore).setSettings(settings as SchlaegerSettings);
        break;
    }
  }

  Future<BoardData<T, S>> load() async {
    final preferences = await SharedPreferences.getInstance();

    await migrateRoundedPreferences(preferences);

    try {
      var hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        supportsVibration = true;
      }
    } on MissingPluginException {
      // https://github.com/benjamindean/flutter_vibration/issues/77
    }

    switch (boardType) {
      case Board.schieber:
        (settings as SchieberSettings).fromPreferences(preferences);
        (settings as SchieberSettings).toPreferences(preferences);
        break;
      case Board.coiffeur:
        (settings as CoiffeurSettings).fromPreferences(preferences);
        (settings as CoiffeurSettings).toPreferences(preferences);
        break;
      case Board.molotow:
        (settings as MolotowSettings).fromPreferences(preferences);
        (settings as MolotowSettings).toPreferences(preferences);
        break;
      case Board.pointBoard:
        (settings as PointBoardSettings).fromPreferences(preferences);
        (settings as PointBoardSettings).toPreferences(preferences);
        break;
      case Board.differenzler:
        (settings as DifferenzlerSettings).fromPreferences(preferences);
        (settings as DifferenzlerSettings).toPreferences(preferences);
        break;
      case Board.guggitaler:
        (settings as GuggitalerSettings).fromPreferences(preferences);
        (settings as GuggitalerSettings).toPreferences(preferences);
        break;
      case Board.schlaeger:
        (settings as SchlaegerSettings).fromPreferences(preferences);
        (settings as SchlaegerSettings).toPreferences(preferences);
        break;
    }
    _updateSettings();

    profiles.active = preferences.getString(activeProfileKey) ?? "Standard";
    profiles.list = preferences.getStringList(profilesKey) ?? ["Standard:{}"];

    final str = preferences.getString(dataKey) ?? "{}";
    if (str.length > 2) {
      fromJson(jsonDecode(str));
    }
    onLoaded?.call(this);
    return this;
  }

  void save({bool broadcast = true}) async {
    var json = score.toJson();
    json['common'] = common.toJson();
    final str = jsonEncode(json);
    // Before awaiting anything, to share it before reacting to others.
    if (broadcast) {
      onSaveBroadcast?.call(this, str);
    }
    switch (boardType) {
      case Board.schieber:
        (settings as SchieberSettings).data = str;
        break;
      case Board.coiffeur:
        (settings as CoiffeurSettings).data = str;
        break;
      case Board.molotow:
        (settings as MolotowSettings).data = str;
        break;
      case Board.pointBoard:
        (settings as PointBoardSettings).data = str;
        break;
      case Board.differenzler:
        (settings as DifferenzlerSettings).data = str;
        break;
      case Board.guggitaler:
        (settings as GuggitalerSettings).data = str;
        break;
      case Board.schlaeger:
        (settings as SchlaegerSettings).data = str;
        break;
    }
    _updateSettings();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(dataKey, str);
  }

  /// The current score and shared state serialized as JSON, matching the
  /// format persisted by [save] and consumed by [applyRemote].
  String currentJson() {
    var json = score.toJson();
    json['common'] = common.toJson();
    return jsonEncode(json);
  }

  /// The settings of [board] that only change how it looks or behaves on a
  /// device, so they stay local when the board is shared. Marked `local` in
  /// the settings YAML.
  static Set<String> localSettingsOf(Board board) => switch (board) {
    Board.schieber => SchieberSettings.local,
    Board.coiffeur => CoiffeurSettings.local,
    Board.molotow => MolotowSettings.local,
    Board.pointBoard => PointBoardSettings.local,
    Board.differenzler => DifferenzlerSettings.local,
    Board.guggitaler => GuggitalerSettings.local,
    Board.schlaeger => SchlaegerSettings.local,
  };

  /// The settings synced devices share, such as the goal and the players,
  /// keyed like the preferences.
  Map<String, dynamic> sharedSettings() {
    final local = localSettingsOf(boardType);
    final json = settings.toJson();
    json.remove(dataKey);
    json.removeWhere((key, _) => local.contains(key));
    return json;
  }

  /// The preferences key [board] stores its score under.
  static String dataKeyOf(Board board) => switch (board) {
    Board.schieber => SchieberSettingsKeys().data,
    Board.coiffeur => CoiffeurSettingsKeys().data,
    Board.molotow => MolotowSettingsKeys().data,
    Board.pointBoard => PointBoardSettingsKeys().data,
    Board.differenzler => DifferenzlerSettingsKeys().data,
    Board.guggitaler => GuggitalerSettingsKeys().data,
    Board.schlaeger => SchlaegerSettingsKeys().data,
  };

  /// The settings of [board] with their defaults, keyed like the preferences.
  static Map<String, Object> defaultSettings(Board board) => switch (board) {
    Board.schieber => SchieberSettings.defaults,
    Board.coiffeur => CoiffeurSettings.defaults,
    Board.molotow => MolotowSettings.defaults,
    Board.pointBoard => PointBoardSettings.defaults,
    Board.differenzler => DifferenzlerSettings.defaults,
    Board.guggitaler => GuggitalerSettings.defaults,
    Board.schlaeger => SchlaegerSettings.defaults,
  };

  /// The entries of [shared] that are settings of [board] another device may
  /// set: known keys with values of the right type, neither the score nor a
  /// local setting. Anything else came from a broken or foreign device.
  static Map<String, Object> acceptedSettings(
    Board board,
    Map<String, dynamic> shared,
  ) {
    final defaults = defaultSettings(board);
    final dataKey = dataKeyOf(board);
    final local = localSettingsOf(board);
    return {
      for (final MapEntry(:key, :value) in shared.entries)
        if (value != null &&
            defaults[key]?.runtimeType == value.runtimeType &&
            key != dataKey &&
            !local.contains(key))
          key: value as Object,
    };
  }

  /// Stores the [shared] settings received for [board] while it isn't open,
  /// for it to load them.
  static Future<void> storeSharedSettings(
    Board board,
    Map<String, dynamic> shared,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    for (final MapEntry(:key, :value) in acceptedSettings(
      board,
      shared,
    ).entries) {
      switch (value) {
        case bool value:
          await preferences.setBool(key, value);
        case int value:
          await preferences.setInt(key, value);
        case double value:
          await preferences.setDouble(key, value);
        case String value:
          await preferences.setString(key, value);
      }
    }
  }

  /// Applies board state and [shared] settings received from a synced device
  /// and persists them locally without re-broadcasting them (which would loop
  /// back to the sender).
  void applyRemote(String jsonStr, Map<String, dynamic> shared) {
    final accepted = acceptedSettings(boardType, shared);
    final json = settings.toJson();
    json.addAll(accepted);
    settings.fromJson(json);
    storeSharedSettings(boardType, accepted);
    _updateSettings();
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    // A profile carries settings under the data key, the score doesn't.
    data.remove(dataKey);
    fromJson(data);
    save(broadcast: false);
  }

  void reset() {
    score.reset(common.timestamps.duration());
    common.reset();
    save();
  }

  void checkGameOver(BuildContext context, {required GoalType goalType}) {
    final winners = score.winner();
    if (winners.isNotEmpty && common.timestamps.justFinished()) {
      Future.delayed(Duration.zero, () {
        if (context.mounted) {
          winnerDialog(
            context: context,
            winners: winners,
            losers: score.loser(),
            setWinnerFunction: score.setWinner,
            goalType: goalType,
          );
        }
      });
    }
  }

  void saveProfiles() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(activeProfileKey, profiles.active);
    await preferences.setStringList(profilesKey, profiles.list);
  }

  void fromJson(Map<String, dynamic> json) async {
    if (json.containsKey(dataKey)) {
      // restore profile
      final preferences = await SharedPreferences.getInstance();
      migrateRoundedJson(json);
      switch (boardType) {
        case Board.schieber:
          var schieberSettings = settings as SchieberSettings;
          schieberSettings.fromJson(json);
          schieberSettings.toPreferences(preferences);
          break;
        case Board.coiffeur:
          var coiffeurSettings = settings as CoiffeurSettings;
          coiffeurSettings.fromJson(json);
          coiffeurSettings.toPreferences(preferences);
          break;
        case Board.molotow:
          var molotowSettings = settings as MolotowSettings;
          molotowSettings.fromJson(json);
          molotowSettings.toPreferences(preferences);
          break;
        case Board.pointBoard:
          var pointBoardSettings = settings as PointBoardSettings;
          pointBoardSettings.fromJson(json);
          pointBoardSettings.toPreferences(preferences);
          break;
        case Board.differenzler:
          var differenzlerSettings = settings as DifferenzlerSettings;
          differenzlerSettings.fromJson(json);
          differenzlerSettings.toPreferences(preferences);
          break;
        case Board.guggitaler:
          var guggitalerSettings = settings as GuggitalerSettings;
          guggitalerSettings.fromJson(json);
          guggitalerSettings.toPreferences(preferences);
          break;
        case Board.schlaeger:
          var schlaegerSettings = settings as SchlaegerSettings;
          schlaegerSettings.fromJson(json);
          schlaegerSettings.toPreferences(preferences);
          break;
      }
      _updateSettings();
      json = jsonDecode(json[dataKey]);
    }

    if (json.containsKey('common')) {
      common = CommonData.fromJson(json['common']);
      json.remove('common');
    }
    switch (boardType) {
      case Board.schieber:
        score = SchieberScore.fromJson(json) as S;
        break;
      case Board.coiffeur:
        score = CoiffeurScore.fromJson(json) as S;
        break;
      case Board.molotow:
        score = MolotowScore.fromJson(json) as S;
        break;
      case Board.pointBoard:
        score = PointBoardScore.fromJson(json) as S;
        break;
      case Board.differenzler:
        score = DifferenzlerScore.fromJson(json) as S;
        break;
      case Board.guggitaler:
        score = GuggitalerScore.fromJson(json) as S;
        break;
      case Board.schlaeger:
        score = SchlaegerScore.fromJson(json) as S;
        break;
    }
    _updateSettings();
  }
}
