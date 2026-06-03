import '../../core/utils/coerce.dart';
import '../../core/utils/match_time.dart';
export '../../core/utils/match_time.dart' show MatchStatus;
import 'team.dart';
import 'stadium.dart';

/// Match stage derived from API `type` field.
enum MatchStage {
  group,
  r32,
  r16,
  quarterFinal,
  semiFinal,
  thirdPlace,
  final_,
  unknown;

  static MatchStage fromApi(String v) => switch (v.toLowerCase().trim()) {
        'group' => MatchStage.group,
        'r32' => MatchStage.r32,
        'r16' => MatchStage.r16,
        'qf' => MatchStage.quarterFinal,
        'sf' => MatchStage.semiFinal,
        'third' => MatchStage.thirdPlace,
        'final' => MatchStage.final_,
        _ => MatchStage.unknown,
      };

  String get label => switch (this) {
        MatchStage.group => 'Group Stage',
        MatchStage.r32 => 'Round of 32',
        MatchStage.r16 => 'Round of 16',
        MatchStage.quarterFinal => 'Quarter-Final',
        MatchStage.semiFinal => 'Semi-Final',
        MatchStage.thirdPlace => 'Third Place',
        MatchStage.final_ => 'Final',
        MatchStage.unknown => 'Unknown',
      };
}

/// A single match with all associated data.
class Match {
  const Match({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeamNameEn,
    required this.awayTeamNameEn,
    required this.homeTeamLabel,
    required this.awayTeamLabel,
    required this.homeScore,
    required this.awayScore,
    required this.homeScorers,
    required this.awayScorers,
    required this.group,
    required this.matchday,
    required this.localDate,
    required this.stadiumId,
    required this.status,
    required this.stage,
    required this.timeElapsed,
    this.homeTeam,
    this.awayTeam,
    this.stadium,
  });

  final String id;
  final String homeTeamId;
  final String awayTeamId;
  final String homeTeamNameEn;
  final String awayTeamNameEn;
  /// Fallback label for knockout TBD slots (e.g. "Winner Group A").
  final String homeTeamLabel;
  final String awayTeamLabel;
  final int homeScore;
  final int awayScore;
  final List<String> homeScorers;
  final List<String> awayScorers;
  final String group;
  final int matchday;
  final DateTime? localDate;
  final String stadiumId;
  final MatchStatus status;
  final MatchStage stage;
  /// Raw value e.g. "45", "notstarted", "HT".
  final String timeElapsed;

  /// Enriched after client-side join.
  final Team? homeTeam;
  final Team? awayTeam;
  final Stadium? stadium;

  /// 双方球队均已确定（非占位 id）。
  bool get isConfirmed =>
      homeTeamId != '0' &&
      awayTeamId != '0' &&
      homeTeamId.isNotEmpty &&
      awayTeamId.isNotEmpty;

  /// Display name: real team name when known, fallback to label for TBD.
  String get homeDisplayName =>
      homeTeamId != '0' && homeTeamNameEn.isNotEmpty
          ? homeTeamNameEn
          : homeTeamLabel.isNotEmpty
              ? homeTeamLabel
              : 'TBD';

  String get awayDisplayName =>
      awayTeamId != '0' && awayTeamNameEn.isNotEmpty
          ? awayTeamNameEn
          : awayTeamLabel.isNotEmpty
              ? awayTeamLabel
              : 'TBD';

  factory Match.fromJson(
    Map<String, dynamic> j, {
    Map<String, Team> teamMap = const {},
    Map<String, Stadium> stadiumMap = const {},
  }) {
    final finished = Coerce.asBool(j['finished']);
    final timeElapsed = Coerce.asString(j['time_elapsed']);
    final homeTeamId = Coerce.asString(j['home_team_id']);
    final awayTeamId = Coerce.asString(j['away_team_id']);

    return Match(
      id: Coerce.asString(j['id']),
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      homeTeamNameEn: Coerce.asString(j['home_team_name_en']),
      awayTeamNameEn: Coerce.asString(j['away_team_name_en']),
      homeTeamLabel: Coerce.asString(j['home_team_label']),
      awayTeamLabel: Coerce.asString(j['away_team_label']),
      homeScore: Coerce.asInt(j['home_score']),
      awayScore: Coerce.asInt(j['away_score']),
      homeScorers: Coerce.asScorers(j['home_scorers']),
      awayScorers: Coerce.asScorers(j['away_scorers']),
      group: Coerce.asString(j['group']),
      matchday: Coerce.asInt(j['matchday']),
      localDate: MatchTime.parseLocalDate(j['local_date']?.toString()),
      stadiumId: Coerce.asString(j['stadium_id']),
      status: MatchTime.deriveStatus(finished: finished, timeElapsed: timeElapsed),
      stage: MatchStage.fromApi(Coerce.asString(j['type'])),
      timeElapsed: timeElapsed,
      homeTeam: teamMap[homeTeamId],
      awayTeam: teamMap[awayTeamId],
      stadium: stadiumMap[Coerce.asString(j['stadium_id'])],
    );
  }

  Match copyWith({Team? homeTeam, Team? awayTeam, Stadium? stadium}) => Match(
        id: id,
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
        homeTeamNameEn: homeTeamNameEn,
        awayTeamNameEn: awayTeamNameEn,
        homeTeamLabel: homeTeamLabel,
        awayTeamLabel: awayTeamLabel,
        homeScore: homeScore,
        awayScore: awayScore,
        homeScorers: homeScorers,
        awayScorers: awayScorers,
        group: group,
        matchday: matchday,
        localDate: localDate,
        stadiumId: stadiumId,
        status: status,
        stage: stage,
        timeElapsed: timeElapsed,
        homeTeam: homeTeam ?? this.homeTeam,
        awayTeam: awayTeam ?? this.awayTeam,
        stadium: stadium ?? this.stadium,
      );
}
