import 'package:flutter/material.dart';
import 'package:jasstafel/common/widgets/settings_screen_helpers.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/common/widgets/pref_number.dart';
import 'package:jasstafel/common/widgets/profile_button.dart';
import 'package:jasstafel/common/widgets/profile_page.dart';
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:jasstafel/schlaeger/data/schlaeger_score.dart';
import 'package:jasstafel/settings/schlaeger_settings.g.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/common/widgets/settings_provider.dart';

class SchlaegerPlayers {
  static int get min => 3;
  static int get max => 4;
}

class SchlaegerSettingsScreen extends StatefulWidget {
  final BoardData<SchlaegerSettings, SchlaegerScore> boardData;

  const SchlaegerSettingsScreen(this.boardData, {super.key});

  @override
  State<SchlaegerSettingsScreen> createState() =>
      _SchlaegerSettingsScreenState();
}

class _SchlaegerSettingsScreenState extends State<SchlaegerSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = widget.boardData.settings;
    final commonSettings = CommonSettings();
    final preferences = SettingsProvider.of(context);
    commonSettings.fromPreferences(preferences);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsTitle(context.l10n.schlaeger)),
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
            min: SchlaegerPlayers.min,
            max: SchlaegerPlayers.max,
            onChanged: (value) {
              setState(() {
                settings.players = value;
                settings.toPreferences(preferences);
              });
            },
            displayValue: (v) => Text('$v'),
          ),
          // Enable missingPlayer only if players is NOT 4
          buildDropdownTile<int>(
            context,
            title: context.l10n.missingPlayer,
            value: settings.missingPlayer,
            items: [
              DropdownMenuItem(value: 0, child: Text(context.l10n.missingP1)),
              DropdownMenuItem(value: 1, child: Text(context.l10n.missingP2)),
              DropdownMenuItem(value: 2, child: Text(context.l10n.missingP3)),
              DropdownMenuItem(value: 3, child: Text(context.l10n.missingP4)),
            ],
            onChanged: settings.players != 4
                ? (value) {
                    setState(() {
                      settings.missingPlayer = value!;
                      settings.toPreferences(preferences);
                    });
                  }
                : null,
          ),
          buildDropdownTile(
            context,
            title: context.l10n.goalType,
            value: settings.goalType,
            items: [
              DropdownMenuItem(
                value: GoalType.noGoal.index,
                child: Text(context.l10n.noGoal),
              ),
              DropdownMenuItem(
                value: GoalType.points.index,
                child: Text(context.l10n.goalPoints),
              ),
              DropdownMenuItem(
                value: GoalType.rounds.index,
                child: Text(context.l10n.rounds),
              ),
            ],
            onChanged: (value) {
              setState(() {
                settings.goalType = value!;
                settings.toPreferences(preferences);
              });
            },
          ),
          // Show goalPoints only if goalType is points
          if (settings.goalType == GoalType.points.index)
            PrefNumber(
              title: Text(context.l10n.goalPoints),
              value: settings.goalPoints,
              onChanged: (value) {
                setState(() {
                  settings.goalPoints = value;
                  settings.toPreferences(preferences);
                });
              },
            ),
          // Show goalRounds only if goalType is rounds
          if (settings.goalType == GoalType.rounds.index)
            PrefNumber(
              title: Text(context.l10n.rounds),
              value: settings.goalRounds,
              onChanged: (value) {
                setState(() {
                  settings.goalRounds = value;
                  settings.toPreferences(preferences);
                });
              },
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
