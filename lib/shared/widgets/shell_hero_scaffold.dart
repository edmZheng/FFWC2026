import 'package:flutter/material.dart';

import 'world_cup_hero_skin.dart';

/// Shell Tab 页脚手架：透明内容区 + 色块背景渗入 AppBar 下方正文。
///
/// 色块绘制在 [body] 底层并向下延伸至屏幕 [heroHeightFraction]；[appBar] 保持透明叠于其上。
/// [body] 自动加上 AppBar 高度的 top inset，避免列表顶栏被遮挡。
class ShellHeroScaffold extends StatelessWidget {
  const ShellHeroScaffold({
    super.key,
    required this.tab,
    required this.appBar,
    required this.body,
    this.heroHeightFraction = 0.25,
  });

  final WorldCupTab tab;
  final PreferredSizeWidget appBar;
  final Widget body;

  /// 色块区域占屏幕高度的比例（默认 1/4）。
  final double heroHeightFraction;

  double _appBarExtent(BuildContext context) =>
      MediaQuery.paddingOf(context).top + appBar.preferredSize.height;

  double _heroHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height * heroHeightFraction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _heroHeight(context),
            child: WorldCupHeroBackground(tab: tab),
          ),
          Padding(
            padding: EdgeInsets.only(top: _appBarExtent(context)),
            child: body,
          ),
        ],
      ),
    );
  }
}
