import 'package:code_builder/code_builder.dart';

class Setting {
  final String _name;
  final String _prefName;
  final dynamic _defaultValue;

  Setting(name, this._prefName, this._defaultValue)
      : _name = name.replaceRange(0, 1, name[0].toLowerCase()) {
    if (!name[0].contains(RegExp(r'[A-Z]'))) {
      throw ArgumentError(
          "setting $_name has to begin with an upper case letter");
    }
  }

  Method getterMethod() {
    return Method((b) => b
      ..name = _name
      ..body = Code("'$_prefName'")
      ..type = MethodType.getter
      ..lambda = true
      ..returns = refer('String'));
  }

  String _assignment() {
    if (_defaultValue is String) {
      return "'$_defaultValue'";
    }
    return '$_defaultValue';
  }

  Field field() {
    return Field((b) => b
      ..name = _name
      ..assignment = Code(_assignment()));
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

  @override
  String toString() {
    return "\$$_name";
  }

  String fromString(String value) {
    if (_defaultValue is int) {
      return "try{ $_name = int.parse($value); } catch (e) { $_name = $_defaultValue; }";
    } else if (_defaultValue is bool) {
      return "try{ $_name = ($value == 'true'); } catch (e) { $_name = $_defaultValue; }";
    } else if (_defaultValue is String) {
      return "try{ $_name = $value; } catch (e) { $_name = '$_defaultValue'; }";
    } else {
      throw ArgumentError("unhandled type of $_name (${_name.runtimeType})");
    }
  }
}
