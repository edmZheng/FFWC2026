import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api/api_client.dart';
import 'core/cache/cache_store.dart';
import 'core/utils/teams_grid_sort.dart';
import 'data/models/group_standing.dart';
import 'data/models/match.dart';
import 'data/models/stadium.dart';
import 'data/models/player.dart';
import 'data/models/team.dart';
import 'core/api/endpoints.dart';
import 'data/models/lineup.dart';
import 'data/repositories/followed_teams_store.dart';
import 'data/repositories/lineup_repository.dart';
import 'data/repositories/match_id_map_repository.dart';
import 'data/repositories/ranking_repository.dart';
import 'data/repositories/squad_repository.dart';
import 'data/repositories/worldcup_repository.dart';
import 'core/live/live_score_sync.dart';
import 'features/schedule/schedule_search_index.dart';

// ─── Infrastructure ──────────────────────────────────────────────────────────

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('Override with SharedPreferences.getInstance()'),
);

final cacheStoreProvider = Provider<CacheStore>(
  (ref) => CacheStore(ref.watch(sharedPreferencesProvider)),
);

final apiClientProvider = Provider<ApiClient>((_) => ApiClient());

final worldCupRepositoryProvider = Provider<WorldCupRepository>(
  (ref) => WorldCupRepository(
    api: ref.watch(apiClientProvider),
    cache: ref.watch(cacheStoreProvider),
  ),
);

// ─── Data ─────────────────────────────────────────────────────────────────────

final worldCupDataProvider = AsyncNotifierProvider<WorldCupDataNotifier, WorldCupData>(
  WorldCupDataNotifier.new,
);

class WorldCupDataNotifier extends AsyncNotifier<WorldCupData> {
  @override
  Future<WorldCupData> build() => ref.watch(worldCupRepositoryProvider).load();

  /// 下拉刷新：保持当前内容可见，后台拉取后再替换（不设 loading，避免整页闪没）。
  Future<void> refresh() async {
    final previous = state.valueOrNull;
    state = await AsyncValue.guard(
      () => ref.read(worldCupRepositoryProvider).load(forceRefresh: true),
    );
    if (state.hasError && previous != null) {
      state = AsyncValue.data(previous);
    }
  }
}

// ─── Derived selectors ────────────────────────────────────────────────────────

final matchesProvider = Provider<AsyncValue<List<Match>>>(
  (ref) => ref.watch(worldCupDataProvider).whenData((d) => d.matches),
);

final teamsProvider = Provider<AsyncValue<List<Team>>>(
  (ref) => ref.watch(worldCupDataProvider).whenData((d) => d.teams),
);

/// 球队宫格：已关注球队排在最前，组内保持 API 原始顺序。
final teamsGridProvider = Provider<AsyncValue<List<Team>>>((ref) {
  final followed = ref.watch(followedTeamsProvider);
  return ref.watch(teamsProvider).whenData(
        (teams) => sortTeamsWithFollowedFirst(teams, followed),
      );
});

final stadiumsProvider = Provider<AsyncValue<List<Stadium>>>(
  (ref) => ref.watch(worldCupDataProvider).whenData((d) => d.stadiums),
);

final standingsProvider = Provider<AsyncValue<List<GroupStanding>>>(
  (ref) => ref.watch(worldCupDataProvider).whenData((d) => d.standings),
);

final liveMatchesProvider = Provider<AsyncValue<List<Match>>>(
  (ref) => ref.watch(matchesProvider).whenData(
        (ms) => ms.where((m) => m.status == MatchStatus.live).toList(),
      ),
);

// ─── Followed teams ───────────────────────────────────────────────────────────

final followedTeamsStoreProvider = Provider<FollowedTeamsStore>(
  (ref) => FollowedTeamsStore(ref.watch(sharedPreferencesProvider)),
);

class FollowedTeamsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => ref.watch(followedTeamsStoreProvider).read();

  Future<void> toggle(String teamId) async {
    final next = Set<String>.from(state);
    if (next.contains(teamId)) {
      next.remove(teamId);
    } else {
      next.add(teamId);
    }
    state = next;
    await ref.read(followedTeamsStoreProvider).write(next);
  }
}

final followedTeamsProvider =
    NotifierProvider<FollowedTeamsNotifier, Set<String>>(
  FollowedTeamsNotifier.new,
);

int _compareMatchesByKickoff(Match a, Match b) {
  final da = a.localDate;
  final db = b.localDate;
  if (da == null && db == null) return a.id.compareTo(b.id);
  if (da == null) return 1;
  if (db == null) return -1;
  final c = da.compareTo(db);
  return c != 0 ? c : a.id.compareTo(b.id);
}

/// 关注球队的全部已确定赛程（按开赛时间排序）。
final followedMatchesProvider = Provider<AsyncValue<List<Match>>>((ref) {
  final followed = ref.watch(followedTeamsProvider);
  if (followed.isEmpty) return const AsyncValue.data([]);
  return ref.watch(matchesProvider).whenData((ms) {
    final list = ms
        .where(
          (m) =>
              m.isConfirmed &&
              (followed.contains(m.homeTeamId) ||
                  followed.contains(m.awayTeamId)),
        )
        .toList()
      ..sort(_compareMatchesByKickoff);
    return list;
  });
});

// ─── Live score sync (global) ────────────────────────────────────────────────

/// 赛会期间：存在进行中比赛时，每 [kLiveScorePollInterval] 刷新 [worldCupDataProvider]。
/// 在 [MyApp] 中 `ref.watch` 以保持存活；赛程/详情/积分榜等页面自动跟分。
final liveScoreSyncProvider =
    NotifierProvider<LiveScoreSyncNotifier, void>(LiveScoreSyncNotifier.new);

class LiveScoreSyncNotifier extends Notifier<void> {
  Timer? _timer;

  @override
  void build() {
    ref.onDispose(_stop);

    ref.listen<AsyncValue<WorldCupData>>(
      worldCupDataProvider,
      (_, next) {
        final matches = next.valueOrNull?.matches;
        if (matches != null && hasLiveMatches(matches)) {
          _startIfNeeded();
        } else {
          _stop();
        }
      },
      fireImmediately: true,
    );
  }

  void _startIfNeeded() {
    if (_timer != null) return;
    ref.read(worldCupDataProvider.notifier).refresh();
    _timer = Timer.periodic(kLiveScorePollInterval, (_) {
      ref.read(worldCupDataProvider.notifier).refresh();
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }
}

/// 未挂 Tab 的直播列表页沿用同一数据源。
final livePollingProvider = liveMatchesProvider;

// ─── Single match (for detail page) ──────────────────────────────────────────

final matchByIdProvider = Provider.family<Match?, String>((ref, id) {
  return ref
      .watch(matchesProvider)
      .whenData((ms) => ms.where((m) => m.id == id).firstOrNull)
      .valueOrNull
      .flatMap((m) => m);
});

extension _Nullable<T> on T? {
  T? flatMap(T? Function(T) f) => this == null ? null : f(this as T);
}

final teamByIdProvider = Provider.family<Team?, String>((ref, id) {
  return ref
      .watch(teamsProvider)
      .whenData((ts) => ts.where((t) => t.id == id).firstOrNull)
      .valueOrNull
      .flatMap((t) => t);
});

// ─── Squads (bundled asset) ───────────────────────────────────────────────────

final squadRepositoryProvider = Provider<SquadRepository>(
  (_) => SquadRepository.instance,
);

final squadByTeamIdProvider =
    FutureProvider.family<List<Player>, String>((ref, teamId) async {
  return ref.watch(squadRepositoryProvider).forTeam(teamId);
});

/// 赛程搜索索引（球队展示名 + 全库球员名）。
final scheduleSearchIndexProvider =
    FutureProvider<ScheduleSearchIndex>((ref) async {
  final teams = ref.watch(teamsProvider).valueOrNull ?? const [];
  final squads = await ref.watch(squadRepositoryProvider).load();
  return ScheduleSearchIndex.build(teams: teams, squads: squads);
});

// ─── FIFA Ranking (bundled asset) ─────────────────────────────────────────────

final rankingRepositoryProvider = Provider<RankingRepository>(
  (_) => RankingRepository.instance,
);

final fifaRankingsProvider = FutureProvider<
    ({String updated, Map<String, FifaRanking> byCode})>(
  (ref) => ref.watch(rankingRepositoryProvider).load(),
);

/// 按 FIFA 三字母代码查询排名（同步、依赖 [fifaRankingsProvider] 已加载）。
final fifaRankByCodeProvider =
    Provider.family<FifaRanking?, String>((ref, code) {
  final async = ref.watch(fifaRankingsProvider);
  final byCode = async.valueOrNull?.byCode;
  if (byCode == null) return null;
  return byCode[code.toUpperCase()];
});

// ─── Match ID mapping (worldcup26.ir → Highlightly) ───────────────────────────

final matchIdMapRepositoryProvider = Provider<MatchIdMapRepository>(
  (_) => MatchIdMapRepository.instance,
);

final matchIdMapProvider = FutureProvider<Map<String, MatchIdMapEntry>>(
  (ref) => ref.watch(matchIdMapRepositoryProvider).load(),
);

/// 同步查 UTC 开赛时间（依赖 [matchIdMapProvider] 已加载）。
final kickoffUtcByMatchIdProvider =
    Provider.family<DateTime?, String>((ref, matchId) {
  final async = ref.watch(matchIdMapProvider);
  return async.valueOrNull?[matchId]?.kickoffUtc;
});

// ─── Lineups (via Cloudflare Worker proxy) ────────────────────────────────────

final lineupRepositoryProvider = Provider<LineupRepository>(
  (ref) => LineupRepository(
    workerBaseUrl: Endpoints.workerBaseUrl,
    idMap: ref.watch(matchIdMapRepositoryProvider),
  ),
);

final lineupByMatchIdProvider =
    FutureProvider.family<MatchLineup?, String>((ref, matchId) async {
  return ref.watch(lineupRepositoryProvider).forMatch(matchId);
});
