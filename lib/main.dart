import 'package:flutter/material.dart';
import 'package:jasstafel/coiffeur/screens/coiffeur.dart';
import 'package:pref/pref.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final service = await PrefServiceShared.init(
    defaults: {
      'coiffeur_rounded': false,
      'coiffeur_bonus': false,
      'coiffeur_rows': 11,
      'coiffeur_3teams': false,
      'coiffeur_third_column': false,
    },
  );

  runApp(
    PrefService(
      service: service,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jasstafel',
      theme: ThemeData(brightness: Brightness.dark),
      home: const Coiffeur(),
    );
  }
}
