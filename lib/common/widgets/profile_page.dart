import 'dart:convert';

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:jasstafel/common/data/board_data.dart';
import 'package:jasstafel/common/dialog/string_dialog.dart';
import 'package:jasstafel/common/widgets/profile_radio.dart';
import 'package:jasstafel/common/localization.dart';

String encodeProfile(Map<String, dynamic> profile) {
  var bytes = utf8.encode(jsonEncode(profile));
  return base64.encode(GZipEncoder().encode(bytes));
}

Map<String, dynamic> decodeProfile(String encoded) {
  var bytes = GZipDecoder().decodeBytes(base64.decode(encoded));
  var profile = jsonDecode(utf8.decode(bytes));
  return profile;
}

class ProfilePage extends StatefulWidget {
  final BoardData boardData;
  final Function updateParent;
  final Map<String, String> profiles = {};

  ProfilePage(this.boardData, this.updateParent, {super.key}) {
    for (var element in boardData.profiles.list) {
      var separator = element.indexOf(":");
      var profileName = element.substring(0, separator);
      var profile = element.substring(separator + 1);
      profiles[profileName] = profile;
    }

    saveCurrentProfile();
  }

  void saveCurrentProfile() {
    boardData.save();
    var json = boardData.settings.toJson();
    profiles[boardData.profiles.active] = encodeProfile(json);
    saveProfiles();
  }

  void loadProfile(String name) async {
    var profileStr = profiles[name] ?? "{}";
    var profile = decodeProfile(profileStr);
    boardData.fromJson(profile);
    updateParent();
  }

  void renameProfile(String oldName, String newName) {
    var newMap = profiles
        .map((key, value) => MapEntry((key == oldName) ? newName : key, value));
    profiles.clear();
    profiles.addAll(newMap);
    if (oldName == boardData.profiles.active) {
      boardData.profiles.active = newName;
      updateParent();
    }
    saveProfiles();
  }

  void copyProfile(String srcName, String newName) {
    profiles[newName] = profiles[srcName]!;
    saveProfiles();
  }

  void deleteProfile(String name) async {
    profiles.remove(name);
    saveProfiles();
  }

  void saveProfiles() {
    boardData.profiles.list.clear();
    profiles.forEach((key, value) {
      boardData.profiles.list.add("$key:$value");
    });
    boardData.saveProfiles();
  }

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState<T> extends State<ProfilePage> {
  void showProfileNameDialog(String value) async {
    var controller = TextEditingController();
    controller.text = value.toString();

    final input = await stringDialogBuilder(context, controller,
        title: context.l10n.profileName);
    if (input != null) {
      if (value.isEmpty) {
        copyProfile(widget.boardData.profiles.active, input);
      } else {
        renameProfile(value, input);
      }
    }
  }

  void renameProfile(String oldName, String newName) async {
    if (oldName != newName && widget.profiles.containsKey(newName)) {
      await profileNameAlreadyExists(context);
      return;
    }
    widget.renameProfile(oldName, newName);
    setState(() {});
  }

  void copyProfile(String srcName, String newName) async {
    if (widget.profiles.containsKey(newName)) {
      await profileNameAlreadyExists(context);
      return;
    }
    widget.copyProfile(srcName, newName);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];
    widget.profiles.forEach((key, value) {
      Widget actionIcon() {
        if (key == widget.boardData.profiles.active) {
          return InkWell(
            child: Tooltip(
                message: context.l10n.copyProfile,
                child: const Icon(Icons.copy)),
            onTap: () {
              showProfileNameDialog("");
            },
          );
        } else {
          return InkWell(
            child: Tooltip(
                message: context.l10n.deleteProfile,
                child: const Icon(Icons.delete)),
            onTap: () async {
              var result = await confirmDelete(context, key);
              if (result != null && result) {
                widget.deleteProfile(key);
                setState(() {});
              }
            },
          );
        }
      }

      widgets.add(ProfileRadio(
        name: key,
        selected: widget.boardData.profiles.active,
        onSelect: () {
          widget.boardData.profiles.active = key;
          widget.loadProfile(key);
          setState(() {});
        },
        trailing: actionIcon(),
        onLongPress: () {
          showProfileNameDialog(key);
        },
      ));
    });

    return ListView(children: widgets);
  }
}

Future<bool?> confirmDelete(BuildContext context, String name) {
  return showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            textButton(String text, bool delete) {
              return TextButton(
                  style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: Text(text),
                  onPressed: () {
                    Navigator.of(context).pop(delete);
                  });
            }

            return AlertDialog(
              title: Text(context.l10n.deleteProfile),
              content: Text(context.l10n.deleteProfileName(name)),
              actions: [
                textButton(context.l10n.cancel, false),
                textButton(context.l10n.ok, true)
              ],
            );
          },
        );
      });
}

Future<void> profileNameAlreadyExists(BuildContext context) {
  return showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            textButton(String text) {
              return TextButton(
                  style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: Text(text),
                  onPressed: () {
                    Navigator.of(context).pop();
                  });
            }

            return AlertDialog(
              title: Text(context.l10n.addProfileFail),
              actions: [textButton(context.l10n.ok)],
            );
          },
        );
      });
}
