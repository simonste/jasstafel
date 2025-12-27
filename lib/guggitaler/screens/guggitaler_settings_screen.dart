import 'package:flutter/material.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/common/widgets/profile_button.dart';
import 'package:jasstafel/common/widgets/profile_page.dart';
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:jasstafel/settings/guggitaler_settings.g.dart';
import 'package:pref/pref.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:restart_app/restart_app.dart';

class GuggitalerSettingsScreen extends StatefulWidget {
  final BoardData boardData;

  const GuggitalerSettingsScreen(this.boardData, {super.key});

  @override
  State<GuggitalerSettingsScreen> createState() =>
      _GuggitalerSettingsScreenState();
}

class _GuggitalerSettingsScreenState extends State<GuggitalerSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsTitle(context.l10n.guggitaler)),
      ),
      body: PrefPage(
        children: [
          PrefTitle(title: Text(context.l10n.profiles)),
          ProfileButton(
            pageTitle: Text(context.l10n.selectProfile),
            title: Text(widget.boardData.profiles.active),
            page: ProfilePage(widget.boardData, () => setState(() {})),
          ),
          PrefTitle(title: Text(context.l10n.settings)),
          PrefSlider(
            title: Text(context.l10n.diffPlayers),
            pref: GuggitalerSettings.keys.players,
            min: Players.min,
            max: Players.max,
            trailing: (num v) => Text('$v'),
          ),
          PrefTitle(title: Text(context.l10n.commonSettings)),
          PrefCheckbox(
            title: Text(context.l10n.keepScreenOn),
            pref: CommonSettings.keys.keepScreenOn,
          ),
          PrefChoice<int>(
            title: Text(context.l10n.screenOrientation),
            pref: CommonSettings.keys.screenOrientation,
            items: [
              DropdownMenuItem(value: 0, child: Text(context.l10n.sensor)),
              DropdownMenuItem(value: 1, child: Text(context.l10n.portrait)),
              DropdownMenuItem(value: 2, child: Text(context.l10n.landscape)),
            ],
            cancel: Text(context.l10n.cancel),
          ),
          PrefChoice<String>(
            title: Text(context.l10n.language),
            pref: CommonSettings.keys.appLanguage,
            items: const [
              DropdownMenuItem(value: 'de', child: Text('Deutsch')),
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'fr', child: Text('Français')),
            ],
            onChange: (value) => Restart.restartApp(),
            cancel: Text(context.l10n.cancel),
          ),
        ],
      ),
    );
  }
}
