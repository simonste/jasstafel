import 'package:flutter/material.dart';
import 'package:pref/pref.dart';
import 'package:jasstafel/common/localization.dart';

class PrefNumber extends StatelessWidget {
  const PrefNumber({this.title, required this.pref, super.key});

  final Widget? title;
  final String pref;

  @override
  Widget build(BuildContext context) {
    return PrefCustom<int>(
      title: title,
      pref: pref,
      onTap: _tap,
    );
  }

  Future<int?> _tap(BuildContext context, int? value) async {
    var controller = TextEditingController(text: value.toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: title,
        content: SingleChildScrollView(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
          ),
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
            child: Text(context.l10n.ok),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );

    return result == true ? int.parse(controller.text) : value;
  }
}
