import 'package:flutter/material.dart';
import 'package:jasstafel/coiffeur/screens/coiffeur.dart';
import 'package:jasstafel/schieber/screens/schieber.dart';

enum Board { schieber, coiffeur }

class BoardTitle extends Theme {
  BoardTitle(Board board, context, {super.key})
      : super(
          data: ThemeData.dark(),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Board>(
              value: board,
              items: const <DropdownMenuItem<Board>>[
                DropdownMenuItem(
                  value: Board.schieber,
                  child: Text('Schieber'),
                ),
                DropdownMenuItem(
                  value: Board.coiffeur,
                  child: Text('Coiffeur'),
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
