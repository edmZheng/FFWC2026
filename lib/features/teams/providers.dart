import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/teams_grid_sort.dart';
import '../../data/models/team.dart';
import '../../data/repositories/followed_teams/providers.dart';
import '../../data/repositories/worldcup/providers.dart';

/// 球队宫格：已关注球队排在最前，组内保持 API 原始顺序。
final teamsGridProvider = Provider<AsyncValue<List<Team>>>((ref) {
  final followed = ref.watch(followedTeamsProvider);
  return ref.watch(teamsProvider).whenData(
        (teams) => sortTeamsWithFollowedFirst(teams, followed),
      );
});
