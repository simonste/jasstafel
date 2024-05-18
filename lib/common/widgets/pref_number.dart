import 'package:flutter/material.dart';
import 'package:pref/pref.dart';
import 'package:jasstafel/common/localization.dart';

class PrefNumber extends StatelessWidget {
  const PrefNumber(
      {this.title,
      this.subtitle,
      required this.pref,
      super.key,
      this.onChange});

  final Widget? title;
  final Widget? subtitle;
  final String pref;
  final ValueChanged<int?>? onChange;

  @override
  Widget build(BuildContext context) {
    return PrefCustom<int>(
      title: title,
      subtitle: subtitle,
      pref: pref,
      onTap: _tap,
      onChange: onChange,
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
            keyboardType: const TextInputType.numberWithOptions(signed: false),
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

    return result == true ? int.parse(controller.text).abs() : value;
  }
}
