import 'package:flutter/material.dart';

/// AppBar 居中标题图（FWC 品牌 + 页名横幅）。
class AppBarTitleImage extends StatelessWidget {
  const AppBarTitleImage({
    super.key,
    required this.asset,
    required this.semanticsLabel,
    this.height = 30,
    this.onTap,
  });

  const AppBarTitleImage.games({super.key, this.height = 30, this.onTap})
      : asset = 'assets/titles/games.png',
        semanticsLabel = '赛程';

  const AppBarTitleImage.rank({super.key, this.height = 30, this.onTap})
      : asset = 'assets/titles/rank.png',
        semanticsLabel = '积分榜';

  const AppBarTitleImage.teams({super.key, this.height = 30, this.onTap})
      : asset = 'assets/titles/teams.png',
        semanticsLabel = '球队';

  const AppBarTitleImage.stadium({super.key, this.height = 30, this.onTap})
      : asset = 'assets/titles/stadium.png',
        semanticsLabel = '场馆';

  const AppBarTitleImage.about({super.key, this.height = 30, this.onTap})
      : asset = 'assets/titles/about.png',
        semanticsLabel = '关于';

  final String asset;
  final String semanticsLabel;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final image = Semantics(
      label: semanticsLabel,
      image: true,
      child: Image.asset(
        asset,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
    );
    if (onTap == null) return image;
    return GestureDetector(onTap: onTap, child: image);
  }
}
