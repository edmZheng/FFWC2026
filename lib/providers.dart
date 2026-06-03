import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api/api_client.dart';
import 'core/cache/cache_store.dart';
import 'data/models/group_standing.dart';
import 'data/models/match.dart';
import 'data/models/stadium.dart';
import 'data/models/team.dart';
import 'data/repositories/worldcup_repository.dart';

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

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(worldCupRepositoryProvider).load(forceRefresh: true),
    );
  }
}

// ─── Derived selectors ────────────────────────────────────────────────────────

final matchesProvider = Provider<AsyncValue<List<Match>>>(
  (ref) => ref.watch(worldCupDataProvider).whenData((d) => d.matches),
);

final teamsProvider = Provider<AsyncValue<List<Team>>>(
  (ref) => ref.watch(worldCupDataProvider).whenData((d) => d.teams),
);

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

// ─── Live Polling ─────────────────────────────────────────────────────────────

/// Activates a 30-second polling loop when live matches exist.
/// Cancel by calling [cancel]. Intended to be used from a StatefulWidget
/// or a widget-scoped provider that disposes on unmount.
final livePollingProvider =
    AsyncNotifierProvider.autoDispose<LivePollingNotifier, List<Match>>(
  LivePollingNotifier.new,
);

class LivePollingNotifier extends AutoDisposeAsyncNotifier<List<Match>> {
  Timer? _timer;

  @override
  Future<List<Match>> build() async {
    ref.onDispose(() => _timer?.cancel());
    final data = await ref.watch(worldCupRepositoryProvider).load();
    final live = data.matches.where((m) => m.status == MatchStatus.live).toList();

    if (live.isNotEmpty) {
      _timer = Timer.periodic(const Duration(seconds: 30), (_) => _poll());
    }

    return live;
  }

  Future<void> _poll() async {
    final data = await ref.read(worldCupRepositoryProvider).load(forceRefresh: true);
    // Also refresh the global data cache
    ref.invalidate(worldCupDataProvider);
    state = AsyncValue.data(
      data.matches.where((m) => m.status == MatchStatus.live).toList(),
    );
  }
}

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
