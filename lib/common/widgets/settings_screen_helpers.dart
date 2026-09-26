import 'package:flutter/material.dart';
import 'package:jasstafel/common/localization.dart';
import 'package:jasstafel/common/utils.dart';

/// Builds a section title widget for settings screens.
Widget sectionTitle(BuildContext context, String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.secondary,
      ),
    ),
  );
}

/// Builds a checkbox list tile for settings screens.
Widget buildCheckboxTile(
  BuildContext context, {
  required String title,
  required bool value,
  Widget? subtitle,
  ValueChanged<bool?>? onChanged,
}) {
  return CheckboxListTile(
    title: Text(title),
    subtitle: subtitle,
    value: value,
    onChanged: onChanged,
    dense: true,
  );
}

/// Builds a slider tile for settings screens.
///
/// A null [onChanged] disables the row, as it does for the other tiles.
Widget buildSliderTile(
  BuildContext context, {
  required String title,
  required int value,
  required int min,
  required int max,
  required ValueChanged<int>? onChanged,
  required Widget Function(int) displayValue,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.apply(
            color: onChanged == null ? Theme.of(context).disabledColor : null,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                onChanged: onChanged == null
                    ? null
                    : (v) => onChanged(v.round()),
              ),
            ),
            displayValue(value),
          ],
        ),
      ),
    ],
  );
}

/// Builds a dropdown tile for settings screens.
///
/// A null [onChanged] disables the row, as it does for the other tiles.
Widget buildDropdownTile<T>(
  BuildContext context, {
  required String title,
  required T value,
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?>? onChanged,
}) {
  return ListTile(
    enabled: onChanged != null,
    title: Text(title),
    trailing: DropdownButton<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      underline: Container(),
    ),
    dense: true,
  );
}

/// Builds the tile to choose how points are rounded to tens.
Widget buildRoundingTile(
  BuildContext context, {
  required RoundingMode value,
  required ValueChanged<RoundingMode> onChanged,
}) {
  return buildCheckboxTile(
    context,
    title: context.l10n.denominator10,
    value: value != RoundingMode.none,
    onChanged: (rounded) =>
        onChanged(rounded! ? RoundingMode.round : RoundingMode.none),
  );
}

/// Builds a text field tile for settings screens.
///
/// A null [onChanged] disables the row, as it does for the other tiles.
Widget buildTextFieldTile(
  BuildContext context, {
  required String label,
  required String value,
  required String? Function(String?)? validator,
  required ValueChanged<String>? onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      initialValue: value,
      validator: validator,
      enabled: onChanged != null,
      onChanged: onChanged,
    ),
  );
}
