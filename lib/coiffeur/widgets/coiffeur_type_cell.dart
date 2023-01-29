import 'package:flutter/material.dart';
import 'package:jasstafel/coiffeur/data/coiffeur_score.dart';
import 'package:jasstafel/coiffeur/dialog/coiffeur_type_dialog.dart';
import 'package:jasstafel/coiffeur/widgets/coiffeur_type_image.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/settings/coiffeur_settings.g.dart';

class CoiffeurTypeCell extends StatelessWidget {
  final BoardData<CoiffeurSettings, CoiffeurScore> state;
  final int row;
  final Function updateParent;

  const CoiffeurTypeCell(this.state, this.row, this.updateParent, {super.key});

  @override
  Widget build(BuildContext context) {
    String name = state.score.rows[row].type;
    int factor = state.score.rows[row].factor;

    return Expanded(
        child: InkWell(
      onLongPress: () {
        _coiffeurTypeDialog(context);
      },
      child: Stack(
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
      ),
    ));
  }

  void _coiffeurTypeDialog(BuildContext context) async {
    var controller = TextEditingController(text: state.score.rows[row].type);

    var title = state.settings.customFactor
        ? context.l10n.xRound(row + 1)
        : context.l10n.xTimes(row + 1);

    final input = await coiffeurTypeDialogBuilder(context, title, controller,
        state.score.rows[row].factor, state.settings.customFactor);
    if (input == null || input.factor == 0 || input.type.isEmpty) {
      return; // empty name not allowed
    }
    state.score.rows[row].factor = input.factor;
    state.score.rows[row].type = input.type;
    state.save();
    updateParent();
  }
}
