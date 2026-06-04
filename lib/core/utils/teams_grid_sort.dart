import '../../data/models/team.dart';

/// 宫格列表：已关注球队置前，两组内均保持 [teams] 原有顺序。
List<Team> sortTeamsWithFollowedFirst(
  List<Team> teams,
  Set<String> followedIds,
) {
  if (followedIds.isEmpty) return teams;
  final followedFirst = <Team>[];
  final rest = <Team>[];
  for (final t in teams) {
    if (followedIds.contains(t.id)) {
      followedFirst.add(t);
    } else {
      rest.add(t);
    }
  }
  return [...followedFirst, ...rest];
}
