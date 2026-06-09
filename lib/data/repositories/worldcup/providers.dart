import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/infra/providers.dart';
import '../../../data/models/group_standing.dart';
import '../../../data/models/match.dart';
import '../../../data/models/stadium.dart';
import '../../../data/models/team.dart';
import '../../../data/models/worldcup_data.dart';
import '../followed_teams/providers.dart';
import '../worldcup_repository.dart';

final worldCupRepositoryProvider = Provider<WorldCupRepository>(
  (ref) => WorldCupRepository(
    api: ref.watch(apiClientProvider),
    cache: ref.watch(cacheStoreProvider),
  ),
);

final worldCupDataProvider =
    AsyncNotifierProvider<WorldCupDataNotifier, WorldCupData>(
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

final matchesProvider = Provider<AsyncValue<List<Match>>>(
    (ref) => ref.watch(worldCupDataProvider).whenData((d) => d.matches));

final teamsProvider = Provider<AsyncValue<List<Team>>>(
    (ref) => ref.watch(worldCupDataProvider).whenData((d) => d.teams));

final stadiumsProvider = Provider<AsyncValue<List<Stadium>>>(
    (ref) => ref.watch(worldCupDataProvider).whenData((d) => d.stadiums));

final standingsProvider = Provider<AsyncValue<List<GroupStanding>>>(
    (ref) => ref.watch(worldCupDataProvider).whenData((d) => d.standings));

final liveMatchesProvider = Provider<AsyncValue<List<Match>>>(
    (ref) => ref.watch(matchesProvider).whenData(
          (ms) => ms.where((m) => m.status == MatchStatus.live).toList(),
        ));

int _compareMatchesByKickoff(Match a, Match b) {
  final da = a.localDate;
  final db = b.localDate;
  if (da == null && db == null) return a.id.compareTo(b.id);
  if (da == null) return 1;
  if (db == null) return -1;
  final c = da.compareTo(db);
  return c != 0 ? c : a.id.compareTo(b.id);
}

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
