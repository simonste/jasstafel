import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jasstafel/coiffeur/data/coiffeur_score.dart';
import 'package:jasstafel/common/board.dart';
import 'package:jasstafel/common/data/common_data.dart';
import 'package:jasstafel/common/data/profile_data.dart';
import 'package:jasstafel/common/dialog/winner_dialog.dart';
import 'package:jasstafel/molotow/data/molotow_score.dart';
import 'package:jasstafel/schieber/data/schieber_score.dart';
import 'package:jasstafel/settings/coiffeur_settings.g.dart';
import 'package:jasstafel/settings/molotow_settings.g.dart';
import 'package:jasstafel/settings/schieber_settings.g.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

abstract class Score {
  Map<String, dynamic> toJson();

  void reset(int? duration);
  int noOfRounds();
  int totalPoints();

  List<String> winner();
  void setWinner(String team);
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
    }
  }

  Future<BoardData> load() async {
    final preferences = await SharedPreferences.getInstance();

    try {
      var hasVibrator = await Vibration.hasVibrator() ?? false;
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

  void checkGameOver(BuildContext context) {
    final winners = score.winner();
    if (winners.isNotEmpty && common.timestamps.justFinished()) {
      Future.delayed(
          Duration.zero,
          () => winnerDialog(
              context: context,
              winners: winners,
              setWinnerFunction: score.setWinner));
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
    }
  }
}
