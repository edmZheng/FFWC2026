import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/match.dart';
import '../../providers.dart';
import '../../shared/widgets/match_tile.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(matchesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('赛程'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '赛中 / 未赛'),
            Tab(text: '完赛'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(worldCupDataProvider.notifier).refresh(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Error(
          message: e.toString(),
          onRetry: () => ref.read(worldCupDataProvider.notifier).refresh(),
        ),
        data: (matches) {
          final confirmed = matches.where((m) => m.isConfirmed).toList();
          return TabBarView(
            controller: _tabController,
            children: [
              _MatchList(
                matches: confirmed
                    .where((m) => m.status != MatchStatus.finished)
                    .toList(),
                emptyText: '暂无未完结赛程',
              ),
              _MatchList(
                matches: confirmed
                    .where((m) => m.status == MatchStatus.finished)
                    .toList(),
                emptyText: '暂无已完场比赛',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MatchList extends StatelessWidget {
  const _MatchList({required this.matches, required this.emptyText});

  final List<Match> matches;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Center(child: Text(emptyText));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: matches.length,
      itemBuilder: (_, i) => MatchTile(
        match: matches[i],
        onTap: () => context.push('/match/${matches[i].id}'),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      );
}
