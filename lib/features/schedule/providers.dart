import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/rankings/providers.dart';
import '../../data/repositories/worldcup/providers.dart';
import 'schedule_search_index.dart';

/// 赛程搜索索引（球队展示名 + 全库球员名）。
final scheduleSearchIndexProvider =
    FutureProvider<ScheduleSearchIndex>((ref) async {
  final teams = ref.watch(teamsProvider).valueOrNull ?? const [];
  final squads = await ref.watch(squadRepositoryProvider).load();
  return ScheduleSearchIndex.build(teams: teams, squads: squads);
});
