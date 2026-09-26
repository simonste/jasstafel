import 'package:flutter/material.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/common/utils.dart';

String subTitle(int pts, RoundingMode mode, BuildContext context) {
  if (mode == RoundingMode.none) return "";
  return context.l10n.pointsRounded(roundedInt(pts, mode));
}
