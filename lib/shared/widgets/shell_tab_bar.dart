import 'package:flutter/material.dart';

/// 赛程子 Tab（关注 / 赛中·未赛 / 完赛）。
class ShellTabBar extends StatelessWidget implements PreferredSizeWidget {
  const ShellTabBar({
    super.key,
    required this.controller,
    required this.tabs,
  });

  final TabController controller;
  final List<Widget> tabs;

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      tabs: tabs,
      dividerColor: Colors.transparent,
      dividerHeight: 0,
    );
  }
}
