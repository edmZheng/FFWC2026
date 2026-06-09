import 'dart:ui';

import 'package:flutter/material.dart';

/// AppBar 居中标题图（FWC 品牌 + 页名横幅）。
///
/// 在彩色 Hero 背景上反白显示，并加柔和投影提升可读性。
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
      child: _InvertedTitleGraphic(asset: asset, height: height),
    );
    if (onTap == null) return image;
    return GestureDetector(onTap: onTap, child: image);
  }
}

class _InvertedTitleGraphic extends StatelessWidget {
  const _InvertedTitleGraphic({required this.asset, required this.height});

  final String asset;
  final double height;

  @override
  Widget build(BuildContext context) {
    final shadow = Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.55)
        : Colors.black.withValues(alpha: 0.38);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Transform.translate(
          offset: const Offset(0, 1.5),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Image.asset(
              asset,
              height: height,
              fit: BoxFit.contain,
              color: shadow,
              colorBlendMode: BlendMode.srcIn,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
        Image.asset(
          asset,
          height: height,
          fit: BoxFit.contain,
          color: Colors.white,
          colorBlendMode: BlendMode.srcIn,
          filterQuality: FilterQuality.medium,
        ),
      ],
    );
  }
}
