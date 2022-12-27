import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jasstafel/common/data/common_data.dart';
import 'package:jasstafel/common/localization.dart';

class WhoIsNextButton extends IconButton {
  WhoIsNextButton(
      BuildContext context, CommonData data, List<String> teams, int rounds,
      {bool playerNames = false, super.key})
      : super(
            onPressed: () {
              final duration = (data.duration() != null)
                  ? context.l10n.duration(data.duration()!)
                  : "";

              dialogBuilder(context, duration);
            },
            icon: SvgPicture.asset("assets/actions/who_is_next.svg"));
}

Future<void> dialogBuilder(BuildContext context, String duration) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(context.l10n.whoBegins),
        content: Text(duration),
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
}
