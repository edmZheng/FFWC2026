import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';
import '../../shared/widgets/match_tile.dart';

class StadiumDetailPage extends ConsumerWidget {
  const StadiumDetailPage({super.key, required this.stadiumId});
  final String stadiumId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stadiumAsync = ref.watch(stadiumsProvider);
    final matchesAsync = ref.watch(matchesProvider);

    return stadiumAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (stadiums) {
        final stadium = stadiums.where((s) => s.id == stadiumId).firstOrNull;
        if (stadium == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Stadium')),
            body: const Center(child: Text('场馆信息未找到')),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(stadium.nameEn)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Icon(Icons.stadium, size: 64),
              const SizedBox(height: 12),
              _infoRow('FIFA名称', stadium.fifaName),
              _infoRow('所在城市', stadium.cityEn),
              _infoRow('国家/地区', stadium.countryEn),
              _infoRow('赛区', stadium.region),
              _infoRow(
                  '场馆容量',
                  stadium.capacity > 0
                      ? '可容纳 ${stadium.capacity.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+$)'), (m) => '${m[1]},')} 名观众'
                      : '容量未知'),
              const Divider(height: 32),
              Text('将在此投入使用的赛场',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              matchesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(e.toString()),
                data: (matches) {
                  final venueMatches = matches
                      .where((m) => m.stadiumId == stadiumId)
                      .toList();
                  if (venueMatches.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('暂无赛事安排'),
                    );
                  }
                  return Column(
                    children: venueMatches
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
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(child: Text(value)),
          ],
        ),
      );
}
