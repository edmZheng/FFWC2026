import '../../core/utils/coerce.dart';

/// A single team's standing row within a group.
class TeamStanding {
  const TeamStanding({
    required this.teamId,
    required this.mp,
    required this.w,
    required this.l,
    required this.d,
    required this.pts,
    required this.gf,
    required this.ga,
    required this.gd,
    this.teamNameEn = '',
    this.teamFlagUrl = '',
    this.teamIso2 = '',
    this.teamFifaCode = '',
  });

  final String teamId;
  final int mp;
  final int w;
  final int l;
  final int d;
  final int pts;
  final int gf;
  final int ga;
  final int gd;
  /// Enriched after join with teams list.
  final String teamNameEn;
  final String teamFlagUrl;
  final String teamIso2;
  final String teamFifaCode;

  factory TeamStanding.fromJson(Map<String, dynamic> j) => TeamStanding(
        teamId: Coerce.asString(j['team_id']),
        mp: Coerce.asInt(j['mp']),
        w: Coerce.asInt(j['w']),
        l: Coerce.asInt(j['l']),
        d: Coerce.asInt(j['d']),
        pts: Coerce.asInt(j['pts']),
        gf: Coerce.asInt(j['gf']),
        ga: Coerce.asInt(j['ga']),
        gd: Coerce.asInt(j['gd']),
      );

  TeamStanding copyWithTeam({
    required String nameEn,
    required String flagUrl,
    String iso2 = '',
    String fifaCode = '',
  }) =>
      TeamStanding(
        teamId: teamId,
        mp: mp,
        w: w,
        l: l,
        d: d,
        pts: pts,
        gf: gf,
        ga: ga,
        gd: gd,
        teamNameEn: nameEn,
        teamFlagUrl: flagUrl,
        teamIso2: iso2,
        teamFifaCode: fifaCode,
      );
}

/// All standings for a single group, sorted by FIFA rules.
class GroupStanding {
  const GroupStanding({
    required this.groupName,
    required this.teams,
  });

  final String groupName;
  /// Sorted: pts desc → gd desc → gf desc → name asc.
  final List<TeamStanding> teams;

  factory GroupStanding.fromJson(Map<String, dynamic> j,
      {Map<String, dynamic> teamMap = const {}}) {
    final rawTeams = (j['teams'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(TeamStanding.fromJson)
        .toList();

    // Enrich with team name/flag if teamMap provided
    final enriched = rawTeams.map((s) {
      final t = teamMap[s.teamId];
      if (t == null) return s;
      return s.copyWithTeam(
        nameEn: t['name_en']?.toString() ?? '',
        flagUrl: t['flag']?.toString() ?? '',
        iso2: t['iso2']?.toString() ?? '',
        fifaCode: t['fifa_code']?.toString() ?? '',
      );
    }).toList();

    _sort(enriched);

    return GroupStanding(
      groupName: Coerce.asString(j['name']),
      teams: enriched,
    );
  }

  /// FIFA simplified sort: pts↓ gd↓ gf↓ name↑
  static void _sort(List<TeamStanding> list) {
    list.sort((a, b) {
      final pts = b.pts.compareTo(a.pts);
      if (pts != 0) return pts;
      final gd = b.gd.compareTo(a.gd);
      if (gd != 0) return gd;
      final gf = b.gf.compareTo(a.gf);
      if (gf != 0) return gf;
      return a.teamNameEn.compareTo(b.teamNameEn);
    });
  }
}
