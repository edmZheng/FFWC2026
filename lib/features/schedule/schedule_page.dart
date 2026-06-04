import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_info.dart';
import '../../core/nav/schedule_scroll_nav.dart';
import '../../core/utils/match_calendar.dart';
import '../../data/models/match.dart';
import '../../data/repositories/match_id_map_repository.dart';
import '../../providers.dart';
import '../../shared/widgets/capsule_nav_bar.dart';
import '../../shared/widgets/match_tile.dart';
import 'schedule_day_strip.dart';
import 'schedule_search_delegate.dart';

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
  static const _calendarAnimDuration = Duration(milliseconds: 320);

  /// 默认展示「赛中 / 未赛」（关注 Tab 在 index 0）。
  static const _defaultTabIndex = 1;

  bool _calendarOpen = false;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _defaultTabIndex,
    );
    _scrollControllers = List.generate(3, (_) => ScrollController());
    _tabController.addListener(_onTabChanged);
    for (final c in _scrollControllers) {
      c.addListener(_publishScrollNav);
    }
  }

  @override
  void dispose() {
    ref.read(scheduleScrollNavProvider.notifier).reset();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    for (final c in _scrollControllers) {
      c.removeListener(_publishScrollNav);
      c.dispose();
    }
    super.dispose();
  }

  void _toggleCalendar() {
    setState(() {
      if (_calendarOpen) {
        _calendarOpen = false;
        _selectedDay = null;
      } else {
        _calendarOpen = true;
        _selectedDay = defaultCalendarSelectedDay();
      }
    });
    for (var i = 0; i < _scrollControllers.length; i++) {
      _scrollToTop(i);
    }
  }

  void _onDaySelected(DateTime day) {
    setState(() => _selectedDay = calendarDateOnly(day));
    for (var i = 0; i < _scrollControllers.length; i++) {
      _scrollToTop(i);
    }
  }

  static Map<String, DateTime> _kickoffUtcMap(
    Map<String, MatchIdMapEntry>? map,
  ) {
    if (map == null) return const {};
    return {for (final e in map.entries) e.key: e.value.kickoffUtc};
  }

  List<Match> _applyDayFilter(
    List<Match> matches,
    Map<String, DateTime> kickoffMap,
  ) {
    final day = _selectedDay;
    if (!_calendarOpen || day == null) return matches;
    return filterMatchesByCalendarDay(
      matches: matches,
      day: day,
      kickoffUtcById: kickoffMap,
    );
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _publishScrollNav();
      if (_calendarOpen) setState(() {});
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
    final followedAsync = ref.watch(followedMatchesProvider);
    final hasFollowedTeams = ref.watch(followedTeamsProvider).isNotEmpty;
    final kickoffMap = _kickoffUtcMap(ref.watch(matchIdMapProvider).valueOrNull);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            _calendarOpen ? Icons.calendar_month : Icons.calendar_month_outlined,
          ),
          tooltip: _calendarOpen ? '收起赛历' : '赛事日历',
          onPressed: _toggleCalendar,
        ),
        title: Text(
          AppInfo.displayName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                letterSpacing: 0.04,
                fontWeight: FontWeight.w600,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '搜索赛程',
            onPressed: () => showSearch<void>(
              context: context,
              delegate: ScheduleSearchDelegate(ref),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '关注'),
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
          final matchCounts = matchCountByCalendarDay(
            matches: confirmed,
            kickoffUtcById: kickoffMap,
          );
          final calendarDays = scheduleCalendarDays(
            matches: confirmed,
            kickoffUtcById: kickoffMap,
          );
          final followedMatches = followedAsync.valueOrNull ?? const [];
          final followedMatchCounts = matchCountByCalendarDay(
            matches: followedMatches,
            kickoffUtcById: kickoffMap,
          );
          final onFollowTab = _tabController.index == 0;
          final highlightCounts =
              onFollowTab ? followedMatchCounts : matchCounts;
          final labelCounts = onFollowTab ? followedMatchCounts : matchCounts;
          final followedEmptyText = hasFollowedTeams
              ? (_calendarOpen ? '该日暂无关注球队的赛程' : '暂无关注球队的赛程')
              : '尚未关注球队\n在球队页或球队详情中点击爱心即可关注';
          const dayFilterEmpty = '该日暂无赛程';

          final active = _applyDayFilter(
            confirmed.where((m) => m.status != MatchStatus.finished).toList(),
            kickoffMap,
          );
          final finished = _applyDayFilter(
            confirmed.where((m) => m.status == MatchStatus.finished).toList(),
            kickoffMap,
          );
          final followed = _applyDayFilter(followedMatches, kickoffMap);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSize(
                duration: _calendarAnimDuration,
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _calendarOpen && _selectedDay != null
                    ? ScheduleDayStrip(
                        days: calendarDays,
                        selectedDay: _selectedDay!,
                        highlightCountByDay: highlightCounts,
                        labelCountByDay: labelCounts,
                        onDaySelected: _onDaySelected,
                      )
                    : const SizedBox(width: double.infinity),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _MatchList(
                      scrollController: _scrollControllers[0],
                      matches: followed,
                      emptyText: followedEmptyText,
                      onRefresh: () =>
                          ref.read(worldCupDataProvider.notifier).refresh(),
                    ),
                    _MatchList(
                      scrollController: _scrollControllers[1],
                      matches: active,
                      emptyText: _calendarOpen ? dayFilterEmpty : '暂无未完结赛程',
                      onRefresh: () =>
                          ref.read(worldCupDataProvider.notifier).refresh(),
                    ),
                    _MatchList(
                      scrollController: _scrollControllers[2],
                      matches: finished,
                      emptyText: _calendarOpen ? dayFilterEmpty : '暂无已完场比赛',
                      onRefresh: () =>
                          ref.read(worldCupDataProvider.notifier).refresh(),
                    ),
                  ],
                ),
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
                  child: Center(
                    child: Text(
                      emptyText,
                      textAlign: TextAlign.center,
                    ),
                  ),
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
