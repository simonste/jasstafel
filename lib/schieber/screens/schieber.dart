import 'package:flutter/material.dart';
import 'package:jasstafel/common/widgets/boardtitle.dart';

class Schieber extends StatefulWidget {
  const Schieber({super.key});

  @override
  State<Schieber> createState() => _SchieberState();
}

class _SchieberState extends State<Schieber> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BoardTitle(Board.schieber, context),
        actions: [
          IconButton(
              onPressed: () {
                setState(() {});
              },
              icon: const Icon(Icons.delete)),
          IconButton(
              onPressed: () {
                _openSettings();
              },
              icon: const Icon(Icons.settings))
        ],
      ),
      body: const Center(
        child: Text("Hallo Welt"),
      ),
    );
  }

  void _openSettings() {}
}
