import 'package:flutter/material.dart';

import '../../data/models/group_standing.dart';
import 'team_badge.dart';

/// Full standings table for a single group.
class GroupTable extends StatelessWidget {
  const GroupTable({super.key, required this.standing});

  final GroupStanding standing;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Text('Group ${standing.groupName}',
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        ),
        Table(
          columnWidths: const {
            0: FixedColumnWidth(24),
            1: FlexColumnWidth(3),
            2: FixedColumnWidth(30),
            3: FixedColumnWidth(30),
            4: FixedColumnWidth(30),
            5: FixedColumnWidth(30),
            6: FixedColumnWidth(30),
            7: FixedColumnWidth(30),
            8: FixedColumnWidth(36),
          },
          children: [
            _header(cs, tt),
            ...standing.teams.asMap().entries.map((e) =>
                _row(context, e.key + 1, e.value, cs, tt)),
          ],
        ),
      ],
    );
  }

  TableRow _header(ColorScheme cs, TextTheme tt) => TableRow(
        decoration: BoxDecoration(color: cs.surfaceContainerHighest),
        children: ['#', 'Team', 'MP', 'W', 'D', 'L', 'GD', 'GF', 'PTS']
            .map((h) => _hCell(h, tt, cs))
            .toList(),
      );

  Widget _hCell(String text, TextTheme tt, ColorScheme cs) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Text(text,
            textAlign: TextAlign.center,
            style: tt.labelSmall?.copyWith(
                fontWeight: FontWeight.bold, color: cs.onSurfaceVariant)),
      );

  TableRow _row(BuildContext ctx, int pos, TeamStanding s,
      ColorScheme cs, TextTheme tt) {
    final qualifies = pos <= 2; // top 2 advance from group
    return TableRow(
      decoration: BoxDecoration(
        color: qualifies
            ? cs.primaryContainer.withAlpha(77)
            : Colors.transparent,
      ),
      children: [
        _cell('$pos', tt),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              TeamBadge(flagUrl: s.teamFlagUrl, size: 18),
              const SizedBox(width: 4),
              Expanded(
                child: Text(s.teamNameEn.isNotEmpty ? s.teamNameEn : s.teamId,
                    style: tt.labelSmall,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        _cell('${s.mp}', tt),
        _cell('${s.w}', tt),
        _cell('${s.d}', tt),
        _cell('${s.l}', tt),
        _cell('${s.gd >= 0 ? '+' : ''}${s.gd}', tt),
        _cell('${s.gf}', tt),
        _cell('${s.pts}', tt,
            style: tt.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _cell(String text, TextTheme tt, {TextStyle? style}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child:
            Text(text, textAlign: TextAlign.center, style: style ?? tt.labelSmall),
      );
}
