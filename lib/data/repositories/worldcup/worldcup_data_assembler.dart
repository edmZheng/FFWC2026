import '../../../data/models/group_standing.dart';
import '../../../data/models/match.dart';
import '../../../data/models/stadium.dart';
import '../../../data/models/team.dart';
import '../../../data/models/worldcup_data.dart';

/// Turns raw WorldCup API payloads into the app read model.
class WorldCupDataAssembler {
  WorldCupData assemble({
    required Map<String, dynamic> gamesJson,
    required Map<String, dynamic> teamsJson,
    required Map<String, dynamic> stadiumsJson,
    required Map<String, dynamic> groupsJson,
  }) {
    final teamMap = <String, Team>{};
    final rawTeamMap = <String, dynamic>{};
    for (final raw in (teamsJson['teams'] as List<dynamic>? ?? [])) {
      final m = raw as Map<String, dynamic>;
      final t = Team.fromJson(m);
      teamMap[t.id] = t;
      rawTeamMap[t.id] = m;
    }

    final stadiumMap = <String, Stadium>{};
    for (final raw in (stadiumsJson['stadiums'] as List<dynamic>? ?? [])) {
      final m = raw as Map<String, dynamic>;
      final s = Stadium.fromJson(m);
      stadiumMap[s.id] = s;
    }

    final standings = (groupsJson['groups'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map((g) => GroupStanding.fromJson(g, teamMap: rawTeamMap))
        .toList();

    final matches = (gamesJson['games'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map((g) => Match.fromJson(g, teamMap: teamMap, stadiumMap: stadiumMap))
        .toList();

    matches.sort((a, b) {
      if (a.localDate == null && b.localDate == null) return 0;
      if (a.localDate == null) return 1;
      if (b.localDate == null) return -1;
      return a.localDate!.compareTo(b.localDate!);
    });

    return WorldCupData(
      matches: matches,
      teams: teamMap.values.toList()
        ..sort((a, b) => a.nameEn.compareTo(b.nameEn)),
      stadiums: stadiumMap.values.toList()
        ..sort((a, b) => a.nameEn.compareTo(b.nameEn)),
      standings: standings,
    );
  }
}
