import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// https://stackoverflow.com/questions/45631350/flutter-hiding-floatingactionbutton

class BoardListWithFab extends StatefulWidget {
  const BoardListWithFab(
      {super.key,
      required this.header,
      required this.rows,
      required this.footer,
      required this.floatingActionButtons});

  final Widget header;
  final List<Widget> rows;
  final Widget footer;
  final List<Widget> floatingActionButtons;

  @override
  State<BoardListWithFab> createState() => _BoardListWithFabState();
}

class _BoardListWithFabState extends State<BoardListWithFab> {
  bool _fabAtBottom = true;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    return Stack(children: [
      Column(children: [
        widget.header,
        Expanded(
            child: NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            final ScrollDirection direction = notification.direction;
            setState(() {
              if (direction == ScrollDirection.reverse) {
                _fabAtBottom = false;
              } else if (direction == ScrollDirection.forward) {
                _fabAtBottom = true;
              }
            });
            return true;
          },
          child: SingleChildScrollView(
            child: Column(children: widget.rows),
          ),
        )),
        widget.footer
      ]),
      AnimatedPositioned(
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
        right: 20,
        bottom: _fabAtBottom ? 50 : screen.height - 160,
        child: Row(
          children: widget.floatingActionButtons,
        ),
      ),
    ]);
  }
}
