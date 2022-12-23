class CommonData {
  DateTime? startTime;
  DateTime? finishTime;

  int whoBeginsOffset = 0;

  void reset() {
    startTime = DateTime.now();
    finishTime = null;
  }

  void firstPoints() {
    if (startTime == null ||
        DateTime.now().difference(startTime!).inMinutes < 10) {
      reset();
    }
  }

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

  String dump() {
    return "$startTime,$finishTime;";
  }

  void restore(String str) {
    var values = str.split(',');

    try {
      startTime = DateTime.parse(values[0]);
    } on FormatException {
      startTime = null;
    }
    try {
      finishTime = DateTime.parse(values[1]);
    } on FormatException {
      finishTime = null;
    }
  }
}
