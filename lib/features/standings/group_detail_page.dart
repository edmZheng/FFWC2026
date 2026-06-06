import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/kickoff_time_resolver.dart';
import '../../data/models/match.dart';
import '../../data/repositories/lineups/providers.dart';
import '../../data/repositories/match_id_map_repository.dart';
import '../../data/repositories/worldcup/providers.dart';
import '../../shared/widgets/detail_fixed_header_body.dart';
import '../../shared/widgets/detail_scaffold.dart';
import '../../shared/widgets/group_table.dart';
import '../../shared/widgets/match_tile.dart';
import '../../shared/widgets/section_title.dart';

class GroupDetailPage extends ConsumerWidget {
  const GroupDetailPage({super.key, required this.groupName});
  final String groupName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsAsync = ref.watch(standingsProvider);
    final matchesAsync = ref.watch(matchesProvider);

    return standingsAsync.when(
      skipLoadingOnReload: true,
      loading: () => const DetailScaffold(
        title: Text('小组'),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => DetailScaffold(
        title: const Text('小组'),
        body: Center(child: Text(e.toString())),
      ),
      data: (standings) {
        final group =
            standings.where((s) => s.groupName == groupName).firstOrNull;
        if (group == null) {
          return DetailScaffold(
            title: Text('$groupName 组'),
            body: const Center(child: Text('未找到该小组数据')),
          );
        }

        return DetailScaffold(
          title: Text('$groupName 组'),
          body: matchesAsync.when(
            skipLoadingOnReload: true,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (matches) {
              final groupMatches = matches
                  .where((m) =>
                      m.isConfirmed &&
                      m.stage == MatchStage.group &&
                      m.group == groupName)
                  .toList();

              return DetailFixedHeaderBody(
                header: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: GroupTable(standing: group, showTitle: false),
                    ),
                  ),
                ),
                builder: (topInset) {
                  if (groupMatches.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(top: topInset),
                      children: const [
                        SectionTitle('赛程'),
                        SizedBox(height: 48),
                        Center(child: Text('暂无已确定的赛程')),
                      ],
                    );
                  }
                  final kickoffTexts = kickoffTextsFor(
                    groupMatches,
                    ref.watch(matchIdMapProvider).valueOrNull,
                  );
                  return ListView.builder(
                    clipBehavior: Clip.none,
                    padding: EdgeInsets.only(top: topInset, bottom: 16),
                    itemCount: groupMatches.length + 1,
                    itemBuilder: (_, i) {
                      if (i == 0) return const SectionTitle('赛程');
                      final m = groupMatches[i - 1];
                      return MatchTile(
                        match: m,
                        kickoffText: kickoffTexts[m.id] ?? '时间待定',
                        onTap: () => context.push('/match/${m.id}'),
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

Map<String, String> kickoffTextsFor(
  List<Match> matches,
  Map<String, MatchIdMapEntry>? map,
) {
  final kickoffUtcById = <String, DateTime?>{
    if (map != null)
      for (final entry in map.entries) entry.key: entry.value.kickoffUtc,
  };
  return KickoffTimeResolver.formatMap(matches, kickoffUtcById);
}
