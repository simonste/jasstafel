import 'package:jasstafel/common/utils.dart';
import 'package:jasstafel/settings/coiffeur_settings.g.dart';
import 'package:jasstafel/settings/molotow_settings.g.dart';
import 'package:jasstafel/settings/point_board_settings.g.dart';

extension CoiffeurRounding on CoiffeurSettings {
  RoundingMode get roundingMode =>
      rounded ? RoundingMode.round : RoundingMode.none;
  set roundingMode(RoundingMode mode) => rounded = mode != RoundingMode.none;
}

extension MolotowRounding on MolotowSettings {
  RoundingMode get roundingMode =>
      rounded ? RoundingMode.round : RoundingMode.none;
  set roundingMode(RoundingMode mode) => rounded = mode != RoundingMode.none;
}

extension PointBoardRounding on PointBoardSettings {
  RoundingMode get roundingMode =>
      rounded ? RoundingMode.round : RoundingMode.none;
  set roundingMode(RoundingMode mode) => rounded = mode != RoundingMode.none;
}
