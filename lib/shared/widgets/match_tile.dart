import 'package:flutter/material.dart';

import '../../core/l10n/zh_cn.dart';
import '../../core/theme/mono_palette.dart';
import '../../core/utils/match_time.dart';
import '../../data/models/match.dart';
import 'edge_proximity_scale.dart';
import 'score_pill.dart';
import 'stacked_edge_fade.dart';
import 'status_chip.dart';
import 'team_badge.dart';

/// 赛程卡片：轮次在 VS 上方，开赛时间在 VS 下方。
class MatchTile extends StatefulWidget {
  const MatchTile({
    super.key,
    required this.match,
    required this.kickoffText,
    this.onTap,
    this.bottomFadeInset,
  });

  final Match match;
  final String kickoffText;
  final VoidCallback? onTap;

  /// 非 null 时：顶部由 [EdgeProximityScale](verticalTopOnly) 简单缩小，
  /// 底部由 [StackedEdgeFade] 在 viewport.bottom - bottomFadeInset 处
  /// "压栈"（硬停 + 缩 + 淡 + ZSortedSliverList 修 z-order）。
  /// 仅 schedule_page 使用；null 时退回原 EdgeProximityScale(vertical) 行为。
  final double? bottomFadeInset;

  static const double _baseRadius = 10;
  static const double _maxRadius = 36;

  @override
  State<MatchTile> createState() => _MatchTileState();
}

class _MatchTileState extends State<MatchTile> {
  double _progress = 0.0;

  void _onProgress(double p) {
    if (mounted && (p - _progress).abs() > 0.001) {
      setState(() => _progress = p);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLive = widget.match.status == MatchStatus.live;

    final radius = widget.bottomFadeInset != null
        ? MatchTile._baseRadius +
            (MatchTile._maxRadius - MatchTile._baseRadius) * _progress
        : MatchTile._baseRadius;

    final card = Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: cs.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(
            color: Theme.of(context).extension<MonoTokens>()?.cardBorder ??
                cs.outlineVariant,
          ),
        ),
        clipBehavior: Clip.none,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _teamCell(
                            context,
                            ZhCn.matchHomeName(widget.match),
                            widget.match.homeTeam?.iso2 ?? '',
                            widget.match.homeTeam?.fifaCode ?? '',
                            widget.match.homeTeam?.flagUrl ?? '',
                            TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          width: 108,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _roundLabel(),
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      letterSpacing: 0.02,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              ScorePill(match: widget.match),
                              const SizedBox(height: 6),
                              Text(
                                widget.kickoffText,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: cs.onSurface,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _teamCell(
                            context,
                            ZhCn.matchAwayName(widget.match),
                            widget.match.awayTeam?.iso2 ?? '',
                            widget.match.awayTeam?.fifaCode ?? '',
                            widget.match.awayTeam?.flagUrl ?? '',
                            TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    if (widget.match.status != MatchStatus.notStarted) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child:
                            StatusChip(match: widget.match, showTime: false),
                      ),
                    ],
                  ],
                ),
              ),
              if (isLive)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ));

    final bottomInset = widget.bottomFadeInset;
    if (bottomInset != null) {
      return StackedEdgeFade(
        bottomInset: bottomInset,
        onProgressChanged: _onProgress,
        child: EdgeProximityScale(
          axis: EdgeScaleAxis.verticalTopOnly,
          child: card,
        ),
      );
    }
    return EdgeProximityScale(
      axis: EdgeScaleAxis.vertical,
      child: card,
    );
  }

  Widget _teamCell(
    BuildContext ctx,
    String name,
    String iso2,
    String fifaCode,
    String flagUrl,
    TextAlign align,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TeamBadge(iso2: iso2, fifaCode: fifaCode, flagUrl: flagUrl, size: 40),
        const SizedBox(height: 8),
        Text(
          name,
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
          textAlign: align,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _roundLabel() {
    if (widget.match.stage == MatchStage.group &&
        widget.match.group.isNotEmpty) {
      return '${widget.match.group}组 · 第${widget.match.matchday}轮';
    }
    return MatchTime.chineseStage(widget.match.stage.label);
  }
}
