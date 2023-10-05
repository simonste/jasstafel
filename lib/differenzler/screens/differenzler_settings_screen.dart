import 'package:flutter/material.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/widgets/pref_hider_generic.dart';
import 'package:jasstafel/common/widgets/pref_number.dart';
import 'package:jasstafel/common/widgets/profile_button.dart';
import 'package:jasstafel/common/widgets/profile_page.dart';
import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/settings/common_settings.g.dart';
import 'package:jasstafel/settings/differenzler_settings.g.dart';
import 'package:pref/pref.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:restart_app/restart_app.dart';

class DifferenzlerSettingsScreen extends StatefulWidget {
  final BoardData boardData;

  const DifferenzlerSettingsScreen(this.boardData, {super.key});

  @override
  State<DifferenzlerSettingsScreen> createState() =>
      _DifferenzlerSettingsScreenState();
}

class _DifferenzlerSettingsScreenState
    extends State<DifferenzlerSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    DifferenzlerSettings settings = widget.boardData.settings;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsTitle(context.l10n.differenzler)),
      ),
      body: PrefPage(children: [
        PrefTitle(title: Text(context.l10n.profiles)),
        ProfileButton(
            pageTitle: Text(context.l10n.selectProfile),
            title: Text(widget.boardData.profiles.active),
            page: ProfilePage(widget.boardData, () => setState(() {}))),
        PrefTitle(title: Text(context.l10n.countingType)),
        PrefNumber(
          title: Text(context.l10n.pointsPerRound),
          pref: DifferenzlerSettings.keys.pointsPerRound,
        ),
        PrefTitle(title: Text(context.l10n.settings)),
        PrefSlider(
          title: Text(context.l10n.diffPlayers),
          pref: DifferenzlerSettings.keys.players,
          min: Players.min,
          max: Players.max,
          trailing: (num v) => Text('$v'),
        ),
        PrefCheckbox(
          title: Text(context.l10n.hideGuess),
          pref: DifferenzlerSettings.keys.hideGuess,
          onChange: (value) {
            settings.hideGuess = value;
            setState(() {});
          },
        ),
        PrefDropdown(
          title: Text(context.l10n.goalType),
          pref: DifferenzlerSettings.keys.goalType,
          items: [
            DropdownMenuItem(
                value: GoalType.noGoal.index, child: Text(context.l10n.noGoal)),
            DropdownMenuItem(
                value: GoalType.points.index,
                child: Text(context.l10n.goalPoints)),
            DropdownMenuItem(
                value: GoalType.rounds.index, child: Text(context.l10n.rounds)),
          ],
          onChange: (value) => {},
        ),
        PrefHiderGeneric(
          pref: DifferenzlerSettings.keys.goalType,
          nullValue: GoalType.points.index,
          children: [
            PrefNumber(
              title: Text(context.l10n.goalPoints),
              pref: DifferenzlerSettings.keys.goalPoints,
            ),
          ],
        ),
        PrefHiderGeneric(
          pref: DifferenzlerSettings.keys.goalType,
          nullValue: GoalType.rounds.index,
          children: [
            PrefNumber(
              title: Text(context.l10n.rounds),
              pref: DifferenzlerSettings.keys.goalRounds,
            ),
          ],
        ),
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
