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
      settings.add(
        Setting(
          key,
          setting['store'],
          setting['default'],
          local: setting['local'],
        ),
      );
    }
    return SettingsGroup(name, settings);
  }

  Iterable<Spec> create() {
    var fields = [
      Field(
        (b) => b
          ..name = 'keys'
          ..static = true
          ..type = refer('${_groupName}Keys')
          ..assignment = Code('${_groupName}Keys()'),
      ),
    ];

    for (Setting setting in _settings) {
      fields.add(setting.field());
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
      Method.returnsVoid(
        (b) => b
          ..name = 'toPreferences'
          ..annotations.add(refer('override'))
          ..requiredParameters.add(
            Parameter(
              (b) => b
                ..name = 'preferences'
                ..type = refer('SharedPreferences'),
            ),
          )
          ..body = Code(toPreferences),
      ),
      Method.returnsVoid(
        (b) => b
          ..name = 'fromPreferences'
          ..annotations.add(refer('override'))
          ..requiredParameters.add(
            Parameter(
              (b) => b
                ..name = 'preferences'
                ..type = refer('SharedPreferences'),
            ),
          )
          ..body = Code(fromPreferences),
      ),
      Method(
        (b) => b
          ..name = 'toJson'
          ..annotations.add(refer('override'))
          ..returns = refer('Map<String, dynamic>')
          ..body = Code(toJson),
      ),
      Method.returnsVoid(
        (b) => b
          ..name = 'fromJson'
          ..annotations.add(refer('override'))
          ..requiredParameters.add(
            Parameter(
              (b) => b
                ..name = 'json'
                ..type = refer('Map<String, dynamic>'),
            ),
          )
          ..body = Code(fromJson),
      ),
    ];

    String def = "";
    for (Setting setting in _settings) {
      def += setting.defaults();
    }
    methods.add(
      Method(
        (b) => b
          ..type = MethodType.getter
          ..name = 'defaults'
          ..static = true
          ..returns = refer('Map<String, Object>')
          ..body = Code('return {$def};'),
      ),
    );

    final local = _settings
        .where((setting) => setting.local)
        .map((setting) => setting.prefName())
        .join(',');
    methods.add(
      Method(
        (b) => b
          ..type = MethodType.getter
          ..name = 'local'
          ..static = true
          ..returns = refer('Set<String>')
          ..docs.add(
            '/// The settings that stay local when the board is shared.',
          )
          ..body = Code('return {$local};'),
      ),
    );

    var getters = <Method>[];
    for (Setting setting in _settings) {
      getters.add(setting.getterMethod());
    }

    return [
      Class(
        (b) => b
          ..name = "${_groupName}Keys"
          ..methods.addAll(getters),
      ),
      Class(
        (b) => b
          ..name = _groupName
          ..implements.add(refer('BoardSettings'))
          ..fields.addAll(fields)
          ..methods.addAll(methods),
      ),
    ];
  }
}
