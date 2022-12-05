import 'package:flutter/material.dart';
import 'package:jasstafel/coiffeur/widgets/coiffeurtypeimage.dart';

class CoiffeurTypeCell extends Expanded {
  final GestureLongPressCallback? onLongPress;

  CoiffeurTypeCell(int factor, String name, context,
      {super.key, this.onLongPress})
      : super(
            child: InkWell(
                onLongPress: onLongPress,
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: _createChildren(factor, name, context),
                )));

  static Widget _createChildren(factor, name, context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 10,
          bottom: 10,
          left: 5,
          child: CoiffeurTypeImage(context, name, width: 30),
        ),
        Positioned(
          left: 35,
          top: 18,
          bottom: 18,
          child: FittedBox(
            child: Text(name),
          ),
        ),
        Positioned(
          right: 5,
          top: 5,
          child: Text(factor.toString()),
        ),
      ],
    );
  }
}
