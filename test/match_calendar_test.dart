import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup_tracker/core/utils/match_calendar.dart';
import 'package:worldcup_tracker/data/models/match.dart';

Match _match({
  required String id,
  DateTime? localDate,
  String homeTeamId = '1',
  String awayTeamId = '2',
}) =>
    Match(
      id: id,
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
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
  test('tournamentDays spans opening through closing inclusive', () {
    final days = tournamentDays(
      opening: DateTime(2026, 6, 11),
      closing: DateTime(2026, 6, 13),
    );
    expect(days.length, 3);
    expect(days.first, DateTime(2026, 6, 11));
    expect(days.last, DateTime(2026, 6, 13));
  });

  test('groupConfirmedByBeijingDay uses UTC for calendar day', () {
    final m = _match(id: '1', localDate: DateTime(2026, 6, 12, 3, 0));
    final utc = DateTime.utc(2026, 6, 11, 19, 0);
    final grouped = groupConfirmedByBeijingDay(
      matches: [m],
      kickoffUtcById: {'1': utc},
    );
    expect(grouped.keys.single, DateTime(2026, 6, 12));
  });

  test('same day matches sort by Beijing kickoff', () {
    final early = _match(id: '1', localDate: DateTime(2026, 6, 11, 20, 0));
    final late = _match(id: '2', localDate: DateTime(2026, 6, 11, 13, 0));
    final grouped = groupConfirmedByBeijingDay(
      matches: [early, late],
      kickoffUtcById: {
        '1': DateTime.utc(2026, 6, 12, 0, 0),
        '2': DateTime.utc(2026, 6, 11, 19, 0),
      },
    );
    final day = DateTime(2026, 6, 12);
    expect(grouped[day]!.map((m) => m.id).toList(), ['2', '1']);
  });

  test('unconfirmed matches are excluded', () {
    final tbd = _match(
      id: 'x',
      localDate: DateTime(2026, 6, 11, 13, 0),
      homeTeamId: '0',
      awayTeamId: '2',
    );
    final grouped = groupConfirmedByBeijingDay(
      matches: [tbd],
      kickoffUtcById: const {},
    );
    expect(grouped, isEmpty);
  });

  test('scheduleCalendarDays includes today when before first match', () {
    final m = _match(id: '1', localDate: DateTime(2026, 6, 15, 13, 0));
    final days = scheduleCalendarDays(
      matches: [m],
      kickoffUtcById: const {},
      now: DateTime(2026, 6, 4),
    );
    expect(days.first, DateTime(2026, 6, 4));
    expect(days.last, DateTime(2026, 6, 15));
    expect(days, contains(DateTime(2026, 6, 4)));
    expect(days, contains(DateTime(2026, 6, 15)));
  });

  test('scheduleCalendarDays spans min match day through max', () {
    final m1 = _match(id: '1', localDate: DateTime(2026, 6, 11, 13, 0));
    final m2 = _match(id: '2', localDate: DateTime(2026, 6, 13, 13, 0));
    final days = scheduleCalendarDays(
      matches: [m1, m2],
      kickoffUtcById: const {},
      now: DateTime(2026, 6, 12),
    );
    expect(days.first, DateTime(2026, 6, 11));
    expect(days.last, DateTime(2026, 6, 13));
    expect(days.length, 3);
  });

  test('filterMatchesByCalendarDay keeps only matches on that day', () {
    final m1 = _match(id: '1', localDate: DateTime(2026, 6, 11, 13, 0));
    final m2 = _match(id: '2', localDate: DateTime(2026, 6, 12, 13, 0));
    final filtered = filterMatchesByCalendarDay(
      matches: [m1, m2],
      day: DateTime(2026, 6, 11),
      kickoffUtcById: const {},
    );
    expect(filtered.map((m) => m.id), ['1']);
  });

  test('defaultCalendarSelectedDay is always user today', () {
    expect(
      defaultCalendarSelectedDay(now: DateTime(2026, 6, 15, 18, 30)),
      DateTime(2026, 6, 15),
    );
    expect(
      defaultCalendarSelectedDay(now: DateTime(2025, 1, 3)),
      DateTime(2025, 1, 3),
    );
  });

  test('formatBeijingDayHeader includes weekday', () {
    expect(
      formatBeijingDayHeader(DateTime(2026, 6, 11)),
      '6月11日 周四',
    );
  });
}
