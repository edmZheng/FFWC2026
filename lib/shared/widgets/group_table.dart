import 'package:flutter/material.dart';

import '../../core/l10n/zh_cn.dart';
import '../../data/models/group_standing.dart';
import 'team_badge.dart';

/// 单组积分榜表格。
class GroupTable extends StatelessWidget {
  const GroupTable({
    super.key,
    required this.standing,
    this.showTitle = true,
  });

  final GroupStanding standing;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(
              '${standing.groupName} 组',
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
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
            ...standing.teams.asMap().entries.map(
                  (e) => _row(context, e.key + 1, e.value, cs, tt),
                ),
          ],
        ),
      ],
    );
  }

  TableRow _header(ColorScheme cs, TextTheme tt) => TableRow(
        decoration: BoxDecoration(color: cs.surfaceContainerHighest),
        children: ['#', '球队', '场', '胜', '平', '负', '净', '进', '积']
            .map((h) => _hCell(h, tt, cs))
            .toList(),
      );

  Widget _hCell(String text, TextTheme tt, ColorScheme cs) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: tt.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
        ),
      );

  TableRow _row(
    BuildContext ctx,
    int pos,
    TeamStanding s,
    ColorScheme cs,
    TextTheme tt,
  ) {
    final qualifies = pos <= 2;
    final name = s.teamNameEn.isNotEmpty
        ? ZhCn.teamNameEn(s.teamNameEn)
        : s.teamId;
    return TableRow(
      decoration: BoxDecoration(
        color: qualifies ? cs.surfaceContainerHighest : Colors.transparent,
      ),
      children: [
        _cell('$pos', tt),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              TeamBadge(
                iso2: s.teamIso2,
                fifaCode: s.teamFifaCode,
                flagUrl: s.teamFlagUrl,
                size: 18,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  name,
                  style: tt.labelSmall,
                  overflow: TextOverflow.ellipsis,
                ),
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
        _cell(
          '${s.pts}',
          tt,
          style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _cell(String text, TextTheme tt, {TextStyle? style}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: style ?? tt.labelSmall,
        ),
      );
}
