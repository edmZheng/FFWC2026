import 'package:flutter/material.dart';

import '../../data/models/match.dart';

/// Displays the match score or a separator for unstarted matches.
class ScorePill extends StatelessWidget {
  const ScorePill({
    super.key,
    required this.match,
    this.style,
  });

  final Match match;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = style ??
        Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold);

    if (match.status == MatchStatus.notStarted) {
      return Text('vs', style: base?.copyWith(color: cs.outline));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${match.homeScore}', style: base),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('–', style: base?.copyWith(color: cs.outline)),
        ),
        Text('${match.awayScore}', style: base),
      ],
    );
  }
}
