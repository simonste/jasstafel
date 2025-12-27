import 'package:code_builder/code_builder.dart';
import 'package:yaml/yaml.dart';

class Setting {
  final String _name;
  final String _prefName;
  final dynamic _defaultValue;

  Setting(name, this._prefName, this._defaultValue)
    : _name = name.replaceRange(0, 1, name[0].toLowerCase()) {
    if (!name[0].contains(RegExp(r'[A-Z]'))) {
      throw ArgumentError(
        "setting $_name has to begin with an upper case letter",
      );
    }
  }

  Method getterMethod() {
    return Method(
      (b) => b
        ..name = _name
        ..body = Code("'$_prefName'")
        ..type = MethodType.getter
        ..lambda = true
        ..returns = refer('String'),
    );
  }

  String _assignment() {
    if (_defaultValue is String) {
      return "'$_defaultValue'";
    } else if (_defaultValue is YamlList) {
      var defaultList = (_defaultValue as YamlList)
          .map((element) => "\"$element\"")
          .toList();
      return "$defaultList";
    }
    return '$_defaultValue';
  }

  Field field() {
    return Field(
      (b) => b
        ..name = _name
        ..assignment = Code(_assignment()),
    );
  }

  String defaults() {
    return "'$_prefName': ${_assignment()},";
  }

  String toPref() {
    return "pref.set('$_prefName', $_name);";
  }

  String fromPref() {
    return "$_name = pref.get('$_prefName') ?? $_name;";
  }

  String toPreferences() {
    if (_defaultValue is bool) {
      return "preferences.setBool('$_prefName', $_name);";
    } else if (_defaultValue is int) {
      return "preferences.setInt('$_prefName', $_name);";
    } else if (_defaultValue is double) {
      return "preferences.setDouble('$_prefName', $_name);";
    } else if (_defaultValue is String) {
      return "preferences.setString('$_prefName', $_name);";
    } else if (_defaultValue is YamlList) {
      return "preferences.setStringList('$_prefName', $_name);";
    }
    return '$_defaultValue';
  }

  String fromPreferences() {
    if (_defaultValue is bool) {
      return "$_name = preferences.getBool('$_prefName') ?? $_name;";
    } else if (_defaultValue is int) {
      return "$_name = preferences.getInt('$_prefName') ?? $_name;";
    } else if (_defaultValue is double) {
      return "$_name = preferences.getDouble('$_prefName') ?? $_name;";
    } else if (_defaultValue is String) {
      return "$_name = preferences.getString('$_prefName') ?? $_name;";
    } else if (_defaultValue is YamlList) {
      return "$_name = preferences.getStringList('$_prefName') ?? $_name;";
    }
    return '$_defaultValue';
  }

  String toJson() {
    return "'$_prefName': $_name,";
  }

  String fromJson() {
    return "$_name = json['$_prefName'] ?? ${_assignment()};";
  }
}
