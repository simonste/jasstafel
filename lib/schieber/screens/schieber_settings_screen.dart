import 'package:flutter/material.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/dialog/confirm_dialog.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/common/widgets/pref_number.dart';
import 'package:jasstafel/common/widgets/profile_button.dart';
import 'package:jasstafel/common/widgets/profile_page.dart';
import 'package:jasstafel/common/widgets/settings_screen_helpers.dart';
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:jasstafel/settings/schieber_settings.g.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:restart_app/restart_app.dart';
import 'package:jasstafel/common/widgets/settings_provider.dart';

class SchieberSettingsScreen extends StatefulWidget {
  final BoardData boardData;

  const SchieberSettingsScreen(this.boardData, {super.key});

  @override
  State<SchieberSettingsScreen> createState() => _SchieberSettingsScreenState();
}

class _SchieberSettingsScreenState extends State<SchieberSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = widget.boardData.settings as SchieberSettings;
    final commonSettings = CommonSettings();
    final preferences = SettingsProvider.of(context);

    // captured before any edit below changes them
    final currentMatchPoints = settings.match;
    final currentPointsPerRound = settings.pointsPerRound;
    commonSettings.fromPreferences(preferences);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsTitle(context.l10n.schieber)),
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

          sectionTitle(context, context.l10n.countingType),
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
          // Enable differentGoals only if goalType is points
          buildCheckboxTile(
            context,
            title: context.l10n.differentGoals,
            value: settings.differentGoals,
            onChanged: settings.goalType == GoalType.points.index
                ? (value) {
                    setState(() {
                      settings.differentGoals = value!;
                      settings.toPreferences(preferences);
                    });
                  }
                : null,
          ),
          PrefNumber(
            title: Text(context.l10n.matchPoints),
            value: settings.match,
            onChanged: (value) async {
              setState(() {
                settings.match = value;
                settings.toPreferences(preferences);
              });

              final proposedPointsPerRound = roundPoints(value);
              if (currentPointsPerRound == proposedPointsPerRound) return;

              confirmDialog(
                context: context,
                title: context.l10n.matchPointsChanged,
                subtitle: context.l10n.resetPointsPerRound(
                  proposedPointsPerRound,
                ),
                actions: [
                  DialogAction(
                    text: context.l10n.ok,
                    action: () {
                      setState(() {
                        settings.pointsPerRound = proposedPointsPerRound;
                        settings.toPreferences(preferences);
                      });
                    },
                  ),
                ],
              );
            },
          ),
          PrefNumber(
            title: Text(context.l10n.pointsPerRound),
            value: settings.pointsPerRound,
            onChanged: (value) async {
              setState(() {
                settings.pointsPerRound = value;
                settings.toPreferences(preferences);
              });

              final proposedMatchPoints = matchPoints(value);
              if (currentMatchPoints == proposedMatchPoints) return;

              confirmDialog(
                context: context,
                title: context.l10n.pointsPerRoundChanged,
                subtitle: context.l10n.resetMatchPoints(proposedMatchPoints),
                actions: [
                  DialogAction(
                    text: context.l10n.ok,
                    action: () {
                      setState(() {
                        settings.match = proposedMatchPoints;
                        settings.toPreferences(preferences);
                      });
                    },
                  ),
                ],
              );
            },
          ),
          const Divider(),

          sectionTitle(context, context.l10n.settings),
          buildCheckboxTile(
            context,
            title: context.l10n.allowTouch,
            value: settings.touchScreen,
            onChanged: (value) {
              setState(() {
                settings.touchScreen = value!;
                settings.toPreferences(preferences);
              });
            },
          ),
          // Show vibrate only if touchScreen is enabled
          buildCheckboxTile(
            context,
            title: context.l10n.vibrateOnTouch,
            value: settings.vibrate,
            onChanged:
                settings.touchScreen && widget.boardData.supportsVibration
                ? (value) {
                    setState(() {
                      settings.vibrate = value!;
                      settings.toPreferences(preferences);
                    });
                  }
                : null,
          ),
          buildCheckboxTile(
            context,
            title: context.l10n.backsideSetting,
            value: settings.backside,
            onChanged: (value) {
              setState(() {
                settings.backside = value!;
                settings.toPreferences(preferences);
              });
            },
          ),
          // Enable backsideColumns only if backside is enabled
          buildSliderTile(
            context,
            title: context.l10n.backsideColumns,
            value: settings.backsideColumns,
            min: 2,
            max: 6,
            onChanged: settings.backside
                ? (value) {
                    setState(() {
                      settings.backsideColumns = value;
                      settings.toPreferences(preferences);
                    });
                  }
                : null,
            displayValue: (v) => Text('$v'),
          ),
          buildCheckboxTile(
            context,
            title: context.l10n.bigScore,
            value: settings.bigScore,
            onChanged: (value) {
              setState(() {
                settings.bigScore = value!;
                settings.toPreferences(preferences);
              });
            },
          ),
          buildCheckboxTile(
            context,
            title: context.l10n.drawZ,
            value: settings.drawZ,
            onChanged: (value) {
              setState(() {
                settings.drawZ = value!;
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
              Restart.restartApp();
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
              Restart.restartApp();
            },
          ),
        ],
      ),
    );
  }
}
