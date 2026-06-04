import '../../data/models/match.dart';
import 'match_time.dart';

/// 归一化为仅年月日（无时区语义，用于赛历宫格键）。
DateTime calendarDateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool isSameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// 含首尾的连续日历日列表。
List<DateTime> tournamentDays({
  required DateTime opening,
  required DateTime closing,
}) {
  final start = calendarDateOnly(opening);
  final end = calendarDateOnly(closing);
  final days = <DateTime>[];
  for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
    days.add(d);
  }
  return days;
}

/// 比赛归属的北京时间「赛历日」。
DateTime beijingCalendarDayForMatch(
  Match match, {
  DateTime? kickoffUtc,
}) {
  if (kickoffUtc != null) {
    return calendarDateOnly(MatchTime.toBeijing(kickoffUtc));
  }
  final local = match.localDate;
  if (local != null) return calendarDateOnly(local);
  return DateTime(0);
}

DateTime kickoffSortInstant(Match match, {DateTime? kickoffUtc}) {
  if (kickoffUtc != null) return MatchTime.toBeijing(kickoffUtc);
  return match.localDate ?? DateTime(9999);
}

int compareMatchesByBeijingKickoff(
  Match a,
  Match b, {
  DateTime? kickoffUtcA,
  DateTime? kickoffUtcB,
}) {
  final c = kickoffSortInstant(a, kickoffUtc: kickoffUtcA)
      .compareTo(kickoffSortInstant(b, kickoffUtc: kickoffUtcB));
  return c != 0 ? c : a.id.compareTo(b.id);
}

/// 已确定赛程按北京时间赛历日分组；同日按开赛先后排序。
Map<DateTime, List<Match>> groupConfirmedByBeijingDay({
  required Iterable<Match> matches,
  required Map<String, DateTime> kickoffUtcById,
}) {
  final map = <DateTime, List<Match>>{};
  for (final m in matches) {
    if (!m.isConfirmed) continue;
    final day = beijingCalendarDayForMatch(
      m,
      kickoffUtc: kickoffUtcById[m.id],
    );
    if (day.year <= 1) continue;
    map.putIfAbsent(day, () => []).add(m);
  }
  for (final list in map.values) {
    list.sort(
      (a, b) => compareMatchesByBeijingKickoff(
        a,
        b,
        kickoffUtcA: kickoffUtcById[a.id],
        kickoffUtcB: kickoffUtcById[b.id],
      ),
    );
  }
  return map;
}

int indexOfCalendarDay(List<DateTime> days, DateTime day) {
  final target = calendarDateOnly(day);
  final i = days.indexWhere((d) => isSameCalendarDay(d, target));
  return i < 0 ? 0 : i;
}

/// 赛历条日期范围：数据最早/最晚比赛日，并保证包含 [now] 当天。
List<DateTime> scheduleCalendarDays({
  required Iterable<Match> matches,
  required Map<String, DateTime> kickoffUtcById,
  DateTime? now,
}) {
  final today = calendarDateOnly(now ?? DateTime.now());
  final matchDays = <DateTime>[];
  for (final m in matches) {
    if (!m.isConfirmed) continue;
    final d = beijingCalendarDayForMatch(m, kickoffUtc: kickoffUtcById[m.id]);
    if (d.year > 1) matchDays.add(d);
  }
  if (matchDays.isEmpty) return [today];

  var start = matchDays.first;
  var end = matchDays.first;
  for (final d in matchDays) {
    if (d.isBefore(start)) start = d;
    if (d.isAfter(end)) end = d;
  }
  if (today.isBefore(start)) start = today;
  if (today.isAfter(end)) end = today;
  return tournamentDays(opening: start, closing: end);
}

String chineseWeekday(DateTime date) {
  const names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  return names[date.weekday - 1];
}

String formatCalendarDayHeader(DateTime day) =>
    '${day.month}月${day.day}日 · ${chineseWeekday(day)}';

String formatKickoffHm(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

bool matchOnCalendarDay(
  Match match,
  DateTime day, {
  DateTime? kickoffUtc,
}) =>
    isSameCalendarDay(
      beijingCalendarDayForMatch(match, kickoffUtc: kickoffUtc),
      day,
    );

/// 赛历日筛选 + 北京时间开赛排序。
List<Match> filterMatchesByCalendarDay({
  required List<Match> matches,
  required DateTime day,
  required Map<String, DateTime> kickoffUtcById,
}) {
  final list = matches
      .where(
        (m) => matchOnCalendarDay(
          m,
          day,
          kickoffUtc: kickoffUtcById[m.id],
        ),
      )
      .toList();
  list.sort(
    (a, b) => compareMatchesByBeijingKickoff(
      a,
      b,
      kickoffUtcA: kickoffUtcById[a.id],
      kickoffUtcB: kickoffUtcById[b.id],
    ),
  );
  return list;
}

/// 每日已确定场次数（用于赛历条展示）。
Map<DateTime, int> matchCountByCalendarDay({
  required Iterable<Match> matches,
  required Map<String, DateTime> kickoffUtcById,
}) {
  final counts = <DateTime, int>{};
  for (final m in matches) {
    if (!m.isConfirmed) continue;
    final day = beijingCalendarDayForMatch(m, kickoffUtc: kickoffUtcById[m.id]);
    if (day.year <= 1) continue;
    counts[day] = (counts[day] ?? 0) + 1;
  }
  return counts;
}

/// 打开赛历时默认选中用户当前日历日。
DateTime defaultCalendarSelectedDay({DateTime? now}) =>
    calendarDateOnly(now ?? DateTime.now());
