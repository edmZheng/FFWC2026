import '../models/group_standing.dart';
import '../models/match.dart';
import '../models/stadium.dart';
import '../models/team.dart';

/// Aggregated data returned by a full refresh.
class WorldCupData {
  const WorldCupData({
    required this.matches,
    required this.teams,
    required this.stadiums,
    required this.standings,
  });

  final List<Match> matches;
  final List<Team> teams;
  final List<Stadium> stadiums;
  final List<GroupStanding> standings;
}
