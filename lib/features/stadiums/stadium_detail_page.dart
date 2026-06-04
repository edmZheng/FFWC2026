import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/zh_cn.dart';
import '../../providers.dart';
import '../../shared/widgets/detail_scaffold.dart';
import '../../shared/widgets/match_tile.dart';
import '../../shared/widgets/section_title.dart';
import '../../shared/widgets/stadium_cover.dart';

class StadiumDetailPage extends ConsumerWidget {
  const StadiumDetailPage({super.key, required this.stadiumId});
  final String stadiumId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stadiumAsync = ref.watch(stadiumsProvider);
    final matchesAsync = ref.watch(matchesProvider);

    return stadiumAsync.when(
      loading: () => const DetailScaffold(
        title: Text('场馆'),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => DetailScaffold(
        title: const Text('场馆'),
        body: Center(child: Text(e.toString())),
      ),
      data: (stadiums) {
        final stadium = stadiums.where((s) => s.id == stadiumId).firstOrNull;
        if (stadium == null) {
          return const DetailScaffold(
            title: Text('场馆'),
            body: Center(child: Text('场馆信息未找到')),
          );
        }

        final name = ZhCn.stadiumName(stadium);
        final city = ZhCn.city(stadium);
        final country = ZhCn.country(stadium);

        return DetailScaffold(
          title: Text(name),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: StadiumCover(
                  stadiumId: stadium.id,
                  borderRadius: BorderRadius.circular(12),
                  placeholderIconSize: 72,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _infoRow('球场常用名', stadium.fifaName),
              _infoRow('所在城市', city),
              _infoRow('国家/地区', country),
              _infoRow('赛区', ZhCn.region(stadium.region)),
              _infoRow(
                '场馆容量',
                stadium.capacity > 0
                    ? '可容纳 ${stadium.capacity.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+$)'), (m) => '${m[1]},')} 名观众'
                    : '容量未知',
              ),
              const Divider(height: 32),
              const SectionTitle('赛程'),
              matchesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(e.toString()),
                data: (matches) {
                  final venueMatches = matches
                      .where((m) => m.isConfirmed && m.stadiumId == stadiumId)
                      .toList();
                  if (venueMatches.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('暂无已确定的赛事安排'),
                    );
                  }
                  return Column(
                    children: venueMatches
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
      },
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
