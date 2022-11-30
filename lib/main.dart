import 'package:flutter/material.dart';
import 'package:jasstafel/coiffeur/screens/coiffeur.dart';

void main() {
  runApp(const MyApp());
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
