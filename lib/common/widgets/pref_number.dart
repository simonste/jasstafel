import 'package:flutter/material.dart';
import 'package:jasstafel/common/localization.dart';

/// A ListTile that displays a number and allows editing it via a dialog.
///
/// This is a replacement for the PrefNumber widget from the pref package.
/// Unlike the original, this widget requires the parent to manage the value and
/// saving to SharedPreferences.
///
/// Parameters:
/// - title: The title to display
/// - subtitle: Optional subtitle
/// - value: The current value
/// - onChanged: Callback when the value changes (parent should save to preferences)
class PrefNumber extends StatelessWidget {
  const PrefNumber({
    this.title,
    this.subtitle,
    required this.value,
    super.key,
    this.onChanged,
  });

  final Widget? title;
  final Widget? subtitle;
  final int value;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: title,
      subtitle: subtitle,
      trailing: Text('$value'),
      onTap: () => _showEditDialog(context),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final controller = TextEditingController(text: value.toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: title,
        content: SingleChildScrollView(
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(signed: false),
            autofocus: true,
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

    if (result == true) {
      final newValue = int.tryParse(controller.text)?.abs() ?? value;
      if (onChanged != null) {
        onChanged!(newValue);
      }
    }
  }
}
