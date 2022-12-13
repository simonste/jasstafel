import 'package:code_builder/code_builder.dart';
import 'package:jasstafel/settings_generator/lib/setting.dart';

class SettingsGroup {
  String _groupName;
  var _settings = [];

  SettingsGroup(this._groupName, this._settings);

  factory SettingsGroup.parse(String name, map) {
    var settings = <Setting>[];
    for (var key in map.keys) {
      var setting = map[key] as Map;
      settings.add(Setting(key, setting['store'], setting['default']));
    }
    return SettingsGroup(name, settings);
  }

  Iterable<Spec> create() {
    var fields = [
      Field((b) => b
        ..name = 'keys'
        ..static = true
        ..type = refer('${_groupName}Keys')
        ..assignment = Code('${_groupName}Keys()'))
    ];

    for (Setting setting in _settings) {
      fields.add(setting.field());
    }

    var toPref = "var pref = PrefService.of(context);\n";
    for (Setting setting in _settings) {
      toPref += setting.toPref();
    }
    var fromPref = "var pref = PrefService.of(context);\n";
    for (Setting setting in _settings) {
      fromPref += setting.fromPref();
    }
    var toString = "return '";
    for (int i = 0; i < _settings.length; i++) {
      toString += "${_settings[i]},";
    }
    toString = "${toString.substring(0, toString.length - 1)}';";
    var fromString = "var values = str.split(',');\n";
    for (int i = 0; i < _settings.length; i++) {
      fromString += _settings[i].fromString("values[$i]");
    }

    var methods = [
      Method.returnsVoid((b) => b
        ..name = 'toPrefService'
        ..requiredParameters.add(Parameter((b) => b
          ..name = 'context'
          ..type = refer('BuildContext')))
        ..body = Code(toPref)),
      Method.returnsVoid((b) => b
        ..name = 'fromPrefService'
        ..requiredParameters.add(Parameter((b) => b
          ..name = 'context'
          ..type = refer('BuildContext')))
        ..body = Code(fromPref)),
      Method((b) => b
        ..name = 'toString'
        ..annotations.add(refer('override'))
        ..returns = refer('String')
        ..body = Code(toString)),
      Method.returnsVoid((b) => b
        ..name = 'fromString'
        ..requiredParameters.add(Parameter((b) => b
          ..name = 'str'
          ..type = refer('String')))
        ..body = Code(fromString)),
    ];

    String def = "";
    for (Setting setting in _settings) {
      def += setting.defaults();
    }
    methods.add(Method((b) => b
      ..type = MethodType.getter
      ..name = 'defaults'
      ..static = true
      ..body = Code('return {$def};')));

    var getters = <Method>[];
    for (Setting setting in _settings) {
      getters.add(setting.getterMethod());
    }

    return [
      Class((b) => b
        ..name = "${_groupName}Keys"
        ..methods.addAll(getters)),
      Class((b) => b
        ..name = _groupName
        ..fields.addAll(fields)
        ..methods.addAll(methods))
    ];
  }
}
