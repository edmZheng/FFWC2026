import 'package:flutter/material.dart';

/// 滚动列表顶边：仅对子树做 alpha 渐隐，不铺实色底。
///
/// 用于英雄头图等全宽背景场景——底层皮肤可透出，卡片离屏时在该带内淡出，
/// 而非被 [Scaffold] 底色盖住。
class ScrollViewportTopFade extends StatelessWidget {
  const ScrollViewportTopFade({
    super.key,
    required this.child,
    this.top = 0,
    this.fadeHeight = 40,
  });

  final Widget child;

  /// 渐隐起点距子树顶部的偏移（赛程页 = 固定顶区 [DetailFixedHeaderBody] 高度，
  /// 与英雄头图过渡到内容的交界线对齐）。
  final double top;
  final double fadeHeight;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        final h = bounds.height;
        if (h <= 0) {
          return const LinearGradient(
            colors: [Colors.white, Colors.white],
          ).createShader(bounds);
        }

        final t0 = (top / h).clamp(0.0, 1.0);
        final t1 = ((top + fadeHeight) / h).clamp(t0, 1.0);

        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Colors.transparent,
            Colors.transparent,
            Colors.white,
            Colors.white,
          ],
          stops: [0, t0, t1, 1.0],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}
