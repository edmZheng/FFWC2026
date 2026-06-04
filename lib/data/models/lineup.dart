import '../../core/utils/coerce.dart';

/// 单个球员阵容条目（含号码和位置）。
class LineupPlayer {
  const LineupPlayer({
    required this.id,
    required this.name,
    required this.number,
    required this.position,
  });

  final int id;
  final String name;
  final int number;
  final String position;

  factory LineupPlayer.fromJson(Map<String, dynamic> j) => LineupPlayer(
        id: Coerce.asInt(j['id']),
        name: Coerce.asString(j['name']),
        number: Coerce.asInt(j['number']),
        position: Coerce.asString(j['position']),
      );
}

/// 单队首发 + 替补。
class TeamLineup {
  const TeamLineup({
    required this.teamId,
    required this.teamName,
    required this.formation,
    required this.initialLineup,
    required this.substitutes,
  });

  final int teamId;
  final String teamName;
  /// 阵型字符串，如 "4-3-3"；上游可能返回 "Unknown"。
  final String formation;
  /// 上游按阵型行分组，按 [GK, DF, MF, FW] 顺序。每行球员列表。
  final List<List<LineupPlayer>> initialLineup;
  final List<LineupPlayer> substitutes;

  bool get hasData =>
      initialLineup.isNotEmpty && initialLineup.any((row) => row.isNotEmpty);

  factory TeamLineup.fromJson(Map<String, dynamic> j) {
    final lineupRaw = j['initialLineup'] as List<dynamic>? ?? [];
    final lineup = lineupRaw
        .map((row) => (row as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .map(LineupPlayer.fromJson)
            .toList())
        .toList();
    final subsRaw = j['substitutes'] as List<dynamic>? ?? [];
    final subs = subsRaw
        .cast<Map<String, dynamic>>()
        .map(LineupPlayer.fromJson)
        .toList();
    return TeamLineup(
      teamId: Coerce.asInt(j['id']),
      teamName: Coerce.asString(j['name']),
      formation: Coerce.asString(j['formation']),
      initialLineup: lineup,
      substitutes: subs,
    );
  }
}

/// 整场首发 + 替补（主+客）。
class MatchLineup {
  const MatchLineup({required this.home, required this.away});

  final TeamLineup home;
  final TeamLineup away;

  bool get hasAnyData => home.hasData || away.hasData;

  factory MatchLineup.fromJson(Map<String, dynamic> j) => MatchLineup(
        home: TeamLineup.fromJson(j['homeTeam'] as Map<String, dynamic>? ?? {}),
        away: TeamLineup.fromJson(j['awayTeam'] as Map<String, dynamic>? ?? {}),
      );
}
