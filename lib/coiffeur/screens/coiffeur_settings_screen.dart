import 'package:flutter/material.dart';
import 'package:jasstafel/common/widgets/settings_screen_helpers.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/dialog/confirm_dialog.dart';
import 'package:jasstafel/common/setting_utils.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/common/widgets/pref_number.dart';
import 'package:jasstafel/common/widgets/profile_button.dart';
import 'package:jasstafel/common/widgets/profile_page.dart';
import 'package:jasstafel/coiffeur/data/coiffeur_score.dart';
import 'package:jasstafel/settings/coiffeur_settings.g.dart';
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:restart_app/restart_app.dart';
import 'package:jasstafel/common/widgets/settings_provider.dart';

class CoiffeurSettingsScreen extends StatefulWidget {
  final BoardData<CoiffeurSettings, CoiffeurScore> boardData;

  const CoiffeurSettingsScreen(this.boardData, {super.key});

  @override
  State<CoiffeurSettingsScreen> createState() => _CoiffeurSettingsScreenState();
}

class _CoiffeurSettingsScreenState extends State<CoiffeurSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = widget.boardData.settings;
    final commonSettings = CommonSettings();
    final matchPointsSubTitle = subTitle(
      settings.match,
      settings.rounded,
      context,
    );
    final bonusPointsSubTitle = subTitle(
      settings.bonusValue,
      settings.rounded,
      context,
    );
    final counterPointsSubTitle = subTitle(
      settings.counterLoss,
      settings.rounded,
      context,
    );

    final preferences = SettingsProvider.of(context);
    // captured before any edit below changes it
    final currentMatchPoints = settings.match;
    commonSettings.fromPreferences(preferences);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsTitle(context.l10n.coiffeur)),
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
          buildCheckboxTile(
            context,
            title: context.l10n.denominator10,
            value: settings.rounded,
            onChanged: (value) {
              setState(() {
                settings.rounded = value!;
                settings.toPreferences(preferences);
              });
            },
          ),
          PrefNumber(
            title: Text(context.l10n.matchPoints),
            subtitle: Text(matchPointsSubTitle),
            value: settings.match,
            onChanged: (value) {
              setState(() {
                settings.match = value;
                settings.toPreferences(preferences);
              });
            },
          ),
          PrefNumber(
            title: Text(context.l10n.matchMalusVal),
            subtitle: Text(counterPointsSubTitle),
            value: settings.counterLoss,
            onChanged: (value) {
              setState(() {
                settings.counterLoss = value;
                settings.toPreferences(preferences);
              });
            },
          ),
          buildCheckboxTile(
            context,
            title: context.l10n.matchBonus,
            subtitle: Text(
              context.l10n.matchBonusInfo(roundPoints(currentMatchPoints)),
            ),
            value: settings.bonus,
            onChanged: (value) async {
              if (value == null) return;
              setState(() {
                settings.bonus = value;
                settings.toPreferences(preferences);
              });

              final proposedMatchPoints = value
                  ? roundPoints(currentMatchPoints)
                  : matchPoints(currentMatchPoints);
              if (proposedMatchPoints == currentMatchPoints) return;

              confirmDialog(
                context: context,
                title: value
                    ? context.l10n.activatedBonus
                    : context.l10n.deactivatedBonus,
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
          // Show bonusValue only if bonus is enabled
          if (settings.bonus)
            PrefNumber(
              title: Text(context.l10n.matchBonusVal),
              subtitle: Text(bonusPointsSubTitle),
              value: settings.bonusValue,
              onChanged: (value) {
                setState(() {
                  settings.bonusValue = value;
                  settings.toPreferences(preferences);
                });
              },
            ),
          const Divider(),

          sectionTitle(context, context.l10n.settings),
          buildCheckboxTile(
            context,
            title: context.l10n.threeTeams,
            value: settings.threeTeams,
            onChanged: (value) {
              setState(() {
                settings.threeTeams = value!;
                settings.toPreferences(preferences);
              });
            },
          ),
          // thirdColumn has no effect with three teams, which already use it
          buildCheckboxTile(
            context,
            title: context.l10n.thirdColumn,
            value: settings.thirdColumn,
            onChanged: !settings.threeTeams
                ? (bool? value) {
                    setState(() {
                      settings.thirdColumn = value!;
                      settings.toPreferences(preferences);
                    });
                  }
                : null,
          ),
          buildSliderTile(
            context,
            title: context.l10n.rounds,
            value: settings.rows,
            min: 6,
            max: 13,
            onChanged: (value) {
              setState(() {
                settings.rows = value;
                settings.toPreferences(preferences);
              });
            },
            displayValue: (v) => Text(context.l10n.noOfRounds(v)),
          ),
          buildCheckboxTile(
            context,
            title: context.l10n.setFactorManually,
            value: settings.customFactor,
            onChanged: (value) {
              setState(() {
                settings.customFactor = value!;
                settings.toPreferences(preferences);
              });
            },
          ),
          buildCheckboxTile(
            context,
            title: context.l10n.completedRows,
            value: settings.greyCompletedRows,
            onChanged: (value) {
              setState(() {
                settings.greyCompletedRows = value!;
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
