import 'package:flutter/material.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/dialog/confirm_dialog.dart';
import 'package:jasstafel/common/widgets/pref_number.dart';
import 'package:jasstafel/common/widgets/profile_button.dart';
import 'package:jasstafel/common/widgets/profile_page.dart';
import 'package:jasstafel/settings/coiffeur_settings.g.dart';
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:pref/pref.dart';
import 'package:jasstafel/common/localization.dart';

class CoiffeurSettingsScreen extends StatefulWidget {
  final BoardData boardData;

  const CoiffeurSettingsScreen(this.boardData, {super.key});

  @override
  State<CoiffeurSettingsScreen> createState() => _CoiffeurSettingsScreenState();
}

class _CoiffeurSettingsScreenState extends State<CoiffeurSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final pref = PrefService.of(context);
    final keys = CoiffeurSettings.keys;
    subTitle(int pts) {
      return pref.get(keys.rounded)
          ? context.l10n.pointsRounded((pts * 0.1).round())
          : "";
    }

    final matchPointsSubTitle = subTitle(pref.get(keys.match));
    final bonusPointsSubTitle = subTitle(pref.get(keys.bonusValue));
    final counterPointsSubTitle = subTitle(pref.get(keys.counterLoss));

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
            pref: CoiffeurSettings.keys.rounded),
        PrefNumber(
          title: Text(context.l10n.matchPoints),
          subtitle: Text(matchPointsSubTitle),
          pref: CoiffeurSettings.keys.match,
        ),
        PrefNumber(
            title: Text(context.l10n.matchMalusVal),
            subtitle: Text(counterPointsSubTitle),
            pref: CoiffeurSettings.keys.counterLoss),
        PrefCheckbox(
          title: Text(context.l10n.matchBonus),
          subtitle: Text(context.l10n.matchBonusInfo(157)),
          pref: CoiffeurSettings.keys.bonus,
          onChange: (value) async {
            final proposedMatchPoints = value ? 157 : 257;
            if (proposedMatchPoints == pref.get(keys.match)) return;

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
                        pref.set(
                            CoiffeurSettings.keys.match, proposedMatchPoints);
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
                pref: CoiffeurSettings.keys.bonusValue),
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
          trailing: (num v) => Text(context.l10n.noOfRounds(v)),
        ),
        PrefCheckbox(
            title: Text(context.l10n.setFactorManually),
            pref: CoiffeurSettings.keys.customFactor),

        //
        PrefTitle(title: Text(context.l10n.commonSettings)),
        PrefCheckbox(
            title: Text(context.l10n.keepScreenOn),
            pref: CommonSettings.keys.keepScreenOn),
        PrefChoice<String>(
          title: Text(context.l10n.language),
          pref: CommonSettings.keys.appLanguage,
          items: const [
            DropdownMenuItem(value: 'de', child: Text('Deutsch')),
            DropdownMenuItem(value: 'en', child: Text('English')),
            DropdownMenuItem(value: 'fr', child: Text('Français')),
          ],
          cancel: Text(context.l10n.cancel),
        ),
      ]),
    );
  }
}
