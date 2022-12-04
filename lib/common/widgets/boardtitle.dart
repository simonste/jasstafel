import 'package:flutter/material.dart';
import 'package:jasstafel/coiffeur/screens/coiffeur.dart';
import 'package:jasstafel/schieber/screens/schieber.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum Board { schieber, coiffeur }

class BoardTitle extends Theme {
  BoardTitle(Board board, context, {super.key})
      : super(
          data: ThemeData.dark(),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Board>(
              value: board,
              items: <DropdownMenuItem<Board>>[
                DropdownMenuItem(
                  value: Board.schieber,
                  child: Text(AppLocalizations.of(context)!.schieber),
                ),
                DropdownMenuItem(
                  value: Board.coiffeur,
                  child: Text(AppLocalizations.of(context)!.coiffeur),
                ),
              ],
              onChanged: (value) {
                Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
                  builder: (context) {
                    switch (value) {
                      case Board.schieber:
                        return const Schieber();
                      case Board.coiffeur:
                        return const Coiffeur();
                      default:
                        return const Schieber();
                    }
                  },
                ));
              },
            ),
          ),
        );
}
