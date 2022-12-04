import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CoiffeurTypeCell extends Expanded {
  final GestureLongPressCallback? onLongPress;

  CoiffeurTypeCell(int factor, String name, {super.key, this.onLongPress})
      : super(
            child: InkWell(
                onLongPress: onLongPress,
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: _createChildren(factor, name),
                )));

  static Widget _createChildren(factor, name) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
            top: 10,
            left: 10,
            child: SvgPicture.asset(
              'assets/types/${_assetName(name)}.svg',
              width: 30,
            )),
        Positioned(
          left: 45,
          top: 20,
          child: Text(name),
        ),
        Positioned(
          right: 5,
          top: 5,
          child: Text(factor.toString()),
        ),
      ],
    );
  }

  static String _assetName(String name) {
    /* spell-checker:disable */
    switch (name.toLowerCase()) {
      case "eichel":
        return 'eicheln';
      case "rose":
        return 'rosen';
      case "schelle":
        return 'schellen';
    }
    /* spell-checker:enable */
    return name.toLowerCase();
  }
}
