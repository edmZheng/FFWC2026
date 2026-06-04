import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/zh_cn.dart';
import '../../data/models/group_standing.dart';
import '../../providers.dart';
import '../../shared/widgets/app_bar_title_image.dart';
import '../../shared/widgets/capsule_nav_bar.dart';
import '../../shared/widgets/edge_proximity_scale.dart';
import '../../shared/widgets/team_badge.dart';

class StandingsPage extends ConsumerWidget {
  const StandingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(standingsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const AppBarTitleImage.rank(),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: '官方规则',
            onPressed: () => context.push('/standings/rules'),
          ),
        ],
      ),
      body: async.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (standings) {
          final sorted = [...standings]
            ..sort((a, b) => a.groupName.compareTo(b.groupName));
          return RefreshIndicator(
            onRefresh: () => ref.read(worldCupDataProvider.notifier).refresh(),
            child: sorted.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.4,
                        child: const Center(child: Text('暂无积分数据')),
                      ),
                    ],
                  )
                : GridView.builder(
                    clipBehavior: Clip.none,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      CapsuleNavMetrics.bottomInset(context),
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      mainAxisExtent: 200,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: sorted.length,
                    itemBuilder: (_, i) {
                      final g = sorted[i];
                      return _GroupPreviewCard(
                        standing: g,
                        onTap: () => context.push('/group/${g.groupName}'),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

class _GroupPreviewCard extends StatelessWidget {
  const _GroupPreviewCard({required this.standing, required this.onTap});

  final GroupStanding standing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final preview = standing.teams.take(4).toList();

    return EdgeProximityScale(
      child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${standing.groupName} 组',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < preview.length; i++)
                      Expanded(
                        child: _previewRow(context, i + 1, preview[i]),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _previewRow(BuildContext context, int rank, TeamStanding s) {
    final name = ZhCn.teamNameEn(s.teamNameEn);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text(
              '$rank',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          TeamBadge(
            iso2: s.teamIso2,
            fifaCode: s.teamFifaCode,
            flagUrl: s.teamFlagUrl,
            size: 22,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${s.pts}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}
