import 'package:flutter/material.dart';

import '../../core/l10n/zh_cn.dart';
import '../../core/theme/mono_palette.dart';
import '../../core/utils/match_time.dart';
import '../../data/models/match.dart';
import 'edge_proximity_scale.dart';
import 'score_pill.dart';
import 'stacked_edge_fade.dart';
import 'team_badge.dart';

/// 赛程卡片：顶行轮次/时间或状态，下方横向队徽·队名与比分。
class MatchTile extends StatefulWidget {
  const MatchTile({
    super.key,
    required this.match,
    required this.kickoffText,
    this.onTap,
    this.bottomFadeInset,
    this.hideDateInMeta = false,
  });

  final Match match;
  final String kickoffText;
  final VoidCallback? onTap;

  /// 为 true 时顶行左侧仅显示轮次/小组，日期由外层日标题承担。
  final bool hideDateInMeta;

  /// 非 null 时：顶部由 [EdgeProximityScale](verticalTopOnly) 触边即缩+淡
  /// （底边锚定、顶边贴 viewport、与下一张间距不变），
  /// 底部由 [StackedEdgeFade] 在 viewport.bottom - bottomFadeInset 处
  /// "压栈"（硬停 + 缩 + 淡 + ZSortedSliverList 修 z-order）。
  /// 仅 schedule_page 使用；null 时退回原 EdgeProximityScale(vertical) 行为。
  final double? bottomFadeInset;

  static const double _baseRadius = 10;
  static const double _maxRadius = 36;

  static const _metaStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  static const _scoreStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
    fontFeatures: [FontFeature.tabularFigures()],
  );

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
    final mono = MonoTokens.of(context);
    final isLive = widget.match.status == MatchStatus.live;

    final radius = widget.bottomFadeInset != null
        ? MatchTile._baseRadius +
            (MatchTile._maxRadius - MatchTile._baseRadius) * _progress
        : MatchTile._baseRadius;

    final cardColor = isLive
        ? Color.alphaBlend(cs.primary.withValues(alpha: 0.10), mono.cardFill)
        : mono.cardFill;

    final card = Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      color: cardColor,
      shape: mono.cardShape(borderRadius: BorderRadius.circular(radius)),
      clipBehavior: Clip.none,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _metaLeft(context)),
                  const SizedBox(width: 8),
                  _metaRight(context),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _teamRowCell(
                      context,
                      name: ZhCn.matchHomeName(widget.match),
                      iso2: widget.match.homeTeam?.iso2 ?? '',
                      fifaCode: widget.match.homeTeam?.fifaCode ?? '',
                      flagUrl: widget.match.homeTeam?.flagUrl ?? '',
                      home: true,
                    ),
                  ),
                  SizedBox(
                    width: 52,
                    child: Center(
                      child: ScorePill(
                        match: widget.match,
                        style: MatchTile._scoreStyle.copyWith(
                          color: widget.match.status == MatchStatus.notStarted
                              ? mono.textSecondary
                              : mono.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _teamRowCell(
                      context,
                      name: ZhCn.matchAwayName(widget.match),
                      iso2: widget.match.awayTeam?.iso2 ?? '',
                      fifaCode: widget.match.awayTeam?.fifaCode ?? '',
                      flagUrl: widget.match.awayTeam?.flagUrl ?? '',
                      home: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

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

  Widget _metaLeft(BuildContext context) {
    final mono = MonoTokens.of(context);
    final groupLabel = _groupShort();
    final dateLabel = widget.hideDateInMeta ? null : _dateLabel();
    final text =
        dateLabel != null ? '$dateLabel · $groupLabel' : groupLabel;

    return Text(
      text,
      style: MatchTile._metaStyle.copyWith(color: mono.textSecondary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _metaRight(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mono = MonoTokens.of(context);
    return switch (widget.match.status) {
      MatchStatus.live => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              MatchTime.chineseStatus(
                widget.match.status,
                widget.match.timeElapsed,
              ),
              style: MatchTile._metaStyle.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      MatchStatus.finished => Text(
          '完场',
          style: MatchTile._metaStyle.copyWith(color: mono.textSecondary),
        ),
      MatchStatus.notStarted => Text(
          _timeOnly(),
          style: MatchTile._metaStyle.copyWith(color: mono.textSecondary),
        ),
    };
  }

  Widget _teamRowCell(
    BuildContext context, {
    required String name,
    required String iso2,
    required String fifaCode,
    required String flagUrl,
    required bool home,
  }) {
    final mono = MonoTokens.of(context);
    final badge = TeamBadge(iso2: iso2, fifaCode: fifaCode, flagUrl: flagUrl, size: 28);
    final label = Text(
      name,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: mono.textPrimary,
          ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: home ? TextAlign.left : TextAlign.right,
    );

    return Row(
      mainAxisAlignment: home ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: home
          ? [badge, const SizedBox(width: 8), Flexible(child: label)]
          : [Flexible(child: label), const SizedBox(width: 8), badge],
    );
  }

  String? _dateLabel() {
    if (widget.kickoffText == '时间待定') return null;
    final parts = widget.kickoffText.split(' ');
    final datePart = parts.isNotEmpty ? parts.first : widget.kickoffText;
    final weekday = _weekdayLabel();
    if (weekday != null) return '$datePart $weekday';
    return datePart;
  }

  String? _weekdayLabel() {
    final d = widget.match.localDate;
    if (d == null) return null;
    const days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return days[d.weekday - 1];
  }

  String _timeOnly() {
    if (widget.kickoffText == '时间待定') return widget.kickoffText;
    final parts = widget.kickoffText.split(' ');
    if (parts.length >= 2) return parts[1];
    return widget.kickoffText;
  }

  String _groupShort() {
    if (widget.match.stage == MatchStage.group &&
        widget.match.group.isNotEmpty) {
      return '${widget.match.group} 组';
    }
    return MatchTime.chineseStage(widget.match.stage.label);
  }
}
