import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:jasstafel/coiffeur/data/coiffeur_score.dart';
import 'package:jasstafel/coiffeur/dialog/coiffeur_type_dialog.dart';
import 'package:jasstafel/coiffeur/widgets/coiffeur_type_image.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/settings/coiffeur_settings.g.dart';

class CoiffeurTypeCell extends StatelessWidget {
  final BoardData<CoiffeurSettings, CoiffeurScore> data;
  final int row;
  final Function updateParent;
  final AutoSizeGroup? group;

  const CoiffeurTypeCell({
    required this.data,
    required this.row,
    required this.updateParent,
    this.group,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final name = data.score.rows[row].type;
    final factor = data.score.rows[row].factor;
    final thirdCol = (data.settings.thirdColumn || data.settings.threeTeams);
    final double unit = thirdCol ? 4 : 6;

    return Expanded(
        child: InkWell(
      onLongPress: () {
        _coiffeurTypeDialog(context);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            padding: EdgeInsets.only(left: unit),
            alignment: Alignment.centerLeft,
            child: CoiffeurTypeImage(context, name, width: 6 * unit),
          ),
          Positioned(
              left: 7 * unit,
              top: 0,
              bottom: 0,
              right: 0,
              child: Container(
                alignment: Alignment.centerLeft,
                child: AutoSizeText(
                  name,
                  wrapWords: false,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 1000),
                  group: group,
                ),
              )),
          Positioned(
            right: unit,
            top: unit,
            child: Text("$factor"),
          ),
        ],
      ),
    ));
  }

  void _coiffeurTypeDialog(BuildContext context) async {
    var controller = TextEditingController(text: data.score.rows[row].type);

    var title = data.settings.customFactor
        ? context.l10n.xRound(row + 1)
        : context.l10n.xTimes(row + 1);

    final input = await coiffeurTypeDialogBuilder(context,
        title: title,
        controller: controller,
        factor: data.score.rows[row].factor,
        customFactor: data.settings.customFactor);
    if (input == null || input.factor == 0 || input.type.isEmpty) {
      return; // empty name not allowed
    }
    data.score.rows[row].factor = input.factor;
    data.score.rows[row].type = input.type;
    data.save();
    updateParent();
  }
}
