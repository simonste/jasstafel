import 'package:flutter/material.dart';

class SettingsButton<T extends StatefulWidget> extends IconButton {
  final T widget;

  SettingsButton(this.widget, BuildContext context, Function callback,
      {super.key = const Key("SettingsButton")})
      : super(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) {
                    return widget;
                  },
                ),
              ).then((value) {
                callback();
              });
            },
            icon: const Icon(Icons.settings));
}
