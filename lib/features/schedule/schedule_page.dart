import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/nav/schedule_scroll_nav.dart';
import '../../core/utils/kickoff_time_resolver.dart';
import '../../data/models/match.dart';
import '../../data/repositories/match_id_map_repository.dart';
import '../../data/repositories/lineups/providers.dart';
import '../../data/repositories/worldcup/providers.dart';
import '../../shared/widgets/app_bar_title_image.dart';
import '../../shared/widgets/capsule_nav_bar.dart';
import '../../shared/widgets/match_tile.dart';
import '../../shared/widgets/z_sorted_sliver_list.dart';
import '../../data/repositories/followed_teams/providers.dart';
import 'schedule_day_strip.dart';
import 'schedule_search_panel.dart';
import 'state/schedule_page_state.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final List<ScrollController> _scrollControllers;
  SchedulePageUiState _uiState = const SchedulePageUiState();

  static const _scrollToTopThreshold = 120.0;
  static const _calendarAnimDuration = Duration(milliseconds: 320);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _uiState.tabIndex,
    );
    _scrollControllers = List.generate(3, (_) => ScrollController());
    _tabController.addListener(_onTabChanged);
    for (final c in _scrollControllers) {
      c.addListener(_publishScrollNav);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncScrollNav());
  }

  @override
  void activate() {
    super.activate();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncScrollNav());
  }

  void _syncScrollNav() {
    if (!mounted) return;
    _publishScrollNav();
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
    setState(() => _uiState = _uiState.toggleCalendar());
    _scrollAllToTop();
  }

  void _toggleSearch() {
    setState(() => _uiState = _uiState.toggleSearch());
    _scrollAllToTop();
  }

  void _closeSearch() {
    setState(() => _uiState = _uiState.closeSearch());
    _scrollAllToTop();
  }

  void _onDaySelected(DateTime day) {
    setState(() => _uiState = _uiState.selectDay(day));
    _scrollAllToTop();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _publishScrollNav();
      if (_uiState.calendarOpen) setState(() {});
    }
  }

  void _publishScrollNav() {
    final idx = _tabController.index;
    final controller = _scrollControllers[idx];
    final show =
        controller.hasClients && controller.offset > _scrollToTopThreshold;
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

  void _scrollAllToTop() {
    for (var i = 0; i < _scrollControllers.length; i++) {
      _scrollToTop(i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(matchesProvider);
    final followedAsync = ref.watch(followedMatchesProvider);
    final hasFollowedTeams = ref.watch(followedTeamsProvider).isNotEmpty;
    final kickoffMap = kickoffUtcMap(ref.watch(matchIdMapProvider).valueOrNull);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            _uiState.calendarOpen
                ? Icons.calendar_month
                : Icons.calendar_month_outlined,
          ),
          tooltip: _uiState.calendarOpen ? '收起赛历' : '赛事日历',
          onPressed: _toggleCalendar,
        ),
        title: AppBarTitleImage.games(
          onTap: () => _scrollToTop(_tabController.index),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _uiState.searchOpen ? Icons.search : Icons.search_outlined,
            ),
            tooltip: _uiState.searchOpen ? '收起搜索' : '搜索赛程',
            onPressed: _toggleSearch,
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
          final visible = ScheduleVisibleMatches.build(
            matches: matches,
            followedMatches: followedAsync.valueOrNull ?? const [],
            uiState: _uiState,
            kickoffUtcById: kickoffMap,
          );
          final highlightCounts = visible.countsForCurrentTab;
          final labelCounts = highlightCounts;
          final followedEmptyText = hasFollowedTeams
              ? (_uiState.calendarOpen ? '该日暂无关注球队的赛程' : '暂无关注球队的赛程')
              : '尚未关注球队\n在球队页或球队详情中点击爱心即可关注';
          const dayFilterEmpty = '该日暂无赛程';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSize(
                duration: _calendarAnimDuration,
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _uiState.calendarOpen && _uiState.selectedDay != null
                    ? ScheduleDayStrip(
                        days: visible.calendarDays,
                        selectedDay: _uiState.selectedDay!,
                        highlightCountByDay: highlightCounts,
                        labelCountByDay: labelCounts,
                        onDaySelected: _onDaySelected,
                      )
                    : const SizedBox(width: double.infinity),
              ),
              AnimatedSize(
                duration: _calendarAnimDuration,
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _uiState.searchOpen
                    ? Material(
                        color:
                            Theme.of(context).colorScheme.surfaceContainerLow,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: ScheduleInlineSearchField(
                                  query: _uiState.searchQuery,
                                  onChanged: (q) => setState(
                                    () => _uiState =
                                        _uiState.updateSearchQuery(q),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                tooltip: '收起搜索',
                                onPressed: _closeSearch,
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              Expanded(
                child: _uiState.searchOpen
                    ? ScheduleSearchResults(query: _uiState.searchQuery)
                    : TabBarView(
                        controller: _tabController,
                        clipBehavior: Clip.none,
                        children: [
                          _MatchList(
                            scrollController: _scrollControllers[0],
                            matches: visible.followed,
                            kickoffTexts:
                                kickoffTextsFor(visible.followed, kickoffMap),
                            emptyText: followedEmptyText,
                            onRefresh: () => ref
                                .read(worldCupDataProvider.notifier)
                                .refresh(),
                          ),
                          _MatchList(
                            scrollController: _scrollControllers[1],
                            matches: visible.active,
                            kickoffTexts:
                                kickoffTextsFor(visible.active, kickoffMap),
                            emptyText: _uiState.calendarOpen
                                ? dayFilterEmpty
                                : '暂无未完结赛程',
                            onRefresh: () => ref
                                .read(worldCupDataProvider.notifier)
                                .refresh(),
                          ),
                          _MatchList(
                            scrollController: _scrollControllers[2],
                            matches: visible.finished,
                            kickoffTexts:
                                kickoffTextsFor(visible.finished, kickoffMap),
                            emptyText: _uiState.calendarOpen
                                ? dayFilterEmpty
                                : '暂无已完场比赛',
                            onRefresh: () => ref
                                .read(worldCupDataProvider.notifier)
                                .refresh(),
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

Map<String, DateTime> kickoffUtcMap(Map<String, MatchIdMapEntry>? map) {
  if (map == null) return const {};
  return {for (final e in map.entries) e.key: e.value.kickoffUtc};
}

Map<String, String> kickoffTextsFor(
  List<Match> matches,
  Map<String, DateTime> kickoffUtcById,
) =>
    KickoffTimeResolver.formatMap(matches, kickoffUtcById);

class _MatchList extends StatelessWidget {
  const _MatchList({
    required this.scrollController,
    required this.matches,
    required this.kickoffTexts,
    required this.emptyText,
    required this.onRefresh,
  });

  final ScrollController scrollController;
  final List<Match> matches;
  final Map<String, String> kickoffTexts;
  final String emptyText;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final bottomPad = CapsuleNavMetrics.bottomInset(context);
    final systemBottom = MediaQuery.paddingOf(context).bottom;

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
          : ZSortedListView.builder(
              controller: scrollController,
              clipBehavior: Clip.none,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(top: 8, bottom: bottomPad + 8),
              itemCount: matches.length,
              itemBuilder: (_, i) => MatchTile(
                match: matches[i],
                kickoffText: kickoffTexts[matches[i].id] ?? '时间待定',
                onTap: () => context.push('/match/${matches[i].id}'),
                bottomFadeInset: systemBottom,
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
