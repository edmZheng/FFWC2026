import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/zh_cn.dart';
import '../../data/models/player.dart';
import '../../providers.dart';
import '../../shared/widgets/detail_scaffold.dart';
import '../../shared/widgets/match_tile.dart';
import '../../shared/widgets/player_avatar.dart';
import '../../shared/widgets/team_badge.dart';

class TeamDetailPage extends ConsumerWidget {
  const TeamDetailPage({super.key, required this.teamId});
  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(teamByIdProvider(teamId));
    final matchesAsync = ref.watch(matchesProvider);
    final squadAsync = ref.watch(squadByTeamIdProvider(teamId));

    if (team == null) {
      return const DetailScaffold(
        title: Text('球队'),
        body: Center(child: Text('球队信息未找到')),
      );
    }

    final name = ZhCn.teamName(team);

    return DetailScaffold(
      title: Text(name),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: TeamBadge(
              iso2: team.iso2,
              fifaCode: team.fifaCode,
              flagUrl: team.flagUrl,
              size: 96,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow('FIFA 代码', team.fifaCode),
          _infoRow('国家代码', team.iso2.toUpperCase()),
          if (team.groups.isNotEmpty)
            _infoRow('所在小组', team.groups.map((g) => '$g 组').join('、')),
          const Divider(height: 32),
          Text(
            '世界杯名单',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          squadAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(8),
              child: Text('名单加载失败：$e'),
            ),
            data: (players) {
              if (players.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('暂无该队名单数据'),
                );
              }
              return _SquadGrid(players: players);
            },
          ),
          const Divider(height: 32),
          Text(
            '比赛记录',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          matchesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(e.toString()),
            data: (matches) {
              final myMatches = matches
                  .where(
                    (m) =>
                        m.isConfirmed &&
                        (m.homeTeamId == teamId || m.awayTeamId == teamId),
                  )
                  .toList();
              if (myMatches.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('尚无已确定的赛程'),
                );
              }
              return Column(
                children: myMatches
                    .map(
                      (m) => MatchTile(
                        match: m,
                        onTap: () => context.push('/match/${m.id}'),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );
}

class _SquadGrid extends StatelessWidget {
  const _SquadGrid({required this.players});

  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 110,
        mainAxisExtent: 128,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: players.length,
      itemBuilder: (_, i) {
        final p = players[i];
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Column(
              children: [
                PlayerAvatar(
                  photoUrl: p.photoUrl,
                  number: p.number,
                  size: 52,
                ),
                const SizedBox(height: 6),
                Text(
                  '${p.number}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  p.displayName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight:
                            p.captain ? FontWeight.bold : FontWeight.normal,
                      ),
                ),
                Text(
                  p.positionZh,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
