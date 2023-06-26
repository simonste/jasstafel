import 'package:flutter/material.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/common/utils.dart';

String subTitle(int pts, bool rounded, BuildContext context) {
  return rounded ? context.l10n.pointsRounded(roundedInt(pts, rounded)) : "";
}
