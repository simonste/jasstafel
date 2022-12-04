import 'package:flutter/material.dart';
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
        title: Text(context.l10n.settings_title(context.l10n.coiffeur)),
      ),
      body: PrefPage(children: [
        PrefTitle(title: Text(context.l10n.countingType)),
        PrefCheckbox(
            title: Text(context.l10n.denominator10), pref: "coiffeur_rounded"),
        PrefTitle(title: Text(context.l10n.settings)),
        PrefCheckbox(
            title: Text(context.l10n.threeTeams), pref: "coiffeur_3teams"),
        PrefDisabler(
          pref: "coiffeur_3teams",
          children: [
            PrefCheckbox(
                title: Text(context.l10n.thirdColumn),
                pref: "coiffeur_third_column")
          ],
        ),
        PrefSlider(
          title: Text(context.l10n.rounds),
          pref: "coiffeur_rows",
          min: 6,
          max: 13,
          trailing: (num v) => Text(context.l10n.noOfRounds(v)),
        ),
        PrefTitle(title: Text(context.l10n.commonSettings)),
        PrefCheckbox(
            title: Text(context.l10n.keepScreenOn), pref: "keepScreenOn"),
        PrefChoice<String>(
          title: Text(context.l10n.language),
          pref: 'appLanguage',
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
