import 'dart:math';

import 'package:jasstafel/common/localization.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
part 'common_data.g.dart';

var clockSpeed = 1;

extension JassDurationHelper on Duration {
  int get elapsed {
    return (inMilliseconds / 1000 / 60 * clockSpeed).floor();
  }
}

@JsonSerializable()
class Timestamps {
  DateTime? startTime;
  DateTime? finishTime;

  /// When the board last changed, on whichever device: the devices sharing
  /// a board take it along with the change, so the history on each of them
  /// knows the same revision of the game, see `GameRecord.changed`.
  DateTime? changeTime;

  /// Stamps a change made here. Later than the last one even on a device
  /// whose clock is behind the one that made it, so that a change is always
  /// a later revision than the state it was made from.
  void changed() {
    final now = DateTime.now();
    final last = changeTime;
    changeTime = last != null && !now.isAfter(last)
        ? last.add(const Duration(milliseconds: 1))
        : now;
  }

  Timestamps();

  factory Timestamps.fromJson(Map<String, dynamic> json) =>
      _$TimestampsFromJson(json);

  Map<String, dynamic> toJson() => _$TimestampsToJson(this);

  void reset() {
    startTime = DateTime.now();
    finishTime = null;
  }

  int? duration() => startTime == null
      ? null
      : playedMinutes(startTime!, finishTime ?? DateTime.now());

  /// The minutes played from [start] to [end], or null for a game too long
  /// to have been played in one go, such as one left open. A start ahead of
  /// [end], as set by a synced device whose clock runs ahead, counts as none.
  static int? playedMinutes(DateTime start, DateTime end) {
    final minutes = max(0, end.difference(start).elapsed);
    return minutes < 300 ? minutes : null;
  }

  String elapsed(BuildContext context) {
    var dur = duration();
    if (dur != null) {
      return context.l10n.duration(dur);
    }
    return "";
  }

  /// The first points start the clock, unless the board was reset just
  /// before: the time a board waited after a reset isn't played.
  void addPoints(int totalPts) {
    if (totalPts == 0 &&
        (startTime == null ||
            DateTime.now().difference(startTime!).elapsed >= 10)) {
      reset();
    } else if (finishTime != null) {
      finishTime = DateTime.now();
    }
  }

  bool justFinished() {
    if (finishTime == null) {
      finishTime = DateTime.now();
      return true;
    }
    return false;
  }
}

@JsonSerializable()
class WhoIsNext {
  String swapPlayers = "";
  int? whoBeginsOffset;

  WhoIsNext();

  factory WhoIsNext.fromJson(Map<String, dynamic> json) =>
      _$WhoIsNextFromJson(json);

  Map<String, dynamic> toJson() => _$WhoIsNextToJson(this);
}

String newGameId() {
  final random = Random.secure();
  return List.generate(12, (_) => random.nextInt(36).toRadixString(36)).join();
}

@JsonSerializable()
class CommonData {
  /// Tells games apart, for synced devices and a later history to know they
  /// have the same game. A new game gets a new id.
  @JsonKey(readValue: _readGameId)
  String gameId = newGameId();
  Timestamps timestamps = Timestamps();
  WhoIsNext whoIsNext = WhoIsNext();

  CommonData();

  factory CommonData.fromJson(Map<String, dynamic> json) =>
      _$CommonDataFromJson(json);

  Map<String, dynamic> toJson() => _$CommonDataToJson(this);

  // A game saved before games had ids gets one.
  static Object? _readGameId(Map<dynamic, dynamic> json, String key) =>
      json[key] ?? newGameId();

  void reset() {
    gameId = newGameId();
    timestamps.reset();
    whoIsNext.whoBeginsOffset = null;
  }
}
