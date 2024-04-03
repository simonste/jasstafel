import 'dart:async';

import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:jasstafel/settings_generator/lib/settings_group.dart';
import 'package:yaml/yaml.dart';

// inspired by https://github.com/natebosch/message_builder

Builder generateSettings(_) => const GenerateSettings();

class GenerateSettings implements Builder {
  const GenerateSettings();

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final settingsYaml =
        loadYaml(await buildStep.readAsString(buildStep.inputId)) as Map;

    assert(settingsYaml.keys.length == 1);

    var name = settingsYaml.keys.first;
    final settings = SettingsGroup.parse(name, settingsYaml[name] as Map);

    var library = Library((b) {
      b.directives.addAll([
        Directive.import('package:flutter/widgets.dart'),
        Directive.import('package:pref/pref.dart'),
        Directive.import('package:shared_preferences/shared_preferences.dart')
      ]);
      b.body.addAll(settings.create());
    });

    final emitter = DartEmitter.scoped();
    await buildStep.writeAsString(buildStep.inputId.changeExtension('.g.dart'),
        DartFormatter().format('${library.accept(emitter)}'));
  }

  @override
  final buildExtensions = const {
    '.yaml': ['.g.dart']
  };
}
