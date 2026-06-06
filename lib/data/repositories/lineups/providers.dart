import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/endpoints.dart';
import '../../../data/models/lineup.dart';
import '../match_id_map_repository.dart';
import '../lineup_repository.dart';

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
