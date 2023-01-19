import 'package:jasstafel/common/localization.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
part 'common_data.g.dart';

@JsonSerializable()
class Timestamps {
  DateTime? startTime;
  DateTime? finishTime;

  Timestamps();

  factory Timestamps.fromJson(Map<String, dynamic> json) =>
      _$TimestampsFromJson(json);

  Map<String, dynamic> toJson() => _$TimestampsToJson(this);

  int? duration() {
    int minutes = 1000;
    if (startTime != null) {
      if (finishTime != null) {
        minutes = finishTime!.difference(startTime!).inMinutes;
      } else {
        minutes = DateTime.now().difference(startTime!).inMinutes;
      }
    }

    if (minutes < 300) {
      return minutes;
    }
    return null;
  }

  String elapsed(BuildContext context) {
    var dur = duration();
    if (dur != null) {
      return context.l10n.duration(dur);
    }
    return "";
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

@JsonSerializable()
class CommonData {
  Timestamps timestamps = Timestamps();
  WhoIsNext whoIsNext = WhoIsNext();

  CommonData();

  factory CommonData.fromJson(Map<String, dynamic> json) =>
      _$CommonDataFromJson(json);

  Map<String, dynamic> toJson() => _$CommonDataToJson(this);

  void reset() {
    timestamps.startTime = DateTime.now();
    timestamps.finishTime = null;
    whoIsNext.whoBeginsOffset = null;
  }

  void firstPoints() {
    if (timestamps.startTime == null ||
        DateTime.now().difference(timestamps.startTime!).inMinutes < 10) {
      reset();
    }
  }

  List<dynamic> dump() {
    return [
      timestamps.startTime,
      timestamps.finishTime,
      whoIsNext.swapPlayers,
      whoIsNext.whoBeginsOffset
    ];
  }

  void restore(List<String> values) {
    try {
      timestamps.startTime = DateTime.parse(values[0]);
    } on FormatException {
      timestamps.startTime = null;
    }
    try {
      timestamps.finishTime = DateTime.parse(values[1]);
    } on FormatException {
      timestamps.finishTime = null;
    }
    whoIsNext.swapPlayers = values[2];
    try {
      whoIsNext.whoBeginsOffset = int.parse(values[3]);
    } on FormatException {
      whoIsNext.whoBeginsOffset = null;
    }
  }
}
