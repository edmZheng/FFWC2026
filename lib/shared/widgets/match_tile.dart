import 'package:flutter/material.dart';

import '../../core/utils/match_time.dart';
import '../../data/models/match.dart';
import 'score_pill.dart';
import 'status_chip.dart';
import 'team_badge.dart';

/// Match row used in schedule and live lists, themed for the FIFA World Cup UI.
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _teamCell(
                          context,
                          match.homeDisplayName,
                          match.homeTeam?.iso2 ?? '',
                          match.homeTeam?.flagUrl ?? '',
                          TextAlign.left,
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Center(child: ScorePill(match: match)),
                      ),
                      Expanded(
                        child: _teamCell(
                          context,
                          match.awayDisplayName,
                          match.awayTeam?.iso2 ?? '',
                          match.awayTeam?.flagUrl ?? '',
                          TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          _stageLabel(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: cs.outline,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      StatusChip(match: match),
                    ],
                  ),
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
    String flagUrl,
    TextAlign align,
  ) {
    final badge = TeamBadge(iso2: iso2, flagUrl: flagUrl, size: 36);
    final label = Expanded(
      child: Text(
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
    );
    final children = align == TextAlign.left
        ? [badge, const SizedBox(width: 8), label]
        : [label, const SizedBox(width: 8), badge];
    return Row(
      mainAxisAlignment:
          align == TextAlign.left ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: children,
    );
  }

  String _stageLabel() {
    if (match.stage == MatchStage.group && match.group.isNotEmpty) {
      return '小组${match.group} · 第${match.matchday}轮';
    }
    return MatchTime.chineseStage(match.stage.label);
  }
}
