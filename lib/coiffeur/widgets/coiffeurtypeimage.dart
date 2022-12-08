import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jasstafel/common/localization.dart';

class CoiffeurTypeImage extends SvgPicture {
  CoiffeurTypeImage(context, name, {super.key, super.width})
      : super.asset('assets/types/${assetName(context, name)}.svg',
            semanticsLabel: name);

  static String assetName(BuildContext context, String name) {
    /* spell-checker:disable */
    var knownTypes = {
      _unify(context.l10n.eicheln): "eicheln",
      _unify(context.l10n.schellen): "schellen",
      _unify(context.l10n.schilten): "schilten",
      _unify(context.l10n.rosen): "rosen",
      _unify(context.l10n.schaufel): "schaufel",
      _unify(context.l10n.kreuz): "kreuz",
      _unify(context.l10n.ecken): "ecken",
      _unify(context.l10n.herz): "herz",
      _unify(context.l10n.trumpf): "trumpf",
      _unify(context.l10n.obenabe): "obenabe",
      _unify(context.l10n.obe): "obenabe",
      _unify(context.l10n.ondenufe): "ondenufe",
      _unify(context.l10n.onde): "ondenufe",
      _unify(context.l10n.obenabeOndenufe): "obe_onde",
      _unify(context.l10n.obeOnde): "obe_onde",
      _unify(context.l10n.slalom): "slalom",
      _unify(context.l10n.gusti): "gusti",
      _unify(context.l10n.mery): "mery",
      _unify(context.l10n.slalomGusti): "slalom_gusti",
      _unify(context.l10n.gustiMery): "gusti_mery",
      _unify(context.l10n.misere): "misere",
      _unify(context.l10n.coiffeur): "coiffeur",
      _unify(context.l10n.wunsch): "wunsch",
      _unify(context.l10n.joker): "wunsch",
      _unify(context.l10n.free): "wunsch",
      _unify(context.l10n.superEicheln): "super_eicheln",
      _unify(context.l10n.tutti): "tutti",
      _unify(context.l10n.tannenbaum): "tannenbaum",
      _unify(context.l10n.emmentaler): "emmentaler",
      _unify(context.l10n.blind): "blind",
    };
    /* spell-checker:enable */
    var input = _unify(name);
    if (knownTypes.containsKey(input)) {
      return knownTypes[input]!;
    }
    return 'empty';
  }

  static String _unify(String name) {
    // ignore whitespace, - , / and dialect specific n,ä,e.
    return name
        .toLowerCase()
        .replaceAll(RegExp('\\s|-|/|n|ä|e|é|è'), '')
        .replaceAll("u", "o") // Characters u and o are replaceable
        .replaceAll("sch", "s"); // replace sch with s
  }
}
