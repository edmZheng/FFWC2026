import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/zh_cn.dart';
import '../../providers.dart';
import '../../shared/widgets/capsule_nav_bar.dart';
import '../../shared/widgets/edge_proximity_scale.dart';
import '../../shared/widgets/stadium_cover.dart';

class StadiumsPage extends ConsumerWidget {
  const StadiumsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stadiumsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('场馆')),
      body: async.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (stadiums) => GridView.builder(
          clipBehavior: Clip.none,
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            CapsuleNavMetrics.bottomInset(context),
          ),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            mainAxisExtent: 200,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: stadiums.length,
          itemBuilder: (_, i) {
            final s = stadiums[i];
            final name = ZhCn.stadiumName(s);
            final location = '${ZhCn.city(s)} · ${ZhCn.country(s)}';
            return EdgeProximityScale(
              child: InkWell(
              onTap: () => context.push('/stadium/${s.id}'),
              borderRadius: BorderRadius.circular(10),
              child: Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: StadiumCover(stadiumId: s.id),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      child: Text(
                        location,
                        style: Theme.of(context).textTheme.labelSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            );
          },
        ),
      ),
    );
  }
}
