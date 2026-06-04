import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup_tracker/core/utils/match_time.dart';
import 'package:worldcup_tracker/data/models/match.dart';
import 'package:worldcup_tracker/data/models/player.dart';
import 'package:worldcup_tracker/data/models/team.dart';
import 'package:worldcup_tracker/features/schedule/schedule_search_index.dart';

void main() {
  final brazil = Team(
    id: '1',
    nameEn: 'Brazil',
    nameFa: '',
    flagUrl: '',
    fifaCode: 'BRA',
    iso2: 'br',
    groups: const ['A'],
  );
  final japan = Team(
    id: '2',
    nameEn: 'Japan',
    nameFa: '',
    flagUrl: '',
    fifaCode: 'JPN',
    iso2: 'jp',
    groups: const ['C'],
  );

  Match mk(String id, String homeId, String awayId) => Match(
        id: id,
        homeTeamId: homeId,
        awayTeamId: awayId,
        homeTeamNameEn: '',
        awayTeamNameEn: '',
        homeTeamLabel: '',
        awayTeamLabel: '',
        homeScore: 0,
        awayScore: 0,
        homeScorers: const [],
        awayScorers: const [],
        group: 'A',
        matchday: 1,
        localDate: DateTime(2026, 6, 10 + int.parse(id)),
        stadiumId: '1',
        status: MatchStatus.notStarted,
        stage: MatchStage.group,
        timeElapsed: 'notstarted',
        homeTeam: homeId == '1' ? brazil : japan,
        awayTeam: awayId == '1' ? brazil : japan,
      );

  final index = ScheduleSearchIndex.build(
    teams: [brazil, japan],
    squads: {
      '1': [
        const Player(
          number: 10,
          nameEn: 'Neymar',
          nameZh: '内马尔',
          position: 'FW',
          positionZh: '前锋',
          captain: false,
          photoUrl: '',
        ),
      ],
    },
  );

  test('matches team Chinese name', () {
    final hits = index.search('巴西', [mk('1', '1', '2'), mk('2', '2', '1')]);
    expect(hits.length, 2);
    expect(hits.every((m) => m.homeTeamId == '1' || m.awayTeamId == '1'), true);
  });

  test('matches FIFA code', () {
    final hits = index.search('jpn', [mk('1', '1', '2')]);
    expect(hits.length, 1);
    expect(hits.first.id, '1');
  });

  test('matches player name and returns team fixtures', () {
    final hits = index.search('内马尔', [mk('1', '1', '2')]);
    expect(hits.length, 1);
    expect(hits.first.homeTeamId, '1');
  });

  test('empty query returns no results', () {
    expect(index.search('', [mk('1', '1', '2')]), isEmpty);
  });
}
