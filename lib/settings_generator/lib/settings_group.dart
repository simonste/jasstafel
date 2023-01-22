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

    var toPreferences = "";
    for (Setting setting in _settings) {
      toPreferences += setting.toPreferences();
    }

    var fromPreferences = "";
    for (Setting setting in _settings) {
      fromPreferences += setting.fromPreferences();
    }

    var toJson = "return <String, dynamic>{";
    for (int i = 0; i < _settings.length; i++) {
      toJson += _settings[i].toJson();
    }
    toJson += "};";

    var fromJson = "";
    for (int i = 0; i < _settings.length; i++) {
      fromJson += _settings[i].fromJson();
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
      Method.returnsVoid((b) => b
        ..name = 'toPreferences'
        ..requiredParameters.add(Parameter((b) => b
          ..name = 'preferences'
          ..type = refer('SharedPreferences')))
        ..body = Code(toPreferences)),
      Method.returnsVoid((b) => b
        ..name = 'fromPreferences'
        ..requiredParameters.add(Parameter((b) => b
          ..name = 'preferences'
          ..type = refer('SharedPreferences')))
        ..body = Code(fromPreferences)),
      Method((b) => b
        ..name = 'toJson'
        ..returns = refer('Map<String, dynamic>')
        ..body = Code(toJson)),
      Method.returnsVoid((b) => b
        ..name = 'fromJson'
        ..requiredParameters.add(Parameter((b) => b
          ..name = 'json'
          ..type = refer('Map<String, dynamic>')))
        ..body = Code(fromJson)),
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
