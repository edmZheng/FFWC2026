import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/mono_palette.dart';

/// 底部悬浮胶囊导航尺寸（液态玻璃 Tab，独立浮层不占位）。
abstract final class CapsuleNavMetrics {
  static const navHeight = 64.0;
  static const navMarginB = 28.0;
  static const capsuleWidthFactor = 0.72;

  static double capsuleWidth(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return (screenWidth * capsuleWidthFactor).clamp(268.0, screenWidth - 48);
  }

  static double bottomInset(BuildContext context) {
    return navHeight + navMarginB + MediaQuery.paddingOf(context).bottom;
  }
}

/// 液态玻璃胶囊底栏（Mono 炭蓝单色相）。
class CapsuleNavBar extends StatelessWidget {
  const CapsuleNavBar({
    super.key,
    required this.selectedIndex,
    required this.tabs,
    required this.onTap,
    this.scheduleScrollToTop = false,
  });

  final int selectedIndex;
  final List<(IconData, IconData, String)> tabs;
  final ValueChanged<int> onTap;

  /// 赛程 tab 处于「回顶部」模式（仅 selectedIndex==0 时生效）。
  final bool scheduleScrollToTop;

  static const _scheduleTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mono = Theme.of(context).extension<MonoTokens>() ?? MonoTokens.dark;
    final activeColor = cs.onSurface;
    final inactiveColor = cs.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: mono.shadow,
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: mono.glassFill,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: mono.glassBorder, width: 1),
            ),
            child: Row(
              children: List.generate(tabs.length, (i) {
                final selected = selectedIndex == i;
                final color = selected ? activeColor : inactiveColor;
                final showScrollTop = scheduleScrollToTop &&
                    selected &&
                    i == _scheduleTabIndex;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (showScrollTop)
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: color, width: 1.5),
                            ),
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              size: 14,
                              color: color,
                            ),
                          )
                        else
                          Icon(
                            selected ? tabs[i].$2 : tabs[i].$1,
                            size: 20,
                            color: color,
                          ),
                        const SizedBox(height: 2),
                        Text(
                          showScrollTop ? '回顶部' : tabs[i].$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 0.02,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
