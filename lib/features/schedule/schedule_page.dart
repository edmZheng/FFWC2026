import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_info.dart';
import '../../core/nav/schedule_scroll_nav.dart';
import '../../data/models/match.dart';
import '../../providers.dart';
import '../../shared/widgets/capsule_nav_bar.dart';
import '../../shared/widgets/match_tile.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final List<ScrollController> _scrollControllers;

  static const _scrollToTopThreshold = 120.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollControllers = List.generate(2, (_) => ScrollController());
    _tabController.addListener(_syncScrollNav);
    for (final c in _scrollControllers) {
      c.addListener(_syncScrollNav);
    }
  }

  @override
  void dispose() {
    ref.read(scheduleScrollNavProvider.notifier).reset();
    _tabController.removeListener(_syncScrollNav);
    _tabController.dispose();
    for (final c in _scrollControllers) {
      c.removeListener(_syncScrollNav);
      c.dispose();
    }
    super.dispose();
  }

  void _syncScrollNav() {
    if (!_tabController.indexIsChanging) {
      _publishScrollNav();
    }
  }

  void _publishScrollNav() {
    final idx = _tabController.index;
    final controller = _scrollControllers[idx];
    final show = controller.hasClients &&
        controller.offset > _scrollToTopThreshold;
    ref.read(scheduleScrollNavProvider.notifier).update(
          showScrollToTop: show,
          scrollToTop: show ? () => _scrollToTop(idx) : null,
        );
  }

  Future<void> _scrollToTop(int tabIndex) async {
    final controller = _scrollControllers[tabIndex];
    if (!controller.hasClients) return;
    await controller.animateTo(
      0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
    _publishScrollNav();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(matchesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppInfo.displayName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                letterSpacing: 0.04,
                fontWeight: FontWeight.w600,
              ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '赛中 / 未赛'),
            Tab(text: '完赛'),
          ],
        ),
      ),
      body: async.when(
        skipLoadingOnReload: true,
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
                scrollController: _scrollControllers[0],
                matches: confirmed
                    .where((m) => m.status != MatchStatus.finished)
                    .toList(),
                emptyText: '暂无未完结赛程',
                onRefresh: () =>
                    ref.read(worldCupDataProvider.notifier).refresh(),
              ),
              _MatchList(
                scrollController: _scrollControllers[1],
                matches: confirmed
                    .where((m) => m.status == MatchStatus.finished)
                    .toList(),
                emptyText: '暂无已完场比赛',
                onRefresh: () =>
                    ref.read(worldCupDataProvider.notifier).refresh(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MatchList extends StatelessWidget {
  const _MatchList({
    required this.scrollController,
    required this.matches,
    required this.emptyText,
    required this.onRefresh,
  });

  final ScrollController scrollController;
  final List<Match> matches;
  final String emptyText;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final bottomPad = CapsuleNavMetrics.bottomInset(context);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: matches.isEmpty
          ? ListView(
              controller: scrollController,
              clipBehavior: Clip.none,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.35,
                  child: Center(child: Text(emptyText)),
                ),
                SizedBox(height: bottomPad),
              ],
            )
          : ListView.builder(
              controller: scrollController,
              clipBehavior: Clip.none,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(top: 8, bottom: bottomPad),
              itemCount: matches.length,
              itemBuilder: (_, i) => MatchTile(
                match: matches[i],
                onTap: () => context.push('/match/${matches[i].id}'),
              ),
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
