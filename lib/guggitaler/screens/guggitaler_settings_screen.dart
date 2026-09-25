import 'package:flutter/material.dart';
import 'package:jasstafel/common/widgets/settings_screen_helpers.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/widgets/profile_button.dart';
import 'package:jasstafel/common/widgets/profile_page.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:jasstafel/guggitaler/data/guggitaler_score.dart';
import 'package:jasstafel/settings/guggitaler_settings.g.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/common/widgets/settings_provider.dart';

class GuggitalerSettingsScreen extends StatefulWidget {
  final BoardData<GuggitalerSettings, GuggitalerScore> boardData;

  const GuggitalerSettingsScreen(this.boardData, {super.key});

  @override
  State<GuggitalerSettingsScreen> createState() =>
      _GuggitalerSettingsScreenState();
}

class _GuggitalerSettingsScreenState extends State<GuggitalerSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = widget.boardData.settings;
    final commonSettings = CommonSettings();
    final preferences = SettingsProvider.of(context);
    commonSettings.fromPreferences(preferences);

    String? dominoValidator(String? value, int players) {
      if (value == null || value.split(',').length != players) {
        return context.l10n.dominoPointsInfo(players);
      }
      for (var part in value.split(',')) {
        final parsed = int.tryParse(part.trim());
        if (parsed == null || parsed % 5 != 0) {
          return context.l10n.dominoPointsInfo(players);
        }
      }
      return null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsTitle(context.l10n.guggitaler)),
      ),
      body: ListView(
        children: [
          sectionTitle(context, context.l10n.profiles),
          ProfileButton(
            pageTitle: Text(context.l10n.selectProfile),
            title: Text(widget.boardData.profiles.active),
            page: ProfilePage(widget.boardData, () => setState(() {})),
          ),
          const Divider(),

          sectionTitle(context, context.l10n.settings),
          buildSliderTile(
            context,
            title: context.l10n.diffPlayers,
            value: settings.players,
            min: Players.min,
            max: Players.max,
            onChanged: (value) {
              setState(() {
                settings.players = value;
                settings.toPreferences(preferences);
              });
            },
            displayValue: (v) => Text('$v'),
          ),
          buildCheckboxTile(
            context,
            title: context.l10n.domino,
            value: settings.domino,
            onChanged: (value) {
              setState(() {
                settings.domino = value!;
                settings.toPreferences(preferences);
              });
            },
          ),
          // Enable the domino text fields only if domino is enabled
          buildTextFieldTile(
            context,
            label: context.l10n.domino3player,
            value: settings.domino3,
            validator: (value) => dominoValidator(value, 3),
            onChanged: settings.domino
                ? (value) {
                    setState(() {
                      settings.domino3 = value;
                      settings.toPreferences(preferences);
                    });
                  }
                : null,
          ),
          buildTextFieldTile(
            context,
            label: context.l10n.domino4player,
            value: settings.domino4,
            validator: (value) => dominoValidator(value, 4),
            onChanged: settings.domino
                ? (value) {
                    setState(() {
                      settings.domino4 = value;
                      settings.toPreferences(preferences);
                    });
                  }
                : null,
          ),
          const Divider(),

          sectionTitle(context, context.l10n.commonSettings),
          buildCheckboxTile(
            context,
            title: context.l10n.keepScreenOn,
            value: commonSettings.keepScreenOn,
            onChanged: (value) {
              setState(() {
                commonSettings.keepScreenOn = value!;
                commonSettings.toPreferences(preferences);
              });
            },
          ),
          buildDropdownTile(
            context,
            title: context.l10n.screenOrientation,
            value: commonSettings.screenOrientation,
            items: [
              DropdownMenuItem(value: 0, child: Text(context.l10n.sensor)),
              DropdownMenuItem(value: 1, child: Text(context.l10n.portrait)),
              DropdownMenuItem(value: 2, child: Text(context.l10n.landscape)),
            ],
            onChanged: (value) {
              setState(() {
                commonSettings.screenOrientation = value!;
                commonSettings.toPreferences(preferences);
              });
            },
          ),
          buildDropdownTile(
            context,
            title: context.l10n.theme,
            value: commonSettings.themeMode,
            items: [
              DropdownMenuItem(value: 0, child: Text(context.l10n.system)),
              DropdownMenuItem(value: 1, child: Text(context.l10n.light)),
              DropdownMenuItem(value: 2, child: Text(context.l10n.dark)),
            ],
            onChanged: (value) {
              setState(() {
                commonSettings.themeMode = value!;
                commonSettings.toPreferences(preferences);
              });
            },
          ),
          buildDropdownTile(
            context,
            title: context.l10n.language,
            value: commonSettings.appLanguage,
            items: const [
              DropdownMenuItem(value: 'de', child: Text('Deutsch')),
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'fr', child: Text('Fran\u00e7ais')),
            ],
            onChanged: (value) {
              setState(() {
                commonSettings.appLanguage = value!;
                commonSettings.toPreferences(preferences);
              });
            },
          ),
        ],
      ),
    );
  }
}
