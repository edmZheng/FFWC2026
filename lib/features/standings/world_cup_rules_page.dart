import 'package:flutter/material.dart';

import '../../shared/widgets/detail_scaffold.dart';

/// 2026 美加墨世界杯官方赛制与排名规则（依据 FIFA 公布内容整理）。
class WorldCupRulesPage extends StatelessWidget {
  const WorldCupRulesPage({super.key});

  static const _sourceNote =
      '内容依据国际足联（FIFA）公布的 2026 世界杯赛制与排名规则整理，'
      '完整条文见《FIFA World Cup 2026™ Regulations》。';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(height: 1.5);
    final bulletStyle = bodyStyle;

    return DetailScaffold(
      title: const Text('官方规则'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            '2026 国际足联世界杯\n加拿大 · 墨西哥 · 美国',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle(context, '赛事概览'),
          _paragraph(
            '本届为史上首次 48 队参赛，分 12 个小组（A–L），每组 4 队。'
            '共 104 场比赛：小组赛 72 场，淘汰赛 32 场。',
            bodyStyle,
          ),
          _paragraph(
            '揭幕战 2026 年 6 月 11 日（墨西哥城）；决赛 2026 年 7 月 19 日（纽约/新泽西）。',
            bodyStyle,
          ),
          _sectionTitle(context, '小组赛'),
          _paragraph(
            '每队与同组另外 3 队各踢 1 场，共 3 场。胜 3 分、平 1 分、负 0 分。',
            bodyStyle,
          ),
          _bulletList(
            bulletStyle,
            const [
              '每组前 2 名直接晋级 32 强；',
              '12 个小组第 3 名中成绩最好的 8 队同样晋级（另 4 支第 3 名出局）。',
            ],
          ),
          _sectionTitle(context, '同组积分相同 — 排名依据'),
          _paragraph('若小组内两队或多队积分相同，按下列顺序判定名次：', bodyStyle),
          _numberedBlock(
            context,
            '第一步（仅计相关球队之间的对赛）',
            const [
              '相互间比赛积分多者靠前；',
              '相互间净胜球多者靠前；',
              '相互间进球多者靠前。',
            ],
            bodyStyle,
          ),
          _numberedBlock(
            context,
            '第二步（仍无法区分时）',
            const [
              '全部 3 场小组赛的净胜球多者靠前；',
              '全部 3 场小组赛进球多者靠前；',
              '公平竞赛积分更高者靠前（黄、红牌越少越好）。',
            ],
            bodyStyle,
          ),
          _numberedBlock(
            context,
            '第三步',
            const [
              '按最新公布的 FIFA/Coca-Cola 男足世界排名决定先后。',
            ],
            bodyStyle,
          ),
          _sectionTitle(context, '最佳第三名 — 8 席选拔'),
          _paragraph(
            '12 个小组第三名单独横向比较，取成绩最好的 8 队，按下列顺序排名：',
            bodyStyle,
          ),
          _bulletList(
            bulletStyle,
            const [
              '全部 3 场小组赛积分；',
              '全部 3 场小组赛净胜球；',
              '全部 3 场小组赛进球数；',
              '公平竞赛积分；',
              'FIFA/Coca-Cola 男足世界排名。',
            ],
          ),
          _sectionTitle(context, '淘汰赛'),
          _paragraph(
            '32 强起为单场淘汰：胜者晋级，负者出局。'
            '轮次依次为 32 强 → 16 强 → 8 强 → 半决赛 → 三四名决赛 → 决赛。',
            bodyStyle,
          ),
          _paragraph(
            '32 强对阵在小组赛全部结束后，根据各队最终名次按赛事规程预设的对阵表确定；'
            '首轮淘汰赛原则上不安排同组球队再次相遇。',
            bodyStyle,
          ),
          _paragraph(
            '进入决赛的两支球队本届各需踢满 8 场比赛（含小组赛 3 场），为扩军赛制下的新纪录。',
            bodyStyle,
          ),
          const SizedBox(height: 16),
          Text(
            _sourceNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _paragraph(String text, TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: style),
    );
  }

  Widget _bulletList(TextStyle? style, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: style),
                  Expanded(child: Text(item, style: style)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _numberedBlock(
    BuildContext context,
    String subtitle,
    List<String> items,
    TextStyle? bodyStyle,
  ) {
    final subtitleStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: subtitleStyle),
          const SizedBox(height: 4),
          ...items.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4),
              child: Text(t, style: bodyStyle),
            ),
          ),
        ],
      ),
    );
  }
}
