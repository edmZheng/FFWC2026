import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers.dart';

class StadiumsPage extends ConsumerWidget {
  const StadiumsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stadiumsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Stadiums')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (stadiums) => ListView.builder(
          itemCount: stadiums.length,
          itemBuilder: (_, i) {
            final s = stadiums[i];
            return ListTile(
              leading: const Icon(Icons.stadium),
              title: Text(s.nameEn),
              subtitle: Text('${s.cityEn}, ${s.countryEn}'),
              trailing: Text(
                '${_fmt(s.capacity)} cap.',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              onTap: () => context.go('/stadium/${s.id}'),
            );
          },
        ),
      ),
    );
  }

  String _fmt(int n) {
    if (n == 0) return '—';
    return n >= 1000
        ? '${(n / 1000).toStringAsFixed(0)}k'
        : '$n';
  }
}
