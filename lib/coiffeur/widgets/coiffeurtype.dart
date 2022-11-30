import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CoiffeurType extends Container {
  CoiffeurType(
    String name, {
    super.key,
    super.alignment = Alignment.centerLeft,
    super.padding = const EdgeInsets.all(10),
  }) : super(child: _createChildren(name));

  static Widget _createChildren(String name) {
    return Row(children: [
      SvgPicture.asset(
        'assets/types/${_assetName(name)}.svg',
        width: 30,
      ),
      Text(name),
    ]);
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
