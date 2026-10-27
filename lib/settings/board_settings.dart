import 'package:shared_preferences/shared_preferences.dart';

/// What every generated settings class offers, so a board can be handled
/// without knowing which settings it has.
abstract interface class BoardSettings {
  /// Whether the board has a goal to reach, so that a game can finish rather
  /// than only be reset.
  bool get hasGoal;

  void toPreferences(SharedPreferences preferences);
  void fromPreferences(SharedPreferences preferences);
  Map<String, dynamic> toJson();
  void fromJson(Map<String, dynamic> json);
}
