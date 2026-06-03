import 'package:flutter/material.dart';

import '../../data/models/match.dart';

/// Displays the match score or a "VS" separator for unstarted matches.
class ScorePill extends StatelessWidget {
  const ScorePill({
    super.key,
    required this.match,
    this.style,
  });

  final Match match;

  /// Optional override for the score text style (used by the detail page for a
  /// larger display). When null, the default match-tile sizing is applied.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (match.status == MatchStatus.notStarted) {
      return Text(
        'VS',
        style: (style ?? const TextStyle()).copyWith(
          fontSize: style?.fontSize ?? 22,
          fontWeight: FontWeight.bold,
          color: cs.primary,
        ),
      );
    }

    final scoreStyle = (style ?? const TextStyle()).copyWith(
      fontSize: style?.fontSize ?? 28,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${match.homeScore}', style: scoreStyle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '-',
            style: (style ?? const TextStyle()).copyWith(
              fontSize: style?.fontSize ?? 28,
              fontWeight: FontWeight.bold,
              color: match.status == MatchStatus.live ? cs.primary : cs.outline,
            ),
          ),
        ),
        Text('${match.awayScore}', style: scoreStyle),
      ],
    );
  }
}
