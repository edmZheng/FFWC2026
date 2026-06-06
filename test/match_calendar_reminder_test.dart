import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup_tracker/core/calendar/match_calendar_reminder.dart';
import 'package:worldcup_tracker/data/models/match.dart';
import 'package:worldcup_tracker/data/models/stadium.dart';

void main() {
  group('resolveKickoffLocal', () {
    test('uses UTC mapping converted to local', () {
      final utc = DateTime.utc(2026, 6, 11, 19, 0);
      final local = resolveKickoffLocal(kickoffUtc: utc);
      expect(local, utc.toLocal());
    });

    test('falls back to local_date as Beijing wall time', () {
      final naive = DateTime(2026, 6, 12, 3, 0);
      final local = resolveKickoffLocal(localDate: naive);
      final expectedUtc = DateTime.utc(2026, 6, 11, 19, 0);
      expect(local, expectedUtc.toLocal());
    });
  });

  group('buildMatchCalendarTitle', () {
    test('includes teams', () {
      expect(
        buildMatchCalendarTitle(homeName: '巴西', awayName: '阿根廷'),
        '【世界杯】巴西 vs 阿根廷',
      );
    });
  });

  group('buildMatchCalendarDescription', () {
    test('includes stage and reminder hint', () {
      const match = Match(
        id: '1',
        homeTeamId: '1',
        awayTeamId: '2',
        homeTeamNameEn: 'Brazil',
        awayTeamNameEn: 'Argentina',
        homeTeamLabel: '',
        awayTeamLabel: '',
        homeScore: 0,
        awayScore: 0,
        homeScorers: [],
        awayScorers: [],
        group: 'A',
        matchday: 1,
        localDate: null,
        stadiumId: '4',
        timeElapsed: 'notstarted',
        stage: MatchStage.group,
        status: MatchStatus.notStarted,
        stadium: Stadium(
          id: '4',
          nameEn: 'AT&T Stadium',
          nameFa: '',
          fifaName: 'AT&T Stadium',
          cityEn: 'Dallas (Arlington, Texas)',
          cityFa: '',
          countryEn: 'United States',
          countryFa: '',
          capacity: 94000,
          region: 'Central',
        ),
      );
      final text = buildMatchCalendarDescription(
        match: match,
        kickoffDisplay: '6月12日 03:00',
      );
      expect(text, contains('小组赛'));
      expect(text, contains('赛前 60 分钟提醒'));
      expect(text, contains('达拉斯AT&T体育场'));
    });
  });
}
