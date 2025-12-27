import 'package:flutter/material.dart';

class Progress extends Container {
  final bool flip;
  final double progress;
  final bool bottom;

  Progress(this.progress, {required this.flip, this.bottom = false, super.key});

  @override
  Widget build(BuildContext context) {
    if (flip) {
      return Positioned(
        top: bottom ? null : 1,
        bottom: bottom ? 1 : null,
        right: 0,
        child: RotatedBox(
          quarterTurns: 2,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.4,
            child: LinearProgressIndicator(value: progress),
          ),
        ),
      );
    } else {
      return Positioned(
        top: bottom ? null : 1,
        bottom: bottom ? 1 : null,
        left: 0,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.4,
          child: LinearProgressIndicator(value: progress),
        ),
      );
    }
  }
}
