import 'package:flutter/material.dart';
import 'package:jasstafel/common/widgets/profile_page.dart';
import 'package:pref/pref.dart';

class ProfileButton extends StatelessWidget {
  const ProfileButton({
    super.key,
    this.title,
    required this.page,
    this.subtitle,
    this.pageTitle,
  });

  final Widget? title;
  final Widget? pageTitle;
  final Widget? subtitle;
  final ProfilePage page;

  @override
  Widget build(BuildContext context) {
    return PrefChevron(
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: pageTitle ?? title),
            body: page,
          ),
        ),
      ),
      title: title,
      subtitle: subtitle,
    );
  }
}
