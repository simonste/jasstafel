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

  Timestamps();

  factory Timestamps.fromJson(Map<String, dynamic> json) =>
      _$TimestampsFromJson(json);

  Map<String, dynamic> toJson() => _$TimestampsToJson(this);

  void reset() {
    startTime = DateTime.now();
    finishTime = null;
  }

  int? duration() {
    int minutes = 1000;
    if (startTime != null) {
      if (finishTime != null) {
        minutes = finishTime!.difference(startTime!).elapsed;
      } else {
        minutes = DateTime.now().difference(startTime!).elapsed;
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

  void addPoints(int totalPts) {
    if (totalPts == 0 &&
        (startTime == null ||
            DateTime.now().difference(startTime!).elapsed < 10)) {
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

@JsonSerializable()
class CommonData {
  Timestamps timestamps = Timestamps();
  WhoIsNext whoIsNext = WhoIsNext();

  CommonData();

  factory CommonData.fromJson(Map<String, dynamic> json) =>
      _$CommonDataFromJson(json);

  Map<String, dynamic> toJson() => _$CommonDataToJson(this);

  void reset() {
    timestamps.reset();
    whoIsNext.whoBeginsOffset = null;
  }
}
