import 'package:flutter/material.dart';
import 'package:jasstafel/common/widgets/boardtitle.dart';
import 'package:jasstafel/common/localization.dart';

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
      body: Center(child: Text(context.l10n.schieber)),
    );
  }

  void _openSettings() {}
}
