import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jasstafel/coiffeur/widgets/coiffeur_type_image.dart';

import '../helper/testapp.dart';

void main() {
  testWidgets('type matching', (WidgetTester tester) async {
    final widget = makeTestableExpanded(Builder(builder: (BuildContext ctx) {
      /* spell-checker:disable */
      expect(CoiffeurTypeImage.assetName(ctx, "Eichel"), "eicheln");
      expect(CoiffeurTypeImage.assetName(ctx, "Eichle"), "eicheln");
      expect(CoiffeurTypeImage.assetName(ctx, "Schilte"), "schilten");
      expect(CoiffeurTypeImage.assetName(ctx, "Rose"), "rosen");
      expect(CoiffeurTypeImage.assetName(ctx, "schaufle"), "schaufel");
      expect(CoiffeurTypeImage.assetName(ctx, "ecke"), "ecken");
      expect(CoiffeurTypeImage.assetName(ctx, "Obenabe"), "obenabe");
      expect(CoiffeurTypeImage.assetName(ctx, "Obenaben"), "obenabe");
      expect(CoiffeurTypeImage.assetName(ctx, "Obe"), "obenabe");
      expect(CoiffeurTypeImage.assetName(ctx, "undenufe"), "ondenufe");
      expect(CoiffeurTypeImage.assetName(ctx, "gusti"), "gusti");
      expect(CoiffeurTypeImage.assetName(ctx, "guschti"), "gusti");
      expect(CoiffeurTypeImage.assetName(ctx, "Trompf"), "trumpf");
      expect(CoiffeurTypeImage.assetName(ctx, "slalom gusti"), "slalom_gusti");
      expect(CoiffeurTypeImage.assetName(ctx, "misère"), "misere");
      expect(CoiffeurTypeImage.assetName(ctx, "super eichle"), "super_eicheln");
      expect(CoiffeurTypeImage.assetName(ctx, "tutti"), "tutti");
      expect(CoiffeurTypeImage.assetName(ctx, "emmentaler"), "emmentaler");
      expect(CoiffeurTypeImage.assetName(ctx, "blind"), "blind");
      expect(CoiffeurTypeImage.assetName(ctx, "wonsch"), "wunsch");
      expect(CoiffeurTypeImage.assetName(ctx, "frei"), "wunsch");
      expect(CoiffeurTypeImage.assetName(ctx, "joker"), "wunsch");
      expect(CoiffeurTypeImage.assetName(ctx, "onbekannt"), "empty");
      /* spell-checker:enable */
      return const Text("");
    }));

    await tester.pumpWidget(widget);
  });
}
