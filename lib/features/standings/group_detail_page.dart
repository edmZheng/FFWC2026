import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/match.dart';
import '../../providers.dart';
import '../../shared/widgets/detail_scaffold.dart';
import '../../shared/widgets/group_table.dart';
import '../../shared/widgets/match_tile.dart';

class GroupDetailPage extends ConsumerWidget {
  const GroupDetailPage({super.key, required this.groupName});
  final String groupName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsAsync = ref.watch(standingsProvider);
    final matchesAsync = ref.watch(matchesProvider);

    return standingsAsync.when(
      loading: () => const DetailScaffold(
        title: Text('小组'),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => DetailScaffold(
        title: const Text('小组'),
        body: Center(child: Text(e.toString())),
      ),
      data: (standings) {
        final group = standings
            .where((s) => s.groupName == groupName)
            .firstOrNull;
        if (group == null) {
          return DetailScaffold(
            title: Text('$groupName 组'),
            body: const Center(child: Text('未找到该小组数据')),
          );
        }

        return DetailScaffold(
          title: Text('$groupName 组'),
          body: matchesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (matches) {
              final groupMatches = matches
                  .where((m) =>
                      m.isConfirmed &&
                      m.stage == MatchStage.group &&
                      m.group == groupName)
                  .toList();
              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  GroupTable(standing: group, showTitle: false),
                  const SizedBox(height: 16),
                  Text(
                    '小组赛程',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (groupMatches.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('暂无已确定的赛程'),
                    )
                  else
                    ...groupMatches.map(
                      (m) => MatchTile(
                        match: m,
                        onTap: () => context.push('/match/${m.id}'),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
