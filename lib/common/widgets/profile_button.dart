import 'package:flutter/material.dart';
import 'package:jasstafel/common/widgets/profile_page.dart';

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
    return ListTile(
      title: title,
      subtitle: subtitle,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: pageTitle ?? title),
            body: page,
          ),
        ),
      ),
    );
  }
}
