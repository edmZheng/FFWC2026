import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/player.dart';
import '../ranking_repository.dart';
import '../squad_repository.dart';

final squadRepositoryProvider = Provider<SquadRepository>(
  (_) => SquadRepository.instance,
);

final squadByTeamIdProvider =
    FutureProvider.family<List<Player>, String>((ref, teamId) async {
  return ref.watch(squadRepositoryProvider).forTeam(teamId);
});

final rankingRepositoryProvider = Provider<RankingRepository>(
  (_) => RankingRepository.instance,
);

final fifaRankingsProvider =
    FutureProvider<({String updated, Map<String, FifaRanking> byCode})>(
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
