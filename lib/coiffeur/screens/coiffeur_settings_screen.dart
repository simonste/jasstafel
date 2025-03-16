import 'package:flutter/material.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/dialog/confirm_dialog.dart';
import 'package:jasstafel/common/setting_utils.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/common/widgets/pref_number.dart';
import 'package:jasstafel/common/widgets/profile_button.dart';
import 'package:jasstafel/common/widgets/profile_page.dart';
import 'package:jasstafel/settings/coiffeur_settings.g.dart';
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:pref/pref.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:restart_app/restart_app.dart';

class CoiffeurSettingsScreen extends StatefulWidget {
  final BoardData boardData;

  const CoiffeurSettingsScreen(this.boardData, {super.key});

  @override
  State<CoiffeurSettingsScreen> createState() => _CoiffeurSettingsScreenState();
}

class _CoiffeurSettingsScreenState extends State<CoiffeurSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    CoiffeurSettings settings = widget.boardData.settings;
    final matchPointsSubTitle =
        subTitle(settings.match, settings.rounded, context);
    final bonusPointsSubTitle =
        subTitle(settings.bonusValue, settings.rounded, context);
    final counterPointsSubTitle =
        subTitle(settings.counterLoss, settings.rounded, context);

    final currentMatchPoints =
        PrefService.of(context).get(CoiffeurSettings.keys.match);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsTitle(context.l10n.coiffeur)),
      ),
      body: PrefPage(children: [
        PrefTitle(title: Text(context.l10n.profiles)),
        ProfileButton(
            pageTitle: Text(context.l10n.selectProfile),
            title: Text(widget.boardData.profiles.active),
            page: ProfilePage(widget.boardData, () => setState(() {}))),
        PrefTitle(title: Text(context.l10n.countingType)),
        PrefCheckbox(
          title: Text(context.l10n.denominator10),
          pref: CoiffeurSettings.keys.rounded,
          onChange: (value) {
            settings.rounded = value;
            setState(() {});
          },
        ),
        PrefNumber(
          title: Text(context.l10n.matchPoints),
          subtitle: Text(matchPointsSubTitle),
          pref: CoiffeurSettings.keys.match,
          onChange: (value) {
            settings.match = value!;
            setState(() {});
          },
        ),
        PrefNumber(
            title: Text(context.l10n.matchMalusVal),
            subtitle: Text(counterPointsSubTitle),
            pref: CoiffeurSettings.keys.counterLoss,
            onChange: (value) {
              settings.counterLoss = value!;
              setState(() {});
            }),
        PrefCheckbox(
          title: Text(context.l10n.matchBonus),
          subtitle: Text(
              context.l10n.matchBonusInfo(roundPoints(currentMatchPoints))),
          pref: CoiffeurSettings.keys.bonus,
          onChange: (value) async {
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
                        final pref = PrefService.of(context);
                        final key = CoiffeurSettings.keys.match;
                        pref.set(key, proposedMatchPoints);
                        settings.match = proposedMatchPoints;
                      })
                ]);
          },
        ),
        PrefHider(
          pref: CoiffeurSettings.keys.bonus,
          children: [
            PrefNumber(
                title: Text(context.l10n.matchBonusVal),
                subtitle: Text(bonusPointsSubTitle),
                pref: CoiffeurSettings.keys.bonusValue,
                onChange: (value) {
                  settings.bonusValue = value!;
                  setState(() {});
                }),
          ],
        ),

        //
        PrefTitle(title: Text(context.l10n.settings)),
        PrefCheckbox(
            title: Text(context.l10n.threeTeams),
            pref: CoiffeurSettings.keys.threeTeams),
        PrefDisabler(
          pref: CoiffeurSettings.keys.threeTeams,
          children: [
            PrefCheckbox(
                title: Text(context.l10n.thirdColumn),
                pref: CoiffeurSettings.keys.thirdColumn)
          ],
        ),
        PrefSlider(
          title: Text(context.l10n.rounds),
          pref: CoiffeurSettings.keys.rows,
          min: 6,
          max: 13,
          trailing: (num v) => Text(context.l10n.noOfRounds(v as int)),
        ),
        PrefCheckbox(
            title: Text(context.l10n.setFactorManually),
            pref: CoiffeurSettings.keys.customFactor),
        PrefCheckbox(
            title: Text(context.l10n.completedRows),
            pref: CoiffeurSettings.keys.greyCompletedRows),

        //
        PrefTitle(title: Text(context.l10n.commonSettings)),
        PrefCheckbox(
            title: Text(context.l10n.keepScreenOn),
            pref: CommonSettings.keys.keepScreenOn),
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
      ]),
    );
  }
}
