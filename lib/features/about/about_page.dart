import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/mono_palette.dart';
import '../../shared/widgets/app_bar_title_image.dart';
import '../../shared/widgets/capsule_nav_bar.dart';

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
    final mono = Theme.of(context).extension<MonoTokens>() ?? MonoTokens.dark;
    final bottom = CapsuleNavMetrics.bottomInset(context) + 16;

    return Scaffold(
      appBar: AppBar(
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
          _SectionLabel(label: '本应用实时数据来自以下开源接口', cs: cs),
          const SizedBox(height: 8),
          _InfoCard(
            mono: mono,
            cs: cs,
            children: [
              _DataRow(
                icon: Icons.code_rounded,
                title: 'rezarahiminia/worldcup2026',
                subtitle: '赛程 · 比分 · 球队 · 场馆  |  GitHub 开源项目',
                cs: cs,
              ),
              _Divider(cs: cs),
              _DataRow(
                icon: Icons.sports_soccer_rounded,
                title: 'Highlightly Soccer API',
                subtitle: '首发阵容 · 阵型  |  Basic Free 接口',
                cs: cs,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 联系 ─────────────────────────────────────
          _SectionLabel(label: '联系', cs: cs),
          const SizedBox(height: 8),
          _InfoCard(
            mono: mono,
            cs: cs,
            children: [
              _TapRow(
                icon: Icons.mail_outline_rounded,
                label: '反馈邮箱',
                value: _email,
                cs: cs,
                onTap: () => _copyToClipboard(context, _email, '邮箱地址'),
              ),
              _Divider(cs: cs),
              _TapRow(
                icon: Icons.link_rounded,
                imagePath: 'assets/icon/github.png',
                label: '项目地址',
                value: 'edmZheng/FFWC2026',
                cs: cs,
                onTap: () => _copyToClipboard(context, _projectUrl, '项目链接'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 隐私说明 ──────────────────────────────────
          _SectionLabel(label: '隐私说明', cs: cs),
          const SizedBox(height: 8),
          _InfoCard(
            mono: mono,
            cs: cs,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Text(
                  'FFWC2026 不收集任何个人信息。赛程数据由第三方开源接口提供；'
                  '首发阵容通过 Cloudflare Worker 转发自 Highlightly API，'
                  '所有数据仅在本地缓存，不会上传至任何服务器。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
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
      decoration: BoxDecoration(
        color: mono.glassFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mono.glassBorder),
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
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '随手浏览实时世界杯赛程、积分榜信息',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
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
                      color: cs.onSurfaceVariant,
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.mono, required this.cs, required this.children});
  final MonoTokens mono;
  final ColorScheme cs;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: mono.cardBorder),
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
    required this.cs,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
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
    required this.cs,
    required this.onTap,
    this.imagePath,
  });
  final IconData icon;
  final String? imagePath;
  final String label;
  final String value;
  final ColorScheme cs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                color: isDark ? Colors.white.withOpacity(0.6) : cs.onSurfaceVariant,
              )
            else
              Icon(icon, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.copy_rounded, size: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 46,
      endIndent: 0,
      color: cs.outlineVariant.withValues(alpha: 0.5),
    );
  }
}
