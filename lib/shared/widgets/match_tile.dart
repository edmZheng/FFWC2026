import 'package:flutter/material.dart';

import '../../core/l10n/zh_cn.dart';
import '../../core/utils/match_time.dart';
import '../../data/models/match.dart';
import 'score_pill.dart';
import 'status_chip.dart';
import 'team_badge.dart';

/// 赛程卡片：轮次在 VS 上方，开赛时间在 VS 下方。
class MatchTile extends StatelessWidget {
  const MatchTile({
    super.key,
    required this.match,
    this.onTap,
  });

  final Match match;
  final VoidCallback? onTap;

  static const double _radius = 16;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLive = match.status == MatchStatus.live;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: cs.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
        side: BorderSide(color: cs.primary.withValues(alpha: 0.15)),
      ),
      clipBehavior: Clip.antiAlias,
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
                                    color: cs.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            ScorePill(match: match),
                            const SizedBox(height: 6),
                            Text(
                              match.localDate != null
                                  ? MatchTime.formatChineseDateTime(match.localDate!)
                                  : '时间待定',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
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
                    color: cs.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
