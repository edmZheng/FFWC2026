import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/mono_palette.dart';
import '../../shared/widgets/app_bar_title_image.dart';
import '../../shared/widgets/capsule_nav_bar.dart';
import '../../shared/widgets/shell_hero_scaffold.dart';
import '../../shared/widgets/world_cup_hero_skin.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final _scrollController = ScrollController();

  static const _email = 'edm_zheng@163.com';
  static const _projectUrl = 'https://github.com/edmZheng/FFWC2026';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic);
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已复制$label'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mono = Theme.of(context).extension<MonoTokens>() ?? MonoTokens.of(context);
    final bottom = CapsuleNavMetrics.bottomInset(context) + 16;

    return ShellHeroScaffold(
      tab: WorldCupTab.about,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: AppBarTitleImage.about(onTap: _scrollToTop),
      ),
      body: ListView(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottom),
        children: [
          // ── 头部 ──────────────────────────────────────
          _HeaderCard(cs: cs, mono: mono),
          const SizedBox(height: 16),

          // ── 实时数据来源 ──────────────────────────────
          _SectionLabel(label: '本应用实时数据来自以下开源接口', mono: mono),
          const SizedBox(height: 8),
          _InfoCard(
            mono: mono,
            cs: cs,
            children: [
              _DataRow(
                icon: Icons.code_rounded,
                title: 'rezarahiminia/worldcup2026',
                subtitle: '赛程 · 比分 · 球队 · 场馆  |  GitHub 开源项目',
                mono: mono,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 联系 ─────────────────────────────────────
          _SectionLabel(label: '联系', mono: mono),
          const SizedBox(height: 8),
          _InfoCard(
            mono: mono,
            cs: cs,
            children: [
              _TapRow(
                icon: Icons.mail_outline_rounded,
                label: '反馈邮箱',
                value: _email,
                mono: mono,
                onTap: () => _copyToClipboard(context, _email, '邮箱地址'),
              ),
              _Divider(mono: mono),
              _TapRow(
                icon: Icons.link_rounded,
                imagePath: 'assets/icon/github.png',
                label: '项目地址',
                value: 'edmZheng/FFWC2026',
                mono: mono,
                onTap: () => _copyToClipboard(context, _projectUrl, '项目链接'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 隐私说明 ──────────────────────────────────
          _SectionLabel(label: '隐私说明', mono: mono),
          const SizedBox(height: 8),
          _InfoCard(
            mono: mono,
            cs: cs,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Text(
                  'FFWC2026 不收集任何个人信息。赛程数据由第三方开源接口提供，'
                  '所有数据仅在本地缓存，不会上传至任何服务器。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: mono.textPrimary,
                        height: 1.6,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.cs, required this.mono});
  final ColorScheme cs;
  final MonoTokens mono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: mono.surfaceDecoration(
        color: mono.glassFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FFWC2026',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: mono.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '随手浏览实时世界杯赛程、积分榜信息',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: mono.textSecondary,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: mono.glassBorder),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '开发者：郑伟男（EDMZheng）',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: mono.textSecondary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.mono});
  final String label;
  final MonoTokens mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: mono.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.mono, required this.cs, required this.children});
  final MonoTokens mono;
  final ColorScheme cs;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: mono.surfaceDecoration(
        color: mono.cardFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.mono,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final MonoTokens mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: mono.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: mono.textPrimary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: mono.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TapRow extends StatelessWidget {
  const _TapRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.mono,
    required this.onTap,
    this.imagePath,
  });
  final IconData icon;
  final String? imagePath;
  final String label;
  final String value;
  final MonoTokens mono;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (imagePath != null)
              Image.asset(
                imagePath!,
                width: 18,
                height: 18,
                color: mono.textSecondary,
              )
            else
              Icon(icon, size: 18, color: mono.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: mono.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: mono.textPrimary,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.copy_rounded,
                size: 14, color: mono.textSecondary.withValues(alpha: 0.75)),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.mono});
  final MonoTokens mono;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 46,
      endIndent: 0,
      color: mono.textSecondary.withValues(alpha: 0.35),
    );
  }
}
