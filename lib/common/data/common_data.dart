class Timestamps {
  DateTime? startTime;
  DateTime? finishTime;

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
}

class WhoIsNext {
  String swapPlayers = "";
  int? whoBeginsOffset;
}

class CommonData {
  Timestamps timestamps = Timestamps();
  WhoIsNext whoIsNext = WhoIsNext();

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
