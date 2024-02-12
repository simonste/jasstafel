import 'package:flutter/material.dart';

class Progress extends Container {
  final bool flip;
  final double progress;

  Progress(this.progress, {required this.flip, super.key});

  @override
  Widget build(BuildContext context) {
    if (flip) {
      return Positioned(
          top: 1,
          right: 0,
          child: RotatedBox(
              quarterTurns: 2,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                child: LinearProgressIndicator(
                  value: progress,
                ),
              )));
    } else {
      return Positioned(
          top: 1,
          left: 0,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.4,
            child: LinearProgressIndicator(
              value: progress,
            ),
          ));
    }
  }
}
