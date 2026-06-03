import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/zh_cn.dart';
import '../../providers.dart';
import '../../shared/widgets/team_badge.dart';

class TeamsPage extends ConsumerWidget {
  const TeamsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teamsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('球队')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (teams) => GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 140,
            mainAxisExtent: 110,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: teams.length,
          itemBuilder: (_, i) {
            final t = teams[i];
            final name = ZhCn.teamName(t);
            return InkWell(
              onTap: () => context.push('/team/${t.id}'),
              borderRadius: BorderRadius.circular(12),
              child: Card(
                margin: EdgeInsets.zero,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TeamBadge(
                      iso2: t.iso2,
                      fifaCode: t.fifaCode,
                      flagUrl: t.flagUrl,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (t.fifaCode.isNotEmpty)
                      Text(
                        t.fifaCode,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
