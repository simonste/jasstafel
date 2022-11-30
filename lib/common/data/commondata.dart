class CommonData {
  DateTime? startTime;
  DateTime? finishTime;

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
