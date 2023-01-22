import 'package:flutter/material.dart';

class ProfileRadio extends StatefulWidget {
  const ProfileRadio({
    super.key,
    required this.name,
    required this.selected,
    required this.onSelect,
    this.onLongPress,
    this.trailing,
  });

  final String name;

  final String selected;

  final Function? onSelect;

  final Function? onLongPress;

  final Widget? trailing;

  @override
  ProfileRadioState createState() => ProfileRadioState();
}

class ProfileRadioState<T> extends State<ProfileRadio> {
  void _onChange() {
    if (widget.onSelect != null) {
      widget.onSelect!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.name),
      trailing: widget.trailing,
      leading: Radio<String>(
        key: Key("${widget.name}_Radio"),
        value: widget.name,
        groupValue: widget.selected,
        onChanged: (String? val) => _onChange(),
      ),
      onTap: () => _onChange(),
      onLongPress: () {
        if (widget.onLongPress != null) {
          widget.onLongPress!();
        }
      },
    );
  }
}
