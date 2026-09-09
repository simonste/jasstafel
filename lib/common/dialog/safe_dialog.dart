import 'package:flutter/material.dart';

/// Like [showDialog], but ignores pop attempts within [debounceMs] of
/// opening, to avoid iPadOS ghost touches immediately closing the dialog.
Future<T?> showSafeDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  int debounceMs = 400,
}) {
  final openTime = DateTime.now();

  return showDialog<T>(
    context: context,
    builder: (dialogContext) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;

          final elapsed = DateTime.now().difference(openTime).inMilliseconds;
          if (elapsed > debounceMs) {
            Navigator.of(dialogContext).pop(result);
          }
        },
        child: builder(dialogContext),
      );
    },
  );
}
