import 'package:flutter/material.dart';
import 'package:jasstafel/common/widgets/settings_screen_helpers.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/rounding.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/common/widgets/pref_number.dart';
import 'package:jasstafel/common/widgets/profile_button.dart';
import 'package:jasstafel/common/widgets/profile_page.dart';
import 'package:jasstafel/common/setting_utils.dart';
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:jasstafel/point_board/data/point_board_score.dart';
import 'package:jasstafel/settings/point_board_settings.g.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/common/widgets/settings_provider.dart';

class PointBoardSettingsScreen extends StatefulWidget {
  final BoardData<PointBoardSettings, PointBoardScore> boardData;

  const PointBoardSettingsScreen(this.boardData, {super.key});

  @override
  State<PointBoardSettingsScreen> createState() =>
      _PointBoardSettingsScreenState();
}

class _PointBoardSettingsScreenState extends State<PointBoardSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = widget.boardData.settings;
    final commonSettings = CommonSettings();
    final goalPointsSubTitle = subTitle(
      settings.goalPoints,
      settings.roundingMode,
      context,
    );

    final preferences = SettingsProvider.of(context);
    commonSettings.fromPreferences(preferences);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsTitle(context.l10n.pointBoard)),
      ),
      body: ListView(
        children: [
          // Profiles section
          sectionTitle(context, context.l10n.profiles),
          ProfileButton(
            pageTitle: Text(context.l10n.selectProfile),
            title: Text(widget.boardData.profiles.active),
            page: ProfilePage(widget.boardData, () => setState(() {})),
          ),
          const Divider(),

          // Counting Type section
          sectionTitle(context, context.l10n.countingType),
          buildRoundingTile(
            context,
            value: settings.roundingMode,
            onChanged: (value) {
              setState(() {
                settings.roundingMode = value;
                settings.toPreferences(preferences);
              });
            },
          ),
          buildCheckboxTile(
            context,
            title: context.l10n.enablePpr,
            value: settings.enablePointsPerRound,
            onChanged: (value) {
              setState(() {
                settings.enablePointsPerRound = value!;
                settings.toPreferences(preferences);
              });
            },
          ),
          // Only enable pointsPerRound if enablePointsPerRound is set
          PrefNumber(
            title: Text(context.l10n.pointsPerRound),
            value: settings.pointsPerRound,
            onChanged: settings.enablePointsPerRound
                ? (value) {
                    setState(() {
                      settings.pointsPerRound = value;
                      settings.toPreferences(preferences);
                    });
                  }
                : null,
          ),
          const Divider(),

          // Settings section
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
              subtitle: Text(goalPointsSubTitle),
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
          // Show goalMax only if goalType is NOT noGoal
          if (settings.goalType != GoalType.noGoal.index)
            buildCheckboxTile(
              context,
              title: context.l10n.positiveGoal,
              value: settings.goalMax,
              onChanged: (value) {
                setState(() {
                  settings.goalMax = value!;
                  settings.toPreferences(preferences);
                });
              },
            ),
          const Divider(),

          // Common Settings section
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
