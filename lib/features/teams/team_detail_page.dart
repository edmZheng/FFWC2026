import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';
import '../../shared/widgets/match_tile.dart';
import '../../shared/widgets/team_badge.dart';

class TeamDetailPage extends ConsumerWidget {
  const TeamDetailPage({super.key, required this.teamId});
  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(teamByIdProvider(teamId));
    final matchesAsync = ref.watch(matchesProvider);

    if (team == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Team')),
        body: const Center(child: Text('球队信息未找到')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(team.nameEn)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: TeamBadge(iso2: team.iso2, flagUrl: team.flagUrl, size: 96)),
          const SizedBox(height: 12),
          _infoRow('FIFA代码', team.fifaCode),
          _infoRow('国家代码', team.iso2.toUpperCase()),
          if (team.groups.isNotEmpty)
            _infoRow('所在小组', team.groups.join(', ')),
          const Divider(height: 32),
          Text('比赛记录',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          matchesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(e.toString()),
            data: (matches) {
              final myMatches = matches
                  .where((m) =>
                      m.homeTeamId == teamId || m.awayTeamId == teamId)
                  .toList();
              if (myMatches.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('尚无赛程安排'),
                );
              }
              return Column(
                children: myMatches
                    .map((m) => MatchTile(
                          match: m,
                          onTap: () => context.go('/match/${m.id}'),
                        ))
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
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
            Text(value),
          ],
        ),
      );
}
