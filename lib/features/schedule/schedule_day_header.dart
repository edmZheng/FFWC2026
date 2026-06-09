import 'package:flutter/material.dart';

import '../../core/theme/mono_palette.dart';
import '../../shared/widgets/edge_proximity_scale.dart';
import '../../shared/widgets/stacked_edge_fade.dart';

/// 赛程页同日分组标题；与 [MatchTile] 共用离屏动效包装。
class ScheduleDayHeader extends StatelessWidget {
  const ScheduleDayHeader({
    super.key,
    required this.label,
    required this.bottomFadeInset,
  });

  final String label;
  final double bottomFadeInset;

  @override
  Widget build(BuildContext context) {
    final mono = MonoTokens.of(context);
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.03,
                color: mono.textPrimary,
              ),
        ),
      ),
    );

    return StackedEdgeFade(
      bottomInset: bottomFadeInset,
      child: EdgeProximityScale(
        axis: EdgeScaleAxis.verticalTopOnly,
        child: content,
      ),
    );
  }
}
