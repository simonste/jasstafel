import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jasstafel/coiffeur/data/coiffeur_score.dart';
import 'package:jasstafel/common/board.dart';
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

class BoardData<T, S extends Score> {
  final String dataKey;
  final String activeProfileKey;
  final String profilesKey;
  T settings;
  S score;
  var common = CommonData();
  ProfileData profiles = ProfileData("Standard", []);
  final Board boardType;
  bool supportsVibration = false;

  static Board determineBoardType(String string) {
    if (string == "SchieberScore") {
      return Board.schieber;
    } else if (string == "CoiffeurScore") {
      return Board.coiffeur;
    } else if (string == "MolotowScore") {
      return Board.molotow;
    } else if (string == "PointBoardScore") {
      return Board.pointBoard;
    } else if (string == "DifferenzlerScore") {
      return Board.differenzler;
    } else if (string == "GuggitalerScore") {
      return Board.guggitaler;
    } else if (string == "SchlaegerScore") {
      return Board.schlaeger;
    } else {
      assert(false);
    }
    return Board.schieber;
  }

  BoardData(this.settings, this.score, this.dataKey)
      : profilesKey = "${dataKey}_profiles",
        activeProfileKey = "${dataKey}_profile",
        boardType = determineBoardType(S.toString()) {
    _updateSettings();
  }

  void _updateSettings() {
    switch (boardType) {
      case Board.schieber:
        (score as SchieberScore).setSettings(settings);
        break;
      case Board.coiffeur:
        (score as CoiffeurScore).setSettings(settings);
        break;
      case Board.molotow:
        (score as MolotowScore).setSettings(settings);
        break;
      case Board.pointBoard:
        (score as PointBoardScore).setSettings(settings);
        break;
      case Board.differenzler:
        (score as DifferenzlerScore).setSettings(settings);
        break;
      case Board.guggitaler:
        (score as GuggitalerScore).setSettings(settings);
        break;
      case Board.schlaeger:
        (score as SchlaegerScore).setSettings(settings);
        break;
    }
  }

  Future<BoardData> load() async {
    final preferences = await SharedPreferences.getInstance();

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
    if (str.length <= 2) {
      return this;
    }
    Map<String, dynamic> json = jsonDecode(str);
    fromJson(json);
    return this;
  }

  void save() async {
    var json = score.toJson();
    json['common'] = common.toJson();
    final str = jsonEncode(json);
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

  void reset() {
    score.reset(common.timestamps.duration());
    common.reset();
    save();
  }

  void checkGameOver(BuildContext context, {required GoalType goalType}) {
    final winners = score.winner();
    if (winners.isNotEmpty && common.timestamps.justFinished()) {
      Future.delayed(
        Duration.zero,
        () {
          if (context.mounted) {
            winnerDialog(
                context: context,
                winners: winners,
                losers: score.loser(),
                setWinnerFunction: score.setWinner,
                goalType: goalType);
          }
        },
      );
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
