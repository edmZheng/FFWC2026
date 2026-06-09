import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup_tracker/data/models/match.dart';
import 'package:worldcup_tracker/features/schedule/schedule_list_entries.dart';

Match _match({
  required String id,
  DateTime? localDate,
}) =>
    Match(
      id: id,
      homeTeamId: '1',
      awayTeamId: '2',
      homeTeamNameEn: 'A',
      awayTeamNameEn: 'B',
      homeTeamLabel: '',
      awayTeamLabel: '',
      homeScore: 0,
      awayScore: 0,
      homeScorers: const [],
      awayScorers: const [],
      group: 'A',
      matchday: 1,
      localDate: localDate,
      stadiumId: '1',
      status: MatchStatus.notStarted,
      stage: MatchStage.group,
      timeElapsed: 'notstarted',
    );

void main() {
  test('buildScheduleListEntries inserts one header per day', () {
    final day1a = DateTime(2026, 6, 11, 13);
    final day1b = DateTime(2026, 6, 11, 19);
    final day2 = DateTime(2026, 6, 12, 3);
    final matches = [
      _match(id: '1', localDate: day1a),
      _match(id: '2', localDate: day1b),
      _match(id: '3', localDate: day2),
    ];

    final entries = buildScheduleListEntries(
      matches: matches,
      kickoffUtcById: const {},
    );

    expect(entries.length, 5);
    expect(entries[0].kind, ScheduleListEntryKind.dayHeader);
    expect(entries[0].dayLabel, '6月11日 周四');
    expect(entries[1].match?.id, '1');
    expect(entries[2].match?.id, '2');
    expect(entries[3].dayLabel, '6月12日 周五');
    expect(entries[4].match?.id, '3');
  });
}
