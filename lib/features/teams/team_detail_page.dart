import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/zh_cn.dart';
import '../../data/models/player.dart';
import '../../data/models/team.dart';
import '../../providers.dart';
import '../../shared/widgets/detail_fixed_header_body.dart';
import '../../shared/widgets/detail_scaffold.dart';
import '../../shared/widgets/match_tile.dart';
import '../../shared/widgets/section_title.dart';
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
    final ranking = ref.watch(fifaRankByCodeProvider(team.fifaCode));

    return DetailScaffold(
      title: Text(name),
      body: DetailFixedHeaderBody(
        header: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _TeamHeader(
            team: team,
            rankingRank: ranking?.rank,
          ),
        ),
        builder: (topInset) => RefreshIndicator(
          onRefresh: () => ref.read(worldCupDataProvider.notifier).refresh(),
          child: ListView(
            clipBehavior: Clip.none,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, topInset, 16, 24),
            children: [
              const SectionTitle('赛程'),
              matchesAsync.when(
                skipLoadingOnReload: true,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(e.toString()),
                data: (matches) {
                  final myMatches = matches
                      .where(
                        (m) =>
                            m.isConfirmed &&
                            (m.homeTeamId == teamId ||
                                m.awayTeamId == teamId),
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
              const Divider(height: 32),
              const SectionTitle('出战名单'),
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
                  return _SquadList(players: players);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 国旗 + 小组 / FIFA 排名：居中、左右并排。
class _TeamHeader extends StatelessWidget {
  const _TeamHeader({
    required this.team,
    this.rankingRank,
  });

  final Team team;
  final int? rankingRank;

  static const _flagSize = 96.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final infoLines = <Widget>[];

    if (team.groups.isNotEmpty) {
      infoLines.add(
        _metaLine(
          context,
          '小组',
          team.groups.map((g) => '$g 组').join('、'),
        ),
      );
    }
    if (rankingRank != null) {
      infoLines.add(
        _metaLine(context, 'FIFA 排名', '第 $rankingRank 名'),
      );
    }
    if (infoLines.isEmpty) {
      infoLines.add(
        Text(
          '暂无小组与排名信息',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TeamBadge(
              iso2: team.iso2,
              fifaCode: team.fifaCode,
              flagUrl: team.flagUrl,
              size: _flagSize,
            ),
            const SizedBox(width: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: infoLines,
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaLine(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SquadList extends StatelessWidget {
  const _SquadList({required this.players});
  final List<Player> players;

  static const _order = ['GK', 'DF', 'MF', 'FW'];
  static const _zh = {'GK': '门将', 'DF': '后卫', 'MF': '中场', 'FW': '前锋'};

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Player>>{};
    for (final p in players) {
      grouped.putIfAbsent(p.position, () => []).add(p);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => a.number.compareTo(b.number));
    }
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final sections = <Widget>[];
    for (final pos in _order) {
      final list = grouped[pos];
      if (list == null || list.isEmpty) continue;
      sections.add(Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(
          '${_zh[pos] ?? pos}（${list.length}）',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
        ),
      ));
      for (final p in list) {
        sections.add(_PlayerRow(player: p));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections,
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.player});
  final Player player;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasZh =
        player.nameZh.isNotEmpty && player.nameZh != player.nameEn;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${player.number}',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        player.captain ? FontWeight.bold : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasZh)
                  Text(
                    player.nameEn,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.outline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (player.captain)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '队长',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
