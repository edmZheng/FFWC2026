import 'package:flutter/material.dart';

import '../../core/theme/mono_palette.dart';
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
    final cs = theme.colorScheme;
    final mono = theme.extension<MonoTokens>() ?? MonoTokens.dark;
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(height: 1.55);
    final bulletStyle = bodyStyle;

    return DetailScaffold(
      title: const Text('规则须知'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ── 头部 ─────────────────────────────────────
          _buildHeader(context, cs, mono),
          const SizedBox(height: 20),

          // ── 赛事概览 ──────────────────────────────────
          _SectionLabel(label: '赛事概览', cs: cs),
          const SizedBox(height: 8),
          _RuleCard(
            mono: mono,
            cs: cs,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '本届为史上首次 48 队参赛，分 12 个小组（A–L），每组 4 队。'
                    '共 104 场比赛：小组赛 72 场，淘汰赛 32 场。',
                    style: bodyStyle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '揭幕战 2026 年 6 月 11 日（墨西哥城）；决赛 2026 年 7 月 19 日（纽约/新泽西）。',
                    style: bodyStyle,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── 小组赛 ────────────────────────────────────
          _SectionLabel(label: '小组赛', cs: cs),
          const SizedBox(height: 8),
          _RuleCard(
            mono: mono,
            cs: cs,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '每队与同组另外 3 队各踢 1 场，共 3 场。胜 3 分、平 1 分、负 0 分。',
                    style: bodyStyle,
                  ),
                  const SizedBox(height: 8),
                  _bulletItem('每组前 2 名直接晋级 32 强；', bulletStyle),
                  _bulletItem(
                    '12 个小组第 3 名中成绩最好的 8 队同样晋级（另 4 支第 3 名出局）。',
                    bulletStyle,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── 同组积分相同 ──────────────────────────────
          _SectionLabel(label: '同组积分相同 — 排名依据', cs: cs),
          const SizedBox(height: 8),
          _RuleCard(
            mono: mono,
            cs: cs,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('若小组内两队或多队积分相同，按下列顺序判定名次：', style: bodyStyle),
                  const SizedBox(height: 10),
                  _numberedBlock(context, '第一步（仅计相关球队之间的对赛）', const [
                    '相互间比赛积分多者靠前；',
                    '相互间净胜球多者靠前；',
                    '相互间进球多者靠前。',
                  ], bodyStyle),
                  const SizedBox(height: 8),
                  _numberedBlock(context, '第二步（仍无法区分时）', const [
                    '全部 3 场小组赛的净胜球多者靠前；',
                    '全部 3 场小组赛进球多者靠前；',
                    '公平竞赛积分更高者靠前（黄、红牌越少越好）。',
                  ], bodyStyle),
                  const SizedBox(height: 8),
                  _numberedBlock(context, '第三步', const [
                    '按最新公布的 FIFA/Coca-Cola 男足世界排名决定先后。',
                  ], bodyStyle),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── 最佳第三名 ────────────────────────────────
          _SectionLabel(label: '最佳第三名 — 8 席选拔', cs: cs),
          const SizedBox(height: 8),
          _RuleCard(
            mono: mono,
            cs: cs,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '12 个小组第三名单独横向比较，取成绩最好的 8 队，按下列顺序排名：',
                    style: bodyStyle,
                  ),
                  const SizedBox(height: 8),
                  _bulletItem('全部 3 场小组赛积分；', bulletStyle),
                  _bulletItem('全部 3 场小组赛净胜球；', bulletStyle),
                  _bulletItem('全部 3 场小组赛进球数；', bulletStyle),
                  _bulletItem('公平竞赛积分；', bulletStyle),
                  _bulletItem('FIFA/Coca-Cola 男足世界排名。', bulletStyle),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── 淘汰赛 ────────────────────────────────────
          _SectionLabel(label: '淘汰赛', cs: cs),
          const SizedBox(height: 8),
          _RuleCard(
            mono: mono,
            cs: cs,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '32 强起为单场淘汰：胜者晋级，负者出局。'
                    '轮次依次为 32 强 → 16 强 → 8 强 → 半决赛 → 三四名决赛 → 决赛。',
                    style: bodyStyle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '32 强对阵在小组赛全部结束后，根据各队最终名次按赛事规程预设的对阵表确定；'
                    '首轮淘汰赛原则上不安排同组球队再次相遇。',
                    style: bodyStyle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '进入决赛的两支球队本届各需踢满 8 场比赛（含小组赛 3 场），为扩军赛制下的新纪录。',
                    style: bodyStyle,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── 来源注 ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _sourceNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme cs, MonoTokens mono) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: mono.glassFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mono.glassBorder),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/icon/fifa_wc26_logo.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 14),
          Text(
            '2026年美加墨世界杯',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            '规则须知',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _bulletItem(String text, TextStyle? style) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: style),
          Expanded(child: Text(text, style: style)),
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
    final subtitleStyle =
        Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600);
    return Column(
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
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.cs});
  final String label;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.mono, required this.cs, required this.child});
  final MonoTokens mono;
  final ColorScheme cs;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: mono.cardBorder),
      ),
      child: child,
    );
  }
}
