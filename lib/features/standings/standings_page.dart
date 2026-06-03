import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/match.dart';
import '../../providers.dart';
import '../../shared/widgets/group_table.dart';
import '../../shared/widgets/match_tile.dart';

class StandingsPage extends ConsumerWidget {
  const StandingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsAsync = ref.watch(standingsProvider);
    final matchesAsync = ref.watch(matchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Standings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(worldCupDataProvider.notifier).refresh(),
          ),
        ],
      ),
      body: standingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (standings) {
          if (standings.isEmpty) {
            return const Center(child: Text('No standings data'));
          }
          return DefaultTabController(
            length: standings.length,
            child: Column(
              children: [
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: standings
                      .map((s) => Tab(text: 'Group ${s.groupName}'))
                      .toList(),
                ),
                Expanded(
                  child: TabBarView(
                    children: standings.map((group) {
                      return matchesAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text(e.toString())),
                        data: (matches) {
                          final groupMatches = matches
                              .where((m) =>
                                  m.stage == MatchStage.group &&
                                  m.group == group.groupName)
                              .toList();
                          return ListView(
                            padding: const EdgeInsets.all(12),
                            children: [
                              GroupTable(standing: group),
                              const SizedBox(height: 16),
                              Text('Matches',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                          fontWeight: FontWeight.bold)),
                              ...groupMatches.map((m) => MatchTile(
                                    match: m,
                                    onTap: () =>
                                        context.go('/match/${m.id}'),
                                  )),
                            ],
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
