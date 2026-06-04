import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/zh_cn.dart';
import '../../core/utils/match_time.dart';
import '../../data/models/match.dart';
import '../../providers.dart';
import '../../core/theme/mono_palette.dart';
import 'edge_proximity_scale.dart';
import 'score_pill.dart';
import 'status_chip.dart';
import 'team_badge.dart';

/// 赛程卡片：轮次在 VS 上方，开赛时间在 VS 下方。
class MatchTile extends ConsumerWidget {
  const MatchTile({
    super.key,
    required this.match,
    this.onTap,
  });

  final Match match;
  final VoidCallback? onTap;

  static const double _radius = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isLive = match.status == MatchStatus.live;
    final utc = ref.watch(kickoffUtcByMatchIdProvider(match.id));
    final kickoff = utc != null
        ? MatchTime.formatBeijing(utc)
        : (match.localDate != null
            ? MatchTime.formatChineseDateTime(match.localDate!)
            : '时间待定');

    return EdgeProximityScale(
      axis: EdgeScaleAxis.vertical,
      child: Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: cs.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
        side: BorderSide(
          color: Theme.of(context).extension<MonoTokens>()?.cardBorder ??
              cs.outlineVariant,
        ),
      ),
      clipBehavior: Clip.none,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _teamCell(
                          context,
                          ZhCn.matchHomeName(match),
                          match.homeTeam?.iso2 ?? '',
                          match.homeTeam?.fifaCode ?? '',
                          match.homeTeam?.flagUrl ?? '',
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
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                    letterSpacing: 0.02,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            ScorePill(match: match),
                            const SizedBox(height: 6),
                            Text(
                              kickoff,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                          ZhCn.matchAwayName(match),
                          match.awayTeam?.iso2 ?? '',
                          match.awayTeam?.fifaCode ?? '',
                          match.awayTeam?.flagUrl ?? '',
                          TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  if (match.status != MatchStatus.notStarted) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: StatusChip(match: match, showTime: false),
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
      ),
    ),
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
    if (match.stage == MatchStage.group && match.group.isNotEmpty) {
      return '${match.group}组 · 第${match.matchday}轮';
    }
    return MatchTime.chineseStage(match.stage.label);
  }
}
