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
            body: const Center(child: Text('Stadium not found')),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(stadium.nameEn)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Icon(Icons.stadium, size: 64),
              const SizedBox(height: 12),
              _infoRow('FIFA Name', stadium.fifaName),
              _infoRow('City', stadium.cityEn),
              _infoRow('Country', stadium.countryEn),
              _infoRow('Region', stadium.region),
              _infoRow(
                  'Capacity',
                  stadium.capacity > 0
                      ? '${stadium.capacity.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+$)'), (m) => '${m[1]},')} seats'
                      : '—'),
              const Divider(height: 32),
              Text('Matches at this venue',
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
                      child: Text('No matches at this venue'),
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
