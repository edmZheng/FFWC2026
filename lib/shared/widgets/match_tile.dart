import 'package:flutter/material.dart';

import '../../data/models/match.dart';
import 'score_pill.dart';
import 'status_chip.dart';
import 'team_badge.dart';

/// Compact match row used in schedule and live lists.
class MatchTile extends StatelessWidget {
  const MatchTile({
    super.key,
    required this.match,
    this.onTap,
  });

  final Match match;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _teamCell(context, match.homeDisplayName,
                      match.homeTeam?.flagUrl ?? '', TextAlign.left)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ScorePill(match: match),
                  ),
                  Expanded(child: _teamCell(context, match.awayDisplayName,
                      match.awayTeam?.flagUrl ?? '', TextAlign.right)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _stageLabel(),
                    style: tt.labelSmall
                        ?.copyWith(color: Theme.of(context).colorScheme.outline),
                  ),
                  StatusChip(match: match),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamCell(BuildContext ctx, String name, String flag, TextAlign align) {
    final children = [
      TeamBadge(flagUrl: flag, size: 28),
      const SizedBox(width: 6),
      Expanded(
        child: Text(name,
            style: Theme.of(ctx).textTheme.bodyMedium,
            textAlign: align,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ),
    ];
    return Row(
      mainAxisAlignment: align == TextAlign.left
          ? MainAxisAlignment.start
          : MainAxisAlignment.end,
      children: align == TextAlign.left ? children : children.reversed.toList(),
    );
  }

  String _stageLabel() {
    if (match.stage == MatchStage.group && match.group.isNotEmpty) {
      return 'Group ${match.group}  ·  MD${match.matchday}';
    }
    return match.stage.label;
  }
}
