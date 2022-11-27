class CommonData {
  DateTime? startTime;
  DateTime? finishTime;

  String duration() {
    int minutes = 30;
    if (startTime != null) {
      if (finishTime != null) {
        minutes = startTime!.difference(finishTime!).inMinutes;
      } else {
        minutes = startTime!.difference(DateTime.now()).inMinutes;
      }
    }

    if (minutes < 300) {
      return "$minutes min";
    }
    return "";
  }

  @override
  String toString() {
    return "$startTime,$finishTime;";
  }

  void fromString(String str) {
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
