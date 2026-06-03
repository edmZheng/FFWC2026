import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/zh_cn.dart';
import '../../data/models/group_standing.dart';
import '../../providers.dart';
import '../../shared/widgets/team_badge.dart';

class StandingsPage extends ConsumerWidget {
  const StandingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(standingsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('积分榜'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(worldCupDataProvider.notifier).refresh(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (standings) {
          if (standings.isEmpty) {
            return const Center(child: Text('暂无积分数据'));
          }
          final sorted = [...standings]
            ..sort((a, b) => a.groupName.compareTo(b.groupName));
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisExtent: 200,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: sorted.length,
            itemBuilder: (_, i) {
              final g = sorted[i];
              return _GroupPreviewCard(
                standing: g,
                onTap: () => context.push('/group/${g.groupName}'),
              );
            },
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
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
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
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
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }
}
