import 'package:auto_size_text/auto_size_text.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:jasstafel/common/localization.dart';

class StatisticsButton extends IconButton {
  StatisticsButton(
    BuildContext context,
    String elapsed,
    List<String> colHeader,
    List<List<String>> data, {
    String? summary,
  }) : super(
         key: const Key('statistics'),
         onPressed: () {
           dialogBuilder(context, elapsed, colHeader, data, summary);
         },
         icon: const Icon(Icons.bar_chart),
       );
}

enum RowType { bold, normal }

Future<void> dialogBuilder(
  BuildContext context,
  String elapsed,
  List<String> colHeader,
  List<List<String>> data,
  String? summary,
) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          var nameGroup = AutoSizeGroup();

          row(List<String> strings, {RowType rowType = RowType.normal}) {
            var group = AutoSizeGroup();
            text(String string, {Key? key, required bool first}) {
              return Expanded(
                child: SizedBox(
                  width: 1000,
                  height: 30,
                  child: AutoSizeText(
                    key: key,
                    string,
                    maxLines: first ? 2 : 1,
                    textAlign: first ? TextAlign.left : TextAlign.center,
                    group: first ? nameGroup : group,
                  ),
                ),
              );
            }

            return Row(
              children: strings
                  .mapIndexed(
                    (i, e) => text(e, key: Key("${i}_1"), first: (i == 0)),
                  )
                  .toList(),
            );
          }

          List<Widget> children = [Text(elapsed), const Divider()];
          colHeader.insert(0, "");
          children.add(row(colHeader));

          for (var d in data) {
            children.add(row(d));
          }

          if (summary != null) {
            children.add(const Divider());
            children.add(Text(summary));
          }

          return AlertDialog(
            title: Text(context.l10n.stats),
            content: Column(mainAxisSize: MainAxisSize.min, children: children),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: Text(context.l10n.ok),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    },
  );
}
