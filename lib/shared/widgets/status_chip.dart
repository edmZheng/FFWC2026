import 'package:flutter/material.dart';

import '../../core/utils/match_time.dart';
import '../../data/models/match.dart';

/// Small chip showing match status: 进行中 / 完场 / 日期时间.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.match});

  final Match match;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return switch (match.status) {
      MatchStatus.live => _liveChip(context, cs),
      MatchStatus.finished => _chip(
          context,
          label: '完场',
          bg: cs.secondaryContainer,
          fg: cs.onSecondaryContainer,
        ),
      MatchStatus.notStarted => _chip(
          context,
          label: match.localDate != null ? _fmt(match.localDate!) : '待定',
          bg: cs.surfaceContainerHighest,
          fg: cs.onSurface,
        ),
    };
  }

  String _fmt(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$m/$d $h:$min';
  }

  Widget _liveChip(BuildContext context, ColorScheme cs) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: cs.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: cs.onError,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              MatchTime.chineseStatus(match.status, match.timeElapsed),
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: cs.onError, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );

  Widget _chip(BuildContext context,
          {required String label, required Color bg, required Color fg}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: fg, fontWeight: FontWeight.bold),
        ),
      );
}
