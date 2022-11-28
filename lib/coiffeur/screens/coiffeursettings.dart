import 'package:flutter/material.dart';
import 'package:pref/pref.dart';

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
        title: const Text("Coiffeur - Settings"),
      ),
      body: PrefPage(children: [
        const PrefTitle(title: Text("Counting")),
        const PrefCheckbox(title: Text("Runden"), pref: "coiffeur_rounded"),
        const PrefTitle(title: Text("Settings")),
        const PrefCheckbox(title: Text("3 Teams"), pref: "coiffeur_3teams"),
        const PrefDisabler(
          pref: "coiffeur_3teams",
          children: [
            PrefCheckbox(
                title: Text("Third Column"), pref: "coiffeur_third_column")
          ],
        ),
        PrefSlider(
          title: const Text('Runden'),
          pref: "coiffeur_rows",
          min: 6,
          max: 13,
          trailing: (num v) => Text('$v Runden'),
        ),
        const PrefTitle(title: Text("General")),
      ]),
    );
  }
}
