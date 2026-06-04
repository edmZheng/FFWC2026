import 'package:flutter/material.dart';

/// AppBar 居中标题图（FWC 品牌 + 页名横幅）。
class AppBarTitleImage extends StatelessWidget {
  const AppBarTitleImage({
    super.key,
    required this.asset,
    required this.semanticsLabel,
    this.height = 30,
  });

  const AppBarTitleImage.games({super.key, this.height = 30})
      : asset = 'assets/titles/games.png',
        semanticsLabel = '赛程';

  const AppBarTitleImage.rank({super.key, this.height = 30})
      : asset = 'assets/titles/rank.png',
        semanticsLabel = '积分榜';

  const AppBarTitleImage.teams({super.key, this.height = 30})
      : asset = 'assets/titles/teams.png',
        semanticsLabel = '球队';

  const AppBarTitleImage.stadium({super.key, this.height = 30})
      : asset = 'assets/titles/stadium.png',
        semanticsLabel = '场馆';

  final String asset;
  final String semanticsLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      image: true,
      child: Image.asset(
        asset,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
