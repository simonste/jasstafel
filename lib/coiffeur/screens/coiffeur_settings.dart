import 'package:flutter/material.dart';
import 'package:jasstafel/common/widgets/pref_number.dart';
import 'package:jasstafel/settings/coiffeur_settings.g.dart';
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:pref/pref.dart';
import 'package:jasstafel/common/localization.dart';

class CoiffeurSettingsScreen extends StatefulWidget {
  const CoiffeurSettingsScreen({super.key});

  @override
  State<CoiffeurSettingsScreen> createState() => _CoiffeurSettingsScreenState();
}

class _CoiffeurSettingsScreenState extends State<CoiffeurSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsTitle(context.l10n.coiffeur)),
      ),
      body: PrefPage(children: [
        PrefTitle(title: Text(context.l10n.countingType)),
        PrefCheckbox(
            title: Text(context.l10n.denominator10),
            pref: CoiffeurSettings.keys.rounded),
        PrefNumber(
          title: Text(context.l10n.matchPoints),
          pref: CoiffeurSettings.keys.match,
        ),
        PrefCheckbox(
          title: Text(context.l10n.matchBonus),
          pref: CoiffeurSettings.keys.bonus,
          onChange: (value) {},
        ),
        PrefHider(
          pref: CoiffeurSettings.keys.bonus,
          children: [
            PrefNumber(
                title: Text(context.l10n.matchBonusVal),
                pref: CoiffeurSettings.keys.bonusValue),
            PrefNumber(
                title: Text(context.l10n.matchMalusVal),
                pref: CoiffeurSettings.keys.counterLoss)
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
